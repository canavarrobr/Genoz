// Cofre de projeto `.genoz` (Módulo 11, ADR-017).
//
// O pacote leva `projeto.json` (linhas do banco: projeto, arquivos, análises, filtros,
// notas, diário) + os arquivos importados (`arquivos/<id>`, `.fai` ao lado) + os
// resultados (`analises/<id>/<nome>`), tudo cifrado com a senha pelo núcleo.
//
// - Exportar: gera um `.genoz` para levar a outro aparelho (sem nuvem).
// - Importar: vira um projeto NOVO (IDs novos; o ID de análise, que vem do conteúdo, fica).
// - Proteger: o projeto vira `cofres/<id>.genoz` e os dados em claro são apagados;
//   abrir com a senha restaura o projeto com os mesmos IDs. Senha perdida = dados perdidos.

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/genoz_core.dart';
import '../../persistence/app_storage.dart';
import '../../persistence/database.dart';
import '../../persistence/project_repository.dart';

const vaultDir = 'cofres';
const tempDir = 'temporario';
const vaultExtension = 'genoz';
const archiveSchema = 1;
const minPasswordLength = 8;

/// Arquivos de uma pasta de resultado que vão no pacote.
const analysisFiles = ['rows.bgz', 'rows.idx', 'summary.json', 'stats_a.json', 'stats_b.json', 'manifest.json'];

String vaultRelative(String projectId) => '$vaultDir/$projectId.$vaultExtension';

final _posix = p.Context(style: p.Style.posix);

class ProjectVault {
  ProjectVault(this._db, this._storage, this._core);

  final GenozDatabase _db;
  final AppStorage _storage;
  final GenozCore _core;

  /// projeto.json + arquivos do pacote (`caminho no pacote → caminho relativo`).
  Future<(Uint8List, Map<String, String>)> _collect(String projectId, {String appVersion = ''}) async {
    final project = await (_db.select(_db.projects)..where((t) => t.id.equals(projectId))).getSingle();
    final files = await (_db.select(_db.projectFiles)..where((t) => t.projectId.equals(projectId))).get();
    final analyses = await (_db.select(_db.analyses)..where((t) => t.projectId.equals(projectId))).get();
    final filters = await (_db.select(_db.savedFilters)..where((t) => t.projectId.equals(projectId))).get();
    final notes = await (_db.select(_db.variantNotes)..where((t) => t.projectId.equals(projectId))).get();
    final journal = await (_db.select(_db.journalEntries)..where((t) => t.projectId.equals(projectId))).get();

    final entries = <String, String>{};
    for (final f in files) {
      if (await _storage.blobs.exists(f.storedPath)) entries['arquivos/${f.id}'] = f.storedPath;
      if (await _storage.blobs.exists('${f.storedPath}.fai')) entries['arquivos/${f.id}.fai'] = '${f.storedPath}.fai';
    }
    for (final a in analyses) {
      for (final name in analysisFiles) {
        final rel = '${a.resultDir}/$name';
        if (await _storage.blobs.exists(rel)) entries['analises/${a.id}/$name'] = rel;
      }
    }
    final json = {
      'schema': archiveSchema,
      'kind': 'genoz-project',
      'app_version': appVersion,
      'project': project.toJson(),
      'files': [for (final f in files) f.toJson()],
      'analyses': [for (final a in analyses) a.toJson()],
      'saved_filters': [for (final f in filters) f.toJson()],
      'notes': [for (final n in notes) n.toJson()],
      'journal': [for (final j in journal) j.toJson()],
    };
    return (Uint8List.fromList(utf8.encode(jsonEncode(json))), entries);
  }

  /// Cria um `.genoz` do projeto em `temporario/` e devolve o caminho relativo
  /// (quem chama salva onde o usuário escolher e apaga depois).
  Future<String> export(String projectId, String password, {String appVersion = ''}) async {
    final out = '$tempDir/exportacao_${newId()}.$vaultExtension';
    if (await _isLocked(projectId)) {
      // Já está cifrado: o cofre É o arquivo de exportação (mesma senha).
      await _storage.blobs.writeBytes(out, await _storage.blobs.readBytes(vaultRelative(projectId)));
      return out;
    }
    final (json, files) = await _collect(projectId, appVersion: appVersion);
    await _core.sealVault(inline: {'projeto.json': json}, files: files, outRelative: out, password: password);
    return out;
  }

