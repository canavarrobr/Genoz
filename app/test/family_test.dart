import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/core/family_models.dart';
import 'package:genoz/core/genoz_core.dart';
import 'package:genoz/features/analysis/reproducibility.dart';
import 'package:genoz/features/family/family_actions.dart';
import 'package:genoz/features/family/family_screen.dart';
import 'package:genoz/features/family/family_setup_screen.dart';
import 'package:genoz/features/vault/project_vault.dart';
import 'package:genoz/l10n/generated/app_localizations.dart';
import 'package:genoz/persistence/analysis_repository.dart';
import 'package:genoz/persistence/database.dart';
import 'package:genoz/ui/theme.dart';

import 'support.dart';

const familySamples = ['AVO', 'PAI', 'MAE', 'FILHO', 'FILHA', 'VIZINHO', 'FILHO_REPETIDO'];

/// Projeto com o VCF da família (7 amostras, SHA-256 igual ao do manifesto da fixture).
Future<(String, ProjectFile)> familyProject(TestEnv env) async {
  final (pid, a, _) = await projectWithTwoFiles(env);
  final m = jsonDecode(fixture('familia_manifest.json')) as Map<String, dynamic>;
  final sha = (m['inputs'] as List).first['sha256'] as String;
  await (env.db.update(env.db.projectFiles)..where((t) => t.id.equals(a.id))).write(ProjectFilesCompanion(
        samplesJson: Value(jsonEncode(familySamples)),
        sha256: Value(sha),
        displayName: const Value('familia.vcf'),
      ));
  await env.storage.blobs.writeBytes(a.storedPath, Uint8List.fromList(utf8.encode('##fileformat=VCFv4.3\n')));
  env.core.sha256ByName = {'familia.vcf': sha};
  return (pid, (await env.repo.getFile(a.id))!);
}

