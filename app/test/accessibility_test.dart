// Acessibilidade (Módulo 13): diretrizes do Flutter nas telas principais, em claro e escuro.
// - alvos de toque ≥ 48 × 48 dp (Android);
// - todo alvo de toque com rótulo (leitor de tela);
// - contraste de texto (WCAG AA).

import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/core/compare_models.dart';
import 'package:genoz/core/family_models.dart';
import 'package:genoz/features/about/about_screen.dart';
import 'package:genoz/features/analysis/analysis_screen.dart';
import 'package:genoz/features/annotation/annotations_screen.dart';
import 'package:genoz/features/compare/compare_controller.dart';
import 'package:genoz/features/family/family_actions.dart';
import 'package:genoz/features/family/family_screen.dart';
import 'package:genoz/features/onboarding/onboarding_screen.dart';
import 'package:genoz/features/projects/project_screen.dart';
import 'package:genoz/features/projects/projects_screen.dart';
import 'package:genoz/features/settings/settings_screen.dart';
import 'package:genoz/l10n/generated/app_localizations.dart';
import 'package:genoz/ui/theme.dart';
import 'package:go_router/go_router.dart';

import 'support.dart';

Widget _app(ProviderContainer c, Widget home, Brightness b) => UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(
        theme: genozTheme(b),
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => home)]),
      ),
    );

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> checkGuidelines(WidgetTester tester, String screen) async {
  for (final (name, g) in [
    ('alvo de toque', androidTapTargetGuideline),
    ('rótulo', labeledTapTargetGuideline),
    ('contraste', textContrastGuideline),
  ]) {
    final r = await g.evaluate(tester);
    expect(r.passed, isTrue, reason: '$screen — $name:\n${r.reason}');
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  for (final b in Brightness.values) {
    testWidgets('telas principais seguem as diretrizes (${b.name})', (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final env = (await tester.runAsync(TestEnv.create))!;
      final (pid, analysisId, familyId) = (await tester.runAsync(() async {
        final (pid, a, bf) = await projectWithTwoFiles(env);
        await env.container.read(compareControllerProvider.notifier).run(
              projectId: pid,
              a: (file: a, sample: null),
              b: (file: bf, sample: null),
              options: const CompareOptions(),
              journalMessage: (x, y, id) => '',
            );
        final id = (env.container.read(compareControllerProvider) as CompareSucceeded).analysisId;
        // Família: o mesmo VCF passa a ter 7 amostras (resultado real da fixture).
        await env.db.customStatement(
          'UPDATE project_files SET samples_json = ? WHERE id = ?',
          [jsonEncode(['AVO', 'PAI', 'MAE', 'FILHO', 'FILHA', 'VIZINHO', 'FILHO_REPETIDO']), a.id],
        );
        final f = (await env.repo.getFile(a.id))!;
        final fid = await env.container.read(familyActionsProvider).run(
              projectId: pid,
              file: f,
              options: const FamilyOptions(trio: TrioRoles(child: 'FILHO', father: 'PAI', mother: 'MAE')),
              journalMessage: '',
            );
        return (pid, id, fid);
      }))!;

      final screens = <String, Widget>{
        'Projetos': const ProjectsScreen(),
        'Projeto': ProjectScreen(projectId: pid),
        'Análise · Resumo': AnalysisScreen(analysisId: analysisId),
        'Análise · Tabela': AnalysisScreen(analysisId: analysisId, initialTab: 1),
        'Análise · QC': AnalysisScreen(analysisId: analysisId, initialTab: 3),
        'Família': FamilyScreen(familyId: familyId),
        'Anotações': const AnnotationsScreen(),
        'Ajustes': const SettingsScreen(),
        'Sobre': const AboutScreen(),
        'Apresentação': const OnboardingScreen(again: true),
      };
      for (final e in screens.entries) {
        await tester.pumpWidget(_app(env.container, e.value, b));
        await settle(tester);
        await checkGuidelines(tester, e.key);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(env.dispose);
      handle.dispose();
    });
  }

  testWidgets('telas novas cabem em tela pequena (320×568) com fonte 130%', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final env = (await tester.runAsync(TestEnv.create))!;
    final familyId = (await tester.runAsync(() async {
      final (pid, a, _) = await projectWithTwoFiles(env);
      await env.db.customStatement(
        'UPDATE project_files SET samples_json = ? WHERE id = ?',
        [jsonEncode(['AVO', 'PAI', 'MAE', 'FILHO', 'FILHA', 'VIZINHO', 'FILHO_REPETIDO']), a.id],
      );
      return env.container.read(familyActionsProvider).run(
            projectId: pid,
            file: (await env.repo.getFile(a.id))!,
            options: const FamilyOptions(trio: TrioRoles(child: 'FILHO', father: 'PAI', mother: 'MAE')),
            journalMessage: '',
          );
    }))!;
    Future<void> show(Widget w, String name, {List<String> tabs = const []}) async {
      await tester.pumpWidget(_app(env.container, w, Brightness.light));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: name);
      for (final t in tabs) {
        await tester.tap(find.text(t));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: '$name · $t');
      }
    }

    await show(FamilyScreen(familyId: familyId), 'Família', tabs: ['ROH', 'Trio', 'Interseções']);
    await show(const OnboardingScreen(again: true), 'Apresentação');
    await show(const AnnotationsScreen(), 'Anotações');
    await show(const SettingsScreen(), 'Ajustes');
    await show(const AboutScreen(), 'Sobre');
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });
}