  Future<bool> _isLocked(String projectId) async =>
      (await (_db.select(_db.projects)..where((t) => t.id.equals(projectId))).getSingleOrNull())?.locked ?? false;

  /// Importa um `.genoz` como projeto novo. Lança [VaultError].
  Future<String> import(SourceFile source, String password, {required String journalMessage}) async {
    final staging = '$tempDir/importacao_${newId()}';
    try {
      await _core.openVault(source: source, password: password, stagingRelative: staging);
      return await _restore(staging, journalMessage: journalMessage);
    } finally {
      await _storage.blobs.deleteDir(staging);
    }
  }

  /// Protege o projeto com senha: grava o cofre e só então apaga os dados em claro.
  Future<void> lock(String projectId, String password, {String appVersion = ''}) async {
    final (json, files) = await _collect(projectId, appVersion: appVersion);
    final out = vaultRelative(projectId);
    await _core.sealVault(inline: {'projeto.json': json}, files: files, outRelative: out, password: password);
    final analyses = await (_db.select(_db.analyses)..where((t) => t.projectId.equals(projectId))).get();
    for (final a in analyses) {
      _core.forgetResult(a.resultDir);
    }
    await _db.transaction(() async {
      await _deleteRows(projectId);
      await (_db.update(_db.projects)..where((t) => t.id.equals(projectId))).write(
        const ProjectsCompanion(locked: Value(true)),
      );
    });
    // Linhas apagadas continuam nas páginas livres do SQLite até o VACUUM (nomes de
    // amostras, resumos, notas): sem ele, parte do projeto ficaria legível no banco.
    await _db.customStatement('VACUUM');
    await _storage.deleteProjectFiles(projectId);
  }

  /// Abre um projeto protegido com a senha. Lança [VaultError] (nada muda se a senha estiver errada).
  Future<void> unlock(String projectId, String password, {required String journalMessage}) async {
    final rel = vaultRelative(projectId);
    final staging = '$tempDir/abertura_${newId()}';
    final native = _storage.blobs.nativePath(rel);
    final size = await _storage.blobs.size(rel);
    final source = SourceFile(
      name: p.basename(rel),
      path: native,
      open: native == null ? () => Stream.fromFuture(_storage.blobs.readBytes(rel)) : null,
      size: size,
    );
    try {
      await _core.openVault(source: source, password: password, stagingRelative: staging);
      await _restore(staging, keepProjectId: projectId, journalMessage: journalMessage);
    } finally {
      await _storage.blobs.deleteDir(staging);
    }
    await _storage.blobs.deleteFile(rel);
  }

  Future<void> _deleteRows(String projectId) async {
    await (_db.delete(_db.journalEntries)..where((t) => t.projectId.equals(projectId))).go();
    await (_db.delete(_db.variantNotes)..where((t) => t.projectId.equals(projectId))).go();
    await (_db.delete(_db.savedFilters)..where((t) => t.projectId.equals(projectId))).go();
    await (_db.delete(_db.analyses)..where((t) => t.projectId.equals(projectId))).go();
    await (_db.delete(_db.projectFiles)..where((t) => t.projectId.equals(projectId))).go();
  }