Widget app(ProviderContainer c, Widget home) => UncontrolledProviderScope(
      container: c,
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
        home: home,
      ),
    );

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('o resultado real do núcleo (família fictícia) é lido pelos modelos', () {
    final r = FamilyResult.parse(fixture('familia.json'));
    expect(r.samples, familySamples);
    expect(r.pairs, hasLength(21));
    final dup = r.pair(3, 6)!;
    expect(dup.relation, Relation.duplicate);
    expect(dup.kinship, closeTo(0.5, 0.01));
    expect(r.pair(1, 3)!.relation, Relation.parentOffspring);
    expect(r.pair(3, 4)!.relation, Relation.fullSiblings);
    expect(r.pair(0, 3)!.relation, Relation.secondDegree);
    expect(r.pair(1, 2)!.relation, Relation.unrelated);
    expect(r.pair(2, 2), isNull);
    expect(r.trio!.deNovo, 3);
    expect(r.trio!.events.where((e) => e.deNovo), hasLength(3));
    expect(r.roh[5].runs, hasLength(1));
    expect(r.rohAvailable, isTrue);
  });

  test('opções: ida e volta e chaves que o núcleo espera', () {
    const o = FamilyOptions(
      samples: ['A', 'B'],
      trio: TrioRoles(child: 'A', father: 'B', mother: 'C'),
      passOnly: true,
      minGq: 20,
    );
    final j = jsonDecode(o.toJsonString()) as Map<String, dynamic>;
    expect(j.keys, containsAll(['call_filter', 'samples', 'trio']));
    expect(FamilyOptions.parse(o.toJsonString()).toJsonString(), o.toJsonString());
  });

  group('análise salva', () {
    late TestEnv env;
    tearDown(() => env.dispose());

    test('rodar grava no banco e na pasta; reprodutibilidade; cofre leva junto', () async {
      env = await TestEnv.create();
      final (pid, file) = await familyProject(env);
      expect(isMultiSampleVcf(file), isTrue);
      final actions = env.container.read(familyActionsProvider);
      final id = await actions.run(
        projectId: pid,
        file: file,
        options: const FamilyOptions(trio: TrioRoles(child: 'FILHO', father: 'PAI', mother: 'MAE')),
        journalMessage: 'família',
      );
      final repo = env.container.read(analysisRepositoryProvider);
      final fa = (await repo.getFamilyAnalysis(id))!;
      expect((fa.sampleCount, fa.hasTrio, fa.contentId), (7, true, '15cd6732-77c1-8fe4-b3ac-c992e2f03382'));
      expect(await env.storage.blobs.exists('${fa.resultDir}/familia.json'), isTrue);
      expect(env.core.lastFamilyOptions, contains('"FILHO"'));
      final result = await env.container.read(familyResultProvider(id).future);
      expect(result!.samples, familySamples);

      final repro = await env.container.read(familyReproducibilityProvider)(fa);
      expect(repro.inputsOk, isTrue);
      expect(repro.reproduced, isTrue);

      // Cofre: exportar e importar leva a análise de família.
      final vault = env.container.read(projectVaultProvider);
      final out = await vault.export(pid, 'senha muito boa');
      final newPid = await vault.import(
        SourceFile(name: 'p.genoz', path: env.storage.absolute(out)),
        'senha muito boa',
        journalMessage: 'importado',
      );
      final imported = await (env.db.select(env.db.familyAnalyses)..where((t) => t.projectId.equals(newPid))).getSingle();
      expect(imported.id, isNot(id));
      expect(imported.contentId, fa.contentId);
      expect(imported.fileId, isNot(file.id));
      expect(await env.storage.blobs.readString('${imported.resultDir}/familia.json'), fixture('familia.json'));

      // Proteger apaga a linha; abrir devolve com o mesmo ID.
      await vault.lock(pid, 'senha muito boa');
      expect(await repo.getFamilyAnalysis(id), isNull);
      await vault.unlock(pid, 'senha muito boa', journalMessage: 'aberto');
      expect((await repo.getFamilyAnalysis(id))!.contentId, fa.contentId);

      await repo.deleteFamilyAnalysis(fa);
      expect(await env.storage.blobs.exists('${fa.resultDir}/familia.json'), isFalse);
    });
  });

  testWidgets('tela de resultado: aviso, parentesco, trio com as de novo', (tester) async {
    final env = (await tester.runAsync(TestEnv.create))!;
    final id = (await tester.runAsync(() async {
      final (pid, file) = await familyProject(env);
      return env.container.read(familyActionsProvider).run(
            projectId: pid,
            file: file,
            options: const FamilyOptions(trio: TrioRoles(child: 'FILHO', father: 'PAI', mother: 'MAE')),
            journalMessage: 'família',
          );
    }))!;
    await tester.pumpWidget(app(env.container, FamilyScreen(familyId: id)));
    await settle(tester);
    expect(find.textContaining('Não é teste de paternidade'), findsOneWidget);
    expect(find.text('Matriz de parentesco'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('FILHO × FILHO_REPETIDO'), 300, scrollable: find.byType(Scrollable).at(1));
    expect(find.textContaining('Mesma pessoa ou gêmeos idênticos'), findsOneWidget);

    await tester.tap(find.text('Trio'));
    await settle(tester);
    expect(find.text('Filho(a): FILHO · Pai: PAI · Mãe: MAE'), findsOneWidget);
    expect(find.text('Candidatas a de novo'), findsOneWidget);
    expect(find.text('3'), findsWidgets);

    await tester.tap(find.text('ROH'));
    await settle(tester);
    final rohList = find.ancestor(of: find.textContaining('Runs of homozygosity (ROH)'), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.textContaining('1 trechos · 12,0 Mb'), 200, scrollable: rohList);
    expect(find.textContaining('1 trechos · 12,0 Mb'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });

  testWidgets('configuração: amostras e trio com pessoas repetidas é recusado', (tester) async {
    final env = (await tester.runAsync(TestEnv.create))!;
    final pid = (await tester.runAsync(() async => (await familyProject(env)).$1))!;
    await tester.pumpWidget(app(env.container, FamilySetupScreen(projectId: pid)));
    await settle(tester);
    expect(find.text('Amostras (7 de no máximo 32)'), findsOneWidget);
    for (final s in familySamples) {
      expect(find.widgetWithText(FilterChip, s), findsOneWidget);
    }
    // Só uma amostra marcada: não dá para analisar.
    for (final s in familySamples.skip(1)) {
      await tester.tap(find.widgetWithText(FilterChip, s));
    }
    await tester.pump();
    final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
    expect(fab.onPressed, isNull, reason: 'Analisar desativado');
    await tester.scrollUntilVisible(find.text('Escolha de 2 a 32 amostras.'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Escolha de 2 a 32 amostras.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });
}
