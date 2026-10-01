import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/core/compare_models.dart';
import 'package:genoz/core/density.dart';
import 'package:genoz/features/analysis/analysis_screen.dart';
import 'package:genoz/features/analysis/intersection_diagram.dart';
import 'package:genoz/features/analysis/map_tab.dart';
import 'package:genoz/features/compare/compare_controller.dart';
import 'package:genoz/l10n/generated/app_localizations.dart';
import 'package:genoz/ui/theme.dart';

import 'support.dart';

Widget _material(Widget home) => MaterialApp(
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
    );

/// Alterna espera real (E/S do teste) e quadros até o carregamento sumir.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    if (i > 3 && find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}

DensityMap _map(List<ChromDensity> chroms) =>
    DensityMap(binSize: 1000000, total: chroms.fold(0, (a, c) => a + c.total), chroms: chroms);

void main() {
  group('cariótipo e ideograma', () {
    test('tabelas têm 24 cromossomos e batem com os comprimentos do núcleo', () {
      for (final build in ['GRCh37', 'GRCh38']) {
        final k = karyotype(build);
        expect(k.map((c) => c.name), [for (var i = 1; i <= 22; i++) '$i', 'X', 'Y']);
        for (final c in k) {
          expect(c.centromere, inInclusiveRange(1, c.length), reason: '${c.name} $build');
        }
      }
      expect(karyotype('GRCh38').first.length, 248956422);
      expect(karyotype('GRCh37').first.length, 249250621);
    });

    test('build conhecido: todos os cromossomos aparecem, mesmo sem variantes; extras no fim', () {
      final map = _map([
        const ChromDensity(chrom: '7', maxPos: 100, total: 2, counts: {'shared': [2]}),
        const ChromDensity(chrom: 'MT', maxPos: 16000, total: 1, counts: {'only_a': [1]}),
      ]);
      final chroms = ideogramChroms('GRCh38', map);
      expect(chroms.length, 25);
      expect(chroms.firstWhere((c) => c.name == '1').density, isNull, reason: 'vazio, mas presente');
      expect(chroms.firstWhere((c) => c.name == '7').density!.total, 2);
      expect(chroms.last.name, 'MT');
      expect(chroms.last.centromere, isNull);
    });

    test('build desconhecido: só os cromossomos vistos, comprimento = maior posição', () {
      final map = _map([const ChromDensity(chrom: '3', maxPos: 5000, total: 1, counts: {'only_b': [1]})]);
      final chroms = ideogramChroms('unknown', map);
      expect(chroms.single.length, 5000);
    });

    test('soma por categoria escolhida', () {
      const c = ChromDensity(chrom: '1', maxPos: 3000000, total: 4, counts: {'shared': [1, 0, 1], 'only_a': [0, 2, 0]});
      expect(c.binsFor({}), [1, 2, 1]);
      expect(c.binsFor({'only_a'}), [0, 2, 0]);
      expect(c.countFor({'shared'}), 2);
    });
  });

  testWidgets('diagrama de interseções mostra os números do resumo', (tester) async {
    final summary = CompareSummary.parse(fixture('compare_summary.json'));
    await tester.pumpWidget(_material(Scaffold(body: SingleChildScrollView(child: IntersectionDiagram(summary: summary)))));
    await tester.pumpAndSettle();
    // pessoa_a × pessoa_b: só A 4; nos dois 5 + 1; só B 1; fora 1 ausente/incerta.
    expect(find.text('4'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('5 iguais · 1 genótipo diferente'), findsOneWidget);
    expect(find.textContaining('1 ausentes/incertas e 0 não avaliadas'), findsOneWidget);
  });

  testWidgets('aba Mapa: ideograma com todos os cromossomos; toque abre a região com as variantes', (tester) async {
    final semantics = tester.ensureSemantics();
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
    await tester.pumpWidget(UncontrolledProviderScope(container: env.container, child: _material(AnalysisScreen(analysisId: id))));
    await settle(tester);

    await tester.tap(find.text('Mapa'));
    await settle(tester);
    expect(find.byType(MapTab), findsOneWidget);
    expect(find.bySemanticsLabel('Cromossomo 1: 12 variantes. Toque para ver a região.'), findsOneWidget);
    // Cromossomo sem variantes também aparece (GRCh38 = 24).
    final mapList = find.descendant(of: find.byType(MapTab), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.bySemanticsLabel(RegExp('Cromossomo Y: 0 variantes')), 300, scrollable: mapList);

    // Filtra "Somente em A": o cromossomo 1 passa a ter 4.
    await tester.scrollUntilVisible(find.widgetWithText(FilterChip, 'Somente em A'), -300, scrollable: mapList);
    await tester.tap(find.widgetWithText(FilterChip, 'Somente em A'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Cromossomo 1: 4 variantes. Toque para ver a região.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Cromossomo 1: 4 variantes. Toque para ver a região.'));
    await settle(tester);
    expect(find.text('Cromossomo 1'), findsOneWidget);
    expect(find.text('4 variantes neste trecho'), findsOneWidget);

    // Região digitada fora do cromossomo aberto é recusada.
    await tester.enterText(find.byType(TextField), '2:1000-2000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.textContaining('Use posições do cromossomo 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
    semantics.dispose();
  });
}
