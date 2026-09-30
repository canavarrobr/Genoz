import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'features/projects/project_screen.dart';
import 'features/projects/projects_screen.dart';
import 'features/report/file_report_screen.dart';
import 'l10n/generated/app_localizations.dart';
import 'ui/theme.dart';

GoRouter buildRouter() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ProjectsScreen()),
        GoRoute(
          path: '/projeto/:id',
          builder: (_, s) => ProjectScreen(projectId: s.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'arquivo/:fileId',
              builder: (_, s) => FileReportScreen(fileId: s.pathParameters['fileId']!),
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