  /// Recria projeto, arquivos e linhas a partir de uma pasta extraída.
  /// `keepProjectId`: abrir um cofre (mesmos IDs); sem ele, projeto novo com IDs novos.
  Future<String> _restore(String staging, {String? keepProjectId, required String journalMessage}) async {
    final Map<String, dynamic> j;
    try {
      j = jsonDecode(await _storage.blobs.readString('$staging/projeto.json')) as Map<String, dynamic>;
    } catch (_) {
      throw const VaultError('formato');
    }
    if (j['kind'] != 'genoz-project') throw const VaultError('formato');
    if ((j['schema'] as int? ?? 0) > archiveSchema) throw const VaultError('versao');

    List<Map<String, dynamic>> list(String k) => [for (final e in (j[k] as List? ?? const [])) e as Map<String, dynamic>];
    final old = Project.fromJson(j['project'] as Map<String, dynamic>);
    if (keepProjectId != null && old.id != keepProjectId) throw const VaultError('formato');
    final keep = keepProjectId != null;
    final pid = keepProjectId ?? newId();
    final fileIds = <String, String>{};
    final now = DateTime.now();

    final files = <ProjectFile>[];
    for (final f in list('files').map(ProjectFile.fromJson)) {
      final id = keep ? f.id : newId();
      fileIds[f.id] = id;
      // Mantém a extensão gravada (".vcf.gz", ".fa", ".txt"...).
      final base = _posix.basename(f.storedPath);
      final ext = base.startsWith(f.id) ? base.substring(f.id.length) : _posix.extension(base);
      files.add(f.copyWith(id: id, projectId: pid, storedPath: _posix.join('projetos', pid, 'arquivos', '$id$ext')));
    }
    final analyses = <Analysis>[];
    final analysisIds = <String, String>{};
    for (final a in list('analyses').map(Analysis.fromJson)) {
      final id = keep ? a.id : newId();
      analysisIds[a.id] = id;
      analyses.add(a.copyWith(
        id: id,
        projectId: pid,
        fileAId: fileIds[a.fileAId] ?? a.fileAId,
        fileBId: fileIds[a.fileBId] ?? a.fileBId,
        resultDir: _storage.analysisRelative(pid, id),
      ));
    }

    // Arquivos primeiro; se algo falhar, a pasta do projeto novo é apagada.
    try {
      for (final f in files) {
        final oldId = fileIds.entries.firstWhere((e) => e.value == f.id).key;
        final src = '$staging/arquivos/$oldId';
        if (await _storage.blobs.exists(src)) await _storage.blobs.move(src, f.storedPath);
        if (await _storage.blobs.exists('$src.fai')) await _storage.blobs.move('$src.fai', '${f.storedPath}.fai');
      }
      for (final a in analyses) {
        final oldId = analysisIds.entries.firstWhere((e) => e.value == a.id).key;
        for (final name in analysisFiles) {
          final src = '$staging/analises/$oldId/$name';
          if (await _storage.blobs.exists(src)) await _storage.blobs.move(src, '${a.resultDir}/$name');
        }
      }
      await _db.transaction(() async {
        if (keep) {
          await (_db.update(_db.projects)..where((t) => t.id.equals(pid))).write(
            ProjectsCompanion(locked: const Value(false), updatedAt: Value(now)),
          );
        } else {
          await _db.into(_db.projects).insert(old.copyWith(id: pid, updatedAt: now, locked: false));
        }
        for (final f in files) {
          await _db.into(_db.projectFiles).insert(f);
        }
        for (final a in analyses) {
          await _db.into(_db.analyses).insert(a);
        }
        for (final f in list('saved_filters').map(SavedFilter.fromJson)) {
          await _db.into(_db.savedFilters).insert(f.copyWith(id: keep ? f.id : newId(), projectId: pid));
        }
        for (final n in list('notes').map(VariantNote.fromJson)) {
          await _db.into(_db.variantNotes).insert(n.copyWith(projectId: pid), mode: InsertMode.insertOrReplace);
        }
        for (final e in list('journal').map(JournalEntry.fromJson)) {
          await _db.into(_db.journalEntries).insert(JournalEntriesCompanion.insert(
                projectId: pid,
                kind: e.kind,
                message: e.message,
                createdAt: e.createdAt,
              ));
        }
        await _db.into(_db.journalEntries).insert(JournalEntriesCompanion.insert(
              projectId: pid,
              kind: 'import',
              message: journalMessage,
              createdAt: now,
            ));
      });
    } catch (_) {
      // Projeto novo: some inteiro. Cofre: a cópia em claro pela metade some; o cofre fica.
      await _storage.deleteProjectFiles(pid);
      rethrow;
    }
    return pid;
  }
}

final projectVaultProvider = Provider<ProjectVault>(
  (ref) => ProjectVault(ref.watch(databaseProvider), ref.watch(appStorageProvider), ref.watch(genozCoreProvider)),
);
