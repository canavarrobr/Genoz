import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'features/about/about_screen.dart';
import 'features/analysis/analysis_screen.dart';
import 'features/compare/compare_setup_screen.dart';
import 'features/privacy/privacy_screen.dart';
import 'features/projects/journal_screen.dart';
import 'features/projects/project_screen.dart';
import 'features/projects/projects_screen.dart';
import 'features/report/file_report_screen.dart';
import 'l10n/generated/app_localizations.dart';
import 'ui/theme.dart';

GoRouter buildRouter() => GoRouter(
      // No navegador o endereço pode ser digitado à mão: rota desconhecida volta ao início.
      onException: (_, _, router) => router.go('/'),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ProjectsScreen()),
        GoRoute(path: '/sobre', builder: (_, _) => const AboutScreen()),
        GoRoute(path: '/privacidade', builder: (_, _) => const PrivacyScreen()),
        GoRoute(
          path: '/projeto/:id',
          builder: (_, s) => ProjectScreen(projectId: s.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'arquivo/:fileId',
              builder: (_, s) => FileReportScreen(fileId: s.pathParameters['fileId']!),
            ),
            GoRoute(
              path: 'comparar',
              builder: (_, s) => CompareSetupScreen(projectId: s.pathParameters['id']!),
            ),
            GoRoute(
              path: 'analise/:analysisId',
              builder: (_, s) => AnalysisScreen(analysisId: s.pathParameters['analysisId']!),
            ),
            GoRoute(
              path: 'diario',
              builder: (_, s) => JournalScreen(projectId: s.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );

class GenozApp extends StatefulWidget {
  const GenozApp({super.key});

  @override
  State<GenozApp> createState() => _GenozAppState();
}

class _GenozAppState extends State<GenozApp> {
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
        debugShowCheckedModeBanner: false,
        theme: genozTheme(Brightness.light),
        darkTheme: genozTheme(Brightness.dark),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
      );
}
