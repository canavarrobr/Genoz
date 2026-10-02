// Repositório de projetos e arquivos. É a única porta de entrada para o banco:
// telas e controladores nunca veem SQL nem tabelas do Drift.

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/inspect_report.dart';
import 'app_storage.dart';
import 'database.dart';

class ProjectSummary {
  const ProjectSummary({required this.project, required this.fileCount});
  final Project project;
  final int fileCount;
}

class ProjectRepository {
  ProjectRepository(this._db, this._storage);

  final GenozDatabase _db;
  final AppStorage _storage;

  Stream<List<ProjectSummary>> watchProjects() {
    final count = _db.projectFiles.id.count();
    final query = _db.select(_db.projects).join([
      leftOuterJoin(_db.projectFiles, _db.projectFiles.projectId.equalsExp(_db.projects.id)),
    ])
      ..addColumns([count])
      ..groupBy([_db.projects.id])
      ..orderBy([OrderingTerm.desc(_db.projects.updatedAt)]);
    return query.watch().map((rows) => [
          for (final r in rows)
            ProjectSummary(project: r.readTable(_db.projects), fileCount: r.read(count) ?? 0),
        ]);
  }

  Stream<Project?> watchProject(String id) =>
      (_db.select(_db.projects)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<Project> createProject(String name, {String? description}) async {
    final now = DateTime.now();
    final project = Project(
      id: newId(),
      name: name.trim(),
      description: (description?.trim().isEmpty ?? true) ? null : description!.trim(),
      createdAt: now,
      updatedAt: now,
      locked: false,
    );
    await _db.into(_db.projects).insert(project);
    return project;
  }

  Future<void> renameProject(String id, String name) =>
      (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(name: Value(name.trim()), updatedAt: Value(DateTime.now())),
      );

  /// Apaga o projeto do banco (arquivos em cascata) e da pasta do app.
  Future<void> deleteProject(String id) async {
    await (_db.delete(_db.projects)..where((t) => t.id.equals(id))).go();
    await _storage.deleteProjectFiles(id);
    // Projeto protegido com senha (Módulo 11): o cofre cifrado.
    await _storage.deleteFile('cofres/$id.genoz');
  }

  Stream<List<ProjectFile>> watchFiles(String projectId) => (_db.select(_db.projectFiles)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([(t) => OrderingTerm.asc(t.importedAt)]))
      .watch();

  Future<ProjectFile?> getFile(String id) =>
      (_db.select(_db.projectFiles)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> addImportedFile({
    required String projectId,
    required String fileId,
    required String displayName,
    required String storedPath,
    required InspectReport report,
    required String reportJson,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.projectFiles).insert(ProjectFile(
              id: fileId,
              projectId: projectId,
              displayName: displayName,
              storedPath: storedPath,
              sha256: report.sha256,
              bytes: report.bytes,
              compression: report.compression,
              fileFormat: report.fileFormat,
              build: report.build,
              buildConfidence: report.buildConfidence,
              verdict: verdictCode(report.verdict),
              recordsOk: report.recordsOk,
              errors: report.errors,
              warnings: report.warnings,
              samplesJson: jsonEncode([for (final s in report.samples) s.name]),
              reportJson: reportJson,
              importedAt: DateTime.now(),
            ));
        await _touch(projectId);
      });

  Future<void> deleteFile(ProjectFile file) async {
    await (_db.delete(_db.projectFiles)..where((t) => t.id.equals(file.id))).go();
    await _storage.deleteFile(file.storedPath);
    // FASTA: o índice .fai gravado ao lado na importação.
    await _storage.deleteFile('${file.storedPath}.fai');
    await _touch(file.projectId);
  }

  /// O mesmo conteúdo (mesmo SHA-256) já foi importado neste projeto?
  Future<ProjectFile?> findBySha(String projectId, String sha256) => (_db.select(_db.projectFiles)
        ..where((t) => t.projectId.equals(projectId) & t.sha256.equals(sha256)))
      .getSingleOrNull();

  Future<void> _touch(String projectId) =>
      (_db.update(_db.projects)..where((t) => t.id.equals(projectId)))
          .write(ProjectsCompanion(updatedAt: Value(DateTime.now())));
}

extension ProjectFileX on ProjectFile {
  Verdict get verdictValue => verdictFromCode(verdict);
  List<String> get sampleNames => (jsonDecode(samplesJson) as List).cast<String>();
  InspectReport get report => InspectReport.parse(reportJson);

  /// Arquivo bruto de chip de consumidor (23andMe, AncestryDNA…).
  bool get isChip => fileFormat?.startsWith('chip:') ?? false;

  /// FASTA de referência.
  bool get isFasta => fileFormat == 'fasta';

  /// Fornecedor do chip (`23andMe`…), ou `null`.
  String? get chipVendor => isChip ? fileFormat!.substring(5) : null;
}

final databaseProvider = Provider<GenozDatabase>((ref) {
  final db = GenozDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(ref.watch(databaseProvider), ref.watch(appStorageProvider)),
);

final projectsProvider = StreamProvider<List<ProjectSummary>>(
  (ref) => ref.watch(projectRepositoryProvider).watchProjects(),
);

final projectProvider = StreamProvider.family<Project?, String>(
  (ref, id) => ref.watch(projectRepositoryProvider).watchProject(id),
);

final projectFilesProvider = StreamProvider.family<List<ProjectFile>, String>(
  (ref, projectId) => ref.watch(projectRepositoryProvider).watchFiles(projectId),
);

final projectFileProvider = FutureProvider.family<ProjectFile?, String>(
  (ref, id) => ref.watch(projectRepositoryProvider).getFile(id),
);
