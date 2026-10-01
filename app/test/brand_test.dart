import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/core/genoz_core.dart';
import 'package:genoz/features/about/about_screen.dart';
import 'package:genoz/l10n/generated/app_localizations.dart';
import 'package:genoz/ui/brand.dart';
import 'package:genoz/ui/theme.dart';

import 'support.dart';

Widget _app(Widget home, {Brightness brightness = Brightness.light, Locale locale = const Locale('pt')}) =>
    ProviderScope(
      overrides: [genozCoreProvider.overrideWithValue(FakeGenozCore())],
      child: MaterialApp(
        theme: genozTheme(brightness),
        locale: locale,
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

void main() {
  testWidgets('tela Sobre mostra assinatura, slogan, pilares e versões', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(const AboutScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Sua genômica, no seu controle.'), findsOneWidget);
    expect(find.bySemanticsLabel('Genoz'), findsWidgets, reason: 'o logo tem nome acessível');
    for (final pilar in ['Ciência', 'Desempenho', 'Multiplataforma']) {
      await tester.scrollUntilVisible(find.text(pilar), 200);
      expect(find.text(pilar), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.textContaining('núcleo 0.0.0-teste'), 200);
    expect(find.textContaining('Versão do app $appVersion'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('menu lateral destaca o item atual e mostra a verificação de privacidade', (tester) async {
    await tester.pumpWidget(_app(const Scaffold(drawer: GenozDrawer(current: '/sobre'), body: SizedBox())));
    final state = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Projetos'), findsOneWidget);
    final active = tester.widget<ListTile>(find.ancestor(of: find.text('Sobre o Genoz'), matching: find.byType(ListTile)));
    expect(active.selected, isTrue);
    expect(find.text('Verificar privacidade'), findsOneWidget);
  });

  testWidgets('tela Sobre também funciona em inglês e no tema escuro', (tester) async {
    await tester.pumpWidget(_app(const AboutScreen(), brightness: Brightness.dark, locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Your genomics, under your control.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
