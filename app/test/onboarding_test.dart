import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/features/projects/projects_screen.dart';
import 'package:genoz/features/settings/settings.dart';
import 'package:genoz/l10n/generated/app_localizations.dart';
import 'package:genoz/persistence/project_repository.dart';
import 'package:genoz/platform/blob_store_io.dart';
import 'package:genoz/ui/theme.dart';

import 'support.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('ajustes: instalação nova vê a apresentação; quem atualiza não', () async {
    final dir = await Directory.systemTemp.createTemp('genoz_onb_');
    addTearDown(() => dir.delete(recursive: true));
    final blobs = IoBlobStore(dir.path);
    expect((await AppSettings.load(blobs)).onboardingDone, isFalse, reason: 'sem ajustes.json');
    // ajustes.json de uma versão anterior (sem o campo).
    await File('${dir.path}/$settingsFile').writeAsString(jsonEncode({'schema': 1, 'theme': 'dark'}));
    expect((await AppSettings.load(blobs)).onboardingDone, isTrue);
    expect(AppSettings.fromJson(const AppSettings(onboardingDone: false).toJson()).onboardingDone, isFalse);
  });

  test('traduções: pt e en com as mesmas chaves e marcadores', () {
    Map<String, dynamic> arb(String lang) =>
        jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;
    final (pt, en) = (arb('pt'), arb('en'));
    final keys = {for (final k in pt.keys) if (!k.startsWith('@')) k};
    expect({for (final k in en.keys) if (!k.startsWith('@')) k}, keys);
    final marker = RegExp(r'\{(\w+)\}');
    for (final k in keys) {
      final a = {for (final m in marker.allMatches(pt[k] as String)) m[1]};
      final b = {for (final m in marker.allMatches(en[k] as String)) m[1]};
      expect(b, a, reason: k);
    }
  });

  testWidgets('primeira abertura: apresentação → começar → lista de projetos', (tester) async {
    final env = (await tester.runAsync(() => TestEnv.create()))!;
    final container = ProviderContainer(
      parent: env.container,
      overrides: [
        initialSettingsProvider.overrideWithValue(const AppSettings(onboardingDone: false)),
        settingsProvider.overrideWith(SettingsController.new),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
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
    await tester.pumpAndSettle();
    expect(find.text('Compare, explore e aprenda'), findsOneWidget);
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Tudo fica no seu aparelho'), findsOneWidget);
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Educação e pesquisa — não é diagnóstico'), findsOneWidget);
    expect(find.text('Experimentar com dados fictícios'), findsOneWidget);
    await tester.tap(find.text('Começar'));
    // A lista de projetos carrega do banco (E/S real): espera com limite, sem pumpAndSettle.
    await pumpUntil(tester, find.text('Novo projeto'));
    expect(container.read(settingsProvider).onboardingDone, isTrue);
    expect(find.text('Novo projeto'), findsOneWidget);
    expect(container.read(projectsProvider).value ?? const [], isEmpty);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(env.dispose);
  });

  testWidgets('apresentação: "Experimentar com dados fictícios" cria o projeto Exemplo e importa o VCF', (tester) async {
    final env = (await tester.runAsync(() => TestEnv.create()))!;
    final container = ProviderContainer(
      parent: env.container,
      overrides: [
        initialSettingsProvider.overrideWithValue(const AppSettings(onboardingDone: false)),
        settingsProvider.overrideWith(SettingsController.new),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
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
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Experimentar com dados fictícios'));
    // Criação do projeto e importação usam E/S real: espera o arquivo aparecer no banco (com limite).
    for (var i = 0; i < 200; i++) {
      final n = (await tester.runAsync(() => env.db.select(env.db.projectFiles).get()))!.length;
      if (n > 0) break;
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull);
    expect(container.read(settingsProvider).onboardingDone, isTrue);
    final projects = (await tester.runAsync(() => env.db.select(env.db.projects).get()))!;
    expect(projects.single.name, 'Exemplo');
    final files = (await tester.runAsync(() => env.db.select(env.db.projectFiles).get()))!;
    expect(files, hasLength(1), reason: 'VCF fictício importado');
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(env.dispose);
  });
}
