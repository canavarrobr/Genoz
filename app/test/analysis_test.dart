import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/core/compare_models.dart';
import 'package:genoz/features/analysis/analysis_screen.dart';
import 'package:genoz/features/compare/compare_controller.dart';
import 'package:genoz/features/projects/projects_screen.dart';
import 'package:genoz/features/projects/project_screen.dart';
import 'package:genoz/features/compare/compare_setup_screen.dart';
import 'package:genoz/features/analysis/region_viewer.dart';
import 'package:genoz/l10n/generated/app_localizations.dart';
import 'package:genoz/persistence/analysis_repository.dart';
import 'package:genoz/persistence/database.dart';
import 'package:genoz/ui/theme.dart';

import 'support.dart';

/// Dois arquivos importados num projeto novo.

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('migração v1 → v4 mantém os dados, cria as tabelas novas e a coluna de proteção', () async {
    final db = GenozDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE projects (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, '
          'description TEXT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)');
      raw.execute("INSERT INTO projects VALUES ('p1', 'Antigo', NULL, 0, 0)");
      raw.execute('PRAGMA user_version = 1');
    }));
    final projects = await db.select(db.projects).get();
    expect(projects.single.name, 'Antigo');
    await db.into(db.journalEntries).insert(
          JournalEntriesCompanion.insert(projectId: 'p1', kind: 'import', message: 'x', createdAt: DateTime.now()),
        );
    expect(await db.select(db.journalEntries).get(), hasLength(1));
    expect(await db.customSelect('PRAGMA user_version').getSingle().then((r) => r.data.values.first), 4);
    expect(await db.select(db.familyAnalyses).get(), isEmpty, reason: 'v4: tabela de família criada');
    expect(projects.single.locked, isFalse, reason: 'v3: projetos antigos não ficam protegidos');
    await db.close();
  });

  test('RowFilter vira o JSON que o núcleo Rust espera', () {
    const f = RowFilter(categories: {'only_b', 'only_a'}, minDp: 10, region: Region('7', 100, 200));
    expect(
      f.toJsonString(),
      '{"categories":["only_a","only_b"],"region":{"chrom":"7","start":100,"end":200},"min_dp":10}',
    );
    expect(RowFilter.parse(f.toJsonString()), f);
    expect(const RowFilter().isEmpty, isTrue);
    expect(f.activeCount, 3);
  });

  test('resumo e estatísticas reais do núcleo são lidos pelos modelos', () {
    final s = CompareSummary.parse(fixture('compare_summary.json'));
    expect([for (final c in categoryCodes) s.count(c)], [5, 1, 4, 1, 1, 0]);
    expect(s.a.sample, 'PESSOA_A');
    expect(s.genotypeConcordance, closeTo(5 / 6, 1e-9));
    final rows = ComparisonRow.parseList(fixture('compare_rows.json'));
    expect(rows, hasLength(12));
    expect(rows.firstWhere((r) => r.pos == 5000).b.state, 'explicit_ref');
    final st = SampleStats.parse(fixture('compare_stats_a.json'));
    expect(st.carriers, 11);
    expect(st.dpHist, isNotEmpty);
  });

  group('comparação', () {
    late TestEnv env;
    tearDown(() => env.dispose());

    test('sucesso grava análise, resultados e diário', () async {
      env = await TestEnv.create();
      final (pid, a, b) = await projectWithTwoFiles(env);
      final c = env.container.read(compareControllerProvider.notifier);
      await c.run(
        projectId: pid,
        a: (file: a, sample: null),
        b: (file: b, sample: 'AMOSTRA_B'),
        options: const CompareOptions(minGq: 20, truth: 'b'),
        journalMessage: (x, y, id) => 'cmp $x $y $id',
      );
      final state = env.container.read(compareControllerProvider);
      expect(state, isA<CompareSucceeded>());
      expect(env.core.lastOptions!.minGq, 20);
      expect(env.core.lastB!.sample, 'AMOSTRA_B');
      expect(env.core.lastA!.sha256, a.sha256);

      final repo = env.container.read(analysisRepositoryProvider);
      final analysis = (await repo.getAnalysis((state as CompareSucceeded).analysisId))!;
      expect(analysis.summary.count('only_a'), 4);
      expect(analysis.contentId, hasLength(36));
      expect(await File(env.storage.absolute('${analysis.resultDir}/stats_a.json')).exists(), isTrue);
      final journal = await repo.watchJournal(pid).first;
      expect(journal.single.kind, 'compare');
      expect(journal.single.message, contains('PESSOA_A'));

      await repo.deleteAnalysis(analysis);
      expect(await Directory(env.storage.absolute(analysis.resultDir)).exists(), isFalse);
      expect(await repo.watchAnalyses(pid).first, isEmpty);
    });

    test('falha do núcleo não grava análise', () async {
      env = await TestEnv.create(core: FakeGenozCore(compareFailWith: 'comparação recusada: builds diferentes'));
      final (pid, a, b) = await projectWithTwoFiles(env);
      await env.container.read(compareControllerProvider.notifier).run(
            projectId: pid,
            a: (file: a, sample: null),
            b: (file: b, sample: null),
            options: const CompareOptions(),
            journalMessage: (x, y, id) => '',
          );
      expect((env.container.read(compareControllerProvider) as CompareError).message, contains('builds'));
      expect(await env.container.read(analysisRepositoryProvider).watchAnalyses(pid).first, isEmpty);
    });
  });

  group('filtros salvos e notas', () {
    late TestEnv env;
    tearDown(() => env.dispose());

    test('filtros salvos voltam iguais', () async {
      env = await TestEnv.create();
      final (pid, _, _) = await projectWithTwoFiles(env);
      final repo = env.container.read(analysisRepositoryProvider);
      await repo.saveFilter(pid, ' Só A ', const RowFilter(categories: {'only_a'}));
      final saved = (await repo.watchFilters(pid).first).single;
      expect(saved.name, 'Só A');
      expect(RowFilter.parse(saved.filterJson).categories, {'only_a'});
    });

    test('nota, etiquetas e favorito; vazio remove', () async {
      env = await TestEnv.create();
      final (pid, _, _) = await projectWithTwoFiles(env);
      final repo = env.container.read(analysisRepositoryProvider);
      await repo.saveNote(pid, '1:1000:A:G', note: ' revisar ', tags: ['aula', ' ', 'x'], favorite: true);
      final n = (await repo.watchNote(pid, '1:1000:A:G').first)!;
      expect((n.note, n.favorite), ('revisar', true));
      expect(n.tags, ['aula', 'x']);
      await repo.saveNote(pid, '1:1000:A:G', note: '', tags: [], favorite: false);
      expect(await repo.watchNote(pid, '1:1000:A:G').first, isNull);
    });
  });

  testWidgets('tela da análise mostra resumo e tabela', (tester) async {
    final env = await tester.runAsync(TestEnv.create);
    final (pid, a, b) = (await tester.runAsync(() => projectWithTwoFiles(env!)))!;
    await tester.runAsync(() => env!.container.read(compareControllerProvider.notifier).run(
          projectId: pid,
          a: (file: a, sample: null),
          b: (file: b, sample: null),
          options: const CompareOptions(),
          journalMessage: (x, y, id) => '',
        ));
    final id = (env!.container.read(compareControllerProvider) as CompareSucceeded).analysisId;

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
        home: AnalysisScreen(analysisId: id),
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    expect(find.text('PESSOA_A × PESSOA_B'), findsOneWidget);
    expect(find.text('12 linhas'), findsOneWidget);
    expect(find.text('Somente em A'), findsWidgets);
    await tester.scrollUntilVisible(find.text('83.3%'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('83.3%'), findsOneWidget); // concordância 5/6

    await tester.tap(find.text('Tabela'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('1:1000  A > G'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });

  testWidgets('telas principais cabem em tela pequena (320×568) com fonte 130%', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final env = await tester.runAsync(TestEnv.create);
    final (pid, a, b) = (await tester.runAsync(() => projectWithTwoFiles(env!)))!;
    await tester.runAsync(() => env!.container.read(compareControllerProvider.notifier).run(
          projectId: pid,
          a: (file: a, sample: null),
          b: (file: b, sample: null),
          options: const CompareOptions(),
          journalMessage: (x, y, id) => '',
        ));
    final id = (env!.container.read(compareControllerProvider) as CompareSucceeded).analysisId;

    Future<void> show(Widget screen, {String? tab}) async {
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
          home: screen,
        ),
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pumpAndSettle();
      if (tab != null) {
        await tester.tap(find.text(tab));
        // A aba lê arquivos do disco em vários passos: alterna espera real e quadros até o carregamento sumir.
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          if (i > 3 && find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
        }
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull, reason: '${screen.runtimeType} ${tab ?? ''}');
    }

    await show(const ProjectsScreen());
    await show(ProjectScreen(projectId: pid));
    await show(CompareSetupScreen(projectId: pid));
    await show(AnalysisScreen(analysisId: id));
    await show(AnalysisScreen(analysisId: id), tab: 'Tabela');
    await show(AnalysisScreen(analysisId: id), tab: 'QC');
    await show(AnalysisScreen(analysisId: id), tab: 'Mapa');
    final analysis = (await tester.runAsync(() => env.container.read(analysisProvider(id).future)))!;
    await show(RegionViewerScreen(analysis: analysis, initial: const Region('1', 1, 248956422)));

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });
}
