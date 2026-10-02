import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:genoz/core/compare_models.dart';
import 'package:genoz/core/inspect_report.dart';
import 'package:genoz/features/compare/compare_setup_screen.dart';
import 'package:genoz/features/import/zip_source.dart';
import 'package:genoz/features/report/file_report_screen.dart';
import 'package:genoz/l10n/generated/app_localizations.dart';
import 'package:genoz/persistence/database.dart';
import 'package:genoz/ui/theme.dart';

import 'support.dart';

Widget _app(ProviderContainer c, Widget home) => UncontrolledProviderScope(
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

/// Arquivo "importado" com um relatório real do núcleo.
Future<ProjectFile> _addFile(TestEnv env, String projectId, String id, String name, String reportFixture) async {
  final json = fixture(reportFixture);
  await env.repo.addImportedFile(
    projectId: projectId,
    fileId: id,
    displayName: name,
    storedPath: 'projetos/$projectId/arquivos/$id',
    report: InspectReport.parse(json),
    reportJson: json,
  );
  return (await env.repo.getFile(id))!;
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  }
  await tester.pumpAndSettle();
}

Uint8List _zip(Map<String, String> files) {
  final a = Archive();
  for (final e in files.entries) {
    a.addFile(ArchiveFile.string(e.key, e.value));
  }
  return ZipEncoder().encodeBytes(a);
}

void main() {
  group('modelos com o JSON real do núcleo', () {
    test('relatório de chip', () {
      final r = InspectReport.parse(fixture('report_chip.json'));
      expect(r.kind, FileKind.chip);
      expect(r.chip!.vendor, '23andMe');
      expect((r.chip!.sites, r.chip!.noCalls, r.chip!.indels), (14, 2, 1));
      expect(r.build, 'GRCh37');
    });

    test('relatório de FASTA', () {
      final r = InspectReport.parse(fixture('report_fasta.json'));
      expect(r.kind, FileKind.fasta);
      expect((r.fasta!.sequences, r.fasta!.totalBases), (1, 20000));
      expect(r.fasta!.names.single.$1, '1');
    });

    test('VCF continua sem bloco extra', () {
      expect(InspectReport.parse(fixture('report_vcf_grch37.json')).kind, FileKind.vcf);
    });

    test('resumo do chip × sequenciamento', () {
      final s = CompareSummary.parse(fixture('chip_compare_summary.json'));
      expect(s.chip, isNotNull);
      expect((s.chip!.sites, s.chip!.unknownReference, s.chip!.vcfVariantsOffChip), (13, 1, 2));
      expect(s.jaccard, isNull);
      expect(s.a.sample, '23andMe');
      // Comparações VCF × VCF não têm o bloco.
      expect(CompareSummary.parse(fixture('compare_summary.json')).chip, isNull);
    });
  });

  group('.zip de consumidor', () {
    test('um arquivo de dados: importa o de dentro', () async {
      final src = await unzipSingleDataFile(
        'genome.zip',
        _zip({'genome_Fulano_v5.txt': '# 23andMe\nrs1\t1\t100\tAG\n', '__MACOSX/._x.txt': 'lixo', 'LEIAME.pdf': '%PDF'}),
      );
      expect(src.name, 'genome_Fulano_v5.txt');
      final bytes = await src.open!().expand((c) => c).toList();
      expect(utf8.decode(bytes), contains('rs1'));
    });

    test('erros: vazio, mais de um, inválido', () async {
      Future<String> code(Uint8List b) async {
        try {
          await unzipSingleDataFile('x.zip', b);
          return 'ok';
        } on ZipImportError catch (e) {
          return e.code;
        }
      }

      expect(await code(_zip({'foto.jpg': 'x'})), 'empty');
      expect(await code(_zip({'a.txt': 'x', 'b.csv': 'y'})), 'many');
      expect(await code(Uint8List.fromList([1, 2, 3])), 'invalid');
    });
  });

  testWidgets('tela de comparação: chip vai para A, B só VCF, referência opcional, sem "verdade"', (tester) async {
    final env = (await tester.runAsync(TestEnv.create))!;
    final project = (await tester.runAsync(() => env.repo.createProject('Chip')))!;
    await tester.runAsync(() async {
      await _addFile(env, project.id, 'vcf1', 'pessoa.vcf', 'report_vcf_grch37.json');
      await _addFile(env, project.id, 'chip1', 'genome.txt', 'report_chip.json');
      await _addFile(env, project.id, 'fa1', 'ref.fa', 'report_fasta.json');
    });
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => CompareSetupScreen(projectId: project.id)),
        GoRoute(path: '/projeto/:id/analise/:aid', builder: (_, _) => const Text('análise aberta')),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: env.container,
        child: MaterialApp.router(
          theme: genozTheme(Brightness.light),
          locale: const Locale('pt'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);
    await pumpUntil(tester, find.textContaining('A é um arquivo de chip'));

    expect(find.textContaining('A é um arquivo de chip'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Referência (FASTA)'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Referência (FASTA)'), findsOneWidget);
    expect(find.text('Tratar como verdade (benchmark)'), findsNothing);

    // Escolhe o FASTA e compara.
    await tester.tap(find.text('Sem referência'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ref.fa').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparar'));
    await settle(tester);
    expect(env.core.lastChip, isTrue);
    expect(env.core.lastA!.displayName, 'genome.txt');
    expect(env.core.lastB!.displayName, 'pessoa.vcf');
    expect(env.core.lastReference!.displayName, 'ref.fa');
    expect(env.core.lastOptions!.truth, isNull);
    expect(find.text('análise aberta'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });

  testWidgets('relatório de chip e de FASTA mostram as seções próprias', (tester) async {
    final env = (await tester.runAsync(TestEnv.create))!;
    final project = (await tester.runAsync(() => env.repo.createProject('P')))!;
    await tester.runAsync(() async {
      await _addFile(env, project.id, 'chip1', 'genome.txt', 'report_chip.json');
      await _addFile(env, project.id, 'fa1', 'ref.fa', 'report_fasta.json');
    });

    await tester.pumpWidget(_app(env.container, const FileReportScreen(fileId: 'chip1')));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('chip 23andMe'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('chip 23andMe'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Chip de consumidor'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Sem chamada (--)'), findsOneWidget);
    expect(find.text('Multialélicos'), findsNothing, reason: 'campos de VCF ficam de fora');

    await tester.pumpWidget(_app(env.container, const FileReportScreen(fileId: 'fa1')));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('FASTA de referência'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('FASTA de referência'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Bases no total'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('20.000'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });
}
