import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show TableInfo, Value, Variable, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/core/compare_models.dart';
import 'package:genoz/core/genoz_core.dart';
import 'package:genoz/features/analysis/reproducibility.dart';
import 'package:genoz/features/compare/compare_controller.dart';
import 'package:genoz/features/projects/projects_screen.dart';
import 'package:genoz/features/vault/project_vault.dart';
import 'package:genoz/l10n/generated/app_localizations.dart';
import 'package:genoz/persistence/analysis_repository.dart';
import 'package:genoz/persistence/database.dart';
import 'package:genoz/ui/theme.dart';

import 'support.dart';

/// Projeto com dois arquivos (conteúdo real no armazenamento), uma análise, nota, filtro e diário.
Future<(String, Analysis)> richProject(TestEnv env) async {
  final (pid, a, b) = await projectWithTwoFiles(env);
  await env.storage.blobs.writeBytes(a.storedPath, Uint8List.fromList(utf8.encode('##fileformat=VCFv4.3\nA\n')));
  await env.storage.blobs.writeBytes(b.storedPath, Uint8List.fromList(utf8.encode('##fileformat=VCFv4.3\nB\n')));
  await env.container.read(compareControllerProvider.notifier).run(
        projectId: pid,
        a: (file: a, sample: null),
        b: (file: b, sample: 'PESSOA_B'),
        options: const CompareOptions(passOnly: true, minDp: 10),
        journalMessage: (x, y, id) => 'comparou',
      );
  final id = (env.container.read(compareControllerProvider) as CompareSucceeded).analysisId;
  final repo = env.container.read(analysisRepositoryProvider);
  await repo.saveNote(pid, '1:1000:A:G', note: 'interessante', tags: ['aula'], favorite: true);
  await repo.saveFilter(pid, 'Só A', const RowFilter(categories: {'only_a'}));
  return (pid, (await repo.getAnalysis(id))!);
}

Future<int> count(GenozDatabase db, TableInfo<dynamic, dynamic> t, String pid) async {
  final rows = await db.customSelect('SELECT COUNT(*) AS n FROM ${t.actualTableName} WHERE project_id = ?',
      variables: [Variable.withString(pid)]).getSingle();
  return rows.read<int>('n');
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('CompareOptions.parse lê o que toJsonString grava', () {
    const o = CompareOptions(passOnly: true, minQual: 30, minDp: 10, minGq: 20, truth: 'a');
    final p = CompareOptions.parse(o.toJsonString());
    expect(p.toJsonString(), o.toJsonString());
  });

  group('cofre .genoz', () {
    late TestEnv env;
    tearDown(() => env.dispose());

    test('exportar e importar: projeto novo, IDs novos, mesmo conteúdo e mesmo ID de análise', () async {
      env = await TestEnv.create();
      final (pid, analysis) = await richProject(env);
      final vault = env.container.read(projectVaultProvider);
      final out = await vault.export(pid, 'senha muito boa');
      expect(out, startsWith('$tempDir/'));

      final file = SourceFile(name: 'p.genoz', path: env.storage.absolute(out));
      await expectLater(
        vault.import(file, 'errada', journalMessage: 'importado'),
        throwsA(isA<VaultError>().having((e) => e.code, 'code', 'senha')),
      );
      expect(await env.db.select(env.db.projects).get(), hasLength(1), reason: 'senha errada não cria nada');

      final newId = await vault.import(file, 'senha muito boa', journalMessage: 'importado');
      expect(newId, isNot(pid));
      final db = env.db;
      final files = await (db.select(db.projectFiles)..where((t) => t.projectId.equals(newId))).get();
      expect(files.map((f) => f.displayName).toSet(), {'fa.vcf', 'fb.vcf'});
      expect(files.map((f) => f.id).toSet().intersection({'fa', 'fb'}), isEmpty, reason: 'IDs de arquivo novos');
      for (final f in files) {
        expect(f.storedPath, startsWith('projetos/$newId/arquivos/${f.id}'));
        final text = utf8.decode(await env.storage.blobs.readBytes(f.storedPath));
        expect(text, contains(f.displayName == 'fa.vcf' ? '\nA\n' : '\nB\n'));
      }
      final analyses = await (db.select(db.analyses)..where((t) => t.projectId.equals(newId))).get();
      expect(analyses.single.contentId, analysis.contentId);
      expect(analyses.single.id, isNot(analysis.id));
      expect({analyses.single.fileAId, analyses.single.fileBId}, files.map((f) => f.id).toSet());
      expect(analyses.single.sampleB, 'PESSOA_B');
      expect(await env.storage.blobs.exists('${analyses.single.resultDir}/summary.json'), isTrue);
      expect(await count(db, db.variantNotes, newId), 1);
      expect(await count(db, db.savedFilters, newId), 1);
      final journal = await (db.select(db.journalEntries)..where((t) => t.projectId.equals(newId))).get();
      expect(journal.map((j) => j.message), containsAll(['comparou', 'importado']));
      // O original continua intacto.
      expect(await count(db, db.projectFiles, pid), 2);
    });

    test('proteger: só o cofre fica; senha errada não abre; senha certa restaura com os mesmos IDs', () async {
      env = await TestEnv.create();
      final (pid, analysis) = await richProject(env);
      final vault = env.container.read(projectVaultProvider);
      final db = env.db;
      // Diário volumoso: ao apagar, sobram páginas livres (o caso que o VACUUM resolve).
      for (var i = 0; i < 200; i++) {
        await env.container.read(analysisRepositoryProvider).log(pid, 'note', 'anotação privada $i ${'x' * 200}');
      }
      await vault.lock(pid, 'outra senha boa');

      final p = await (db.select(db.projects)..where((t) => t.id.equals(pid))).getSingle();
      expect(p.locked, isTrue);
      for (final TableInfo<dynamic, dynamic> t in [db.projectFiles, db.analyses, db.variantNotes, db.savedFilters, db.journalEntries]) {
        expect(await count(db, t, pid), 0, reason: t.actualTableName);
      }
      expect(await env.storage.blobs.exists('projetos/$pid/arquivos/fa.vcf'), isFalse, reason: 'dados em claro apagados');
      expect(await env.storage.blobs.exists(vaultRelative(pid)), isTrue);
      // VACUUM: nenhuma página livre com restos do projeto (nomes de amostra, resumos, notas).
      final free = await db.customSelect('PRAGMA freelist_count').getSingle();
      expect(free.data.values.first, 0);

      await expectLater(vault.unlock(pid, 'errada', journalMessage: 'aberto'), throwsA(isA<VaultError>()));
      expect((await (db.select(db.projects)..where((t) => t.id.equals(pid))).getSingle()).locked, isTrue);

      // Exportar um projeto protegido = copiar o cofre (mesma senha).
      final out = await vault.export(pid, '');
      expect(await env.storage.blobs.readBytes(out), await env.storage.blobs.readBytes(vaultRelative(pid)));

      await vault.unlock(pid, 'outra senha boa', journalMessage: 'aberto');
      expect((await (db.select(db.projects)..where((t) => t.id.equals(pid))).getSingle()).locked, isFalse);
      final files = await (db.select(db.projectFiles)..where((t) => t.projectId.equals(pid))).get();
      expect(files.map((f) => f.id).toSet(), {'fa', 'fb'});
      expect((await env.container.read(analysisRepositoryProvider).getAnalysis(analysis.id))!.contentId, analysis.contentId);
      expect(utf8.decode(await env.storage.blobs.readBytes(files.first.storedPath)), startsWith('##fileformat'));
      expect(await env.storage.blobs.exists(vaultRelative(pid)), isFalse, reason: 'aberto: o cofre sai');
      expect(await count(db, db.variantNotes, pid), 1);
    });

    test('arquivo que não é .genoz e versão futura', () async {
      env = await TestEnv.create();
      final vault = env.container.read(projectVaultProvider);
      final notGenoz = SourceFile(name: 'x.vcf', path: await env.sourceFile('x.vcf'));
      await expectLater(
        vault.import(notGenoz, 'qualquer', journalMessage: ''),
        throwsA(isA<VaultError>().having((e) => e.code, 'code', 'formato')),
      );
      // Pacote de um Genoz mais novo.
      await env.storage.blobs.writeBytes(
        'novo.genoz',
        Uint8List.fromList(utf8.encode(jsonEncode({
          'falso_genoz': 'senha',
          'entries': {
            'projeto.json': base64Encode(utf8.encode(jsonEncode({'kind': 'genoz-project', 'schema': 99}))),
          },
        }))),
      );
      await expectLater(
        vault.import(SourceFile(name: 'novo.genoz', path: env.storage.absolute('novo.genoz')), 'senha', journalMessage: ''),
        throwsA(isA<VaultError>().having((e) => e.code, 'code', 'versao')),
      );
      expect(await env.db.select(env.db.projects).get(), isEmpty);
    });
  });

  group('reprodutibilidade', () {
    late TestEnv env;
    tearDown(() => env.dispose());

    Future<Analysis> setup() async {
      env = await TestEnv.create();
      final (pid, analysis) = await richProject(env);
      // Entradas com SHA-256 distintos e o manifesto apontando para elas.
      final db = env.db;
      await (db.update(db.projectFiles)..where((t) => t.id.equals('fb'))).write(
        ProjectFilesCompanion(sha256: Value('b' * 64)),
      );
      final fa = (await (db.select(db.projectFiles)..where((t) => t.id.equals('fa'))).getSingle());
      final m = jsonDecode(fixture('compare_manifest.json')) as Map<String, dynamic>;
      (m['inputs'] as List)[0]['sha256'] = fa.sha256;
      (m['inputs'] as List)[1]['sha256'] = 'b' * 64;
      await env.storage.blobs.writeBytes(
        '${analysis.resultDir}/manifest.json',
        Uint8List.fromList(utf8.encode(jsonEncode(m))),
      );
      env.core.sha256ByName = {'fa.vcf': fa.sha256, 'fb.vcf': 'b' * 64};
      return analysis;
    }

    test('mesmas entradas: reexecuta numa pasta temporária e confere as 5 saídas', () async {
      final analysis = await setup();
      final r = await env.container.read(reproducibilityProvider)(analysis);
      expect(r.inputsOk, isTrue);
      expect(r.sameId, isTrue);
      expect(r.identical, 5);
      expect(r.reproduced, isTrue);
      expect(env.core.lastOptions!.toJsonString(), const CompareOptions(passOnly: true, minDp: 10).toJsonString());
      expect(env.core.lastB!.sample, 'PESSOA_B');
      expect(await env.storage.blobs.exists('$tempDir/x'), isFalse);
    });

    test('arquivo alterado: não reexecuta e aponta qual entrada mudou', () async {
      final analysis = await setup();
      env.core.sha256ByName['fb.vcf'] = 'c' * 64;
      final runsBefore = env.core.lastB;
      env.core.lastB = null;
      final r = await env.container.read(reproducibilityProvider)(analysis);
      expect(r.inputsOk, isFalse);
      expect(r.inputs.firstWhere((i) => i.role == 'b').problem, 'alterado');
      expect(r.reproduced, isFalse);
      expect(env.core.lastB, isNull, reason: 'não reexecutou');
      expect(runsBefore, isNotNull);
    });
  });

  testWidgets('lista: projeto protegido aparece com cadeado e "Protegido com senha"', (tester) async {
    final env = (await tester.runAsync(TestEnv.create))!;
    await tester.runAsync(() async {
      final (pid, _) = await richProject(env);
      await env.container.read(projectVaultProvider).lock(pid, 'senha muito boa');
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: env.container,
      child: MaterialApp(
        theme: genozTheme(Brightness.light),
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProjectsScreen(),
      ),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.textContaining('Protegido com senha'), findsOneWidget);
    expect(find.byTooltip('Importar projeto (.genoz)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });
}
