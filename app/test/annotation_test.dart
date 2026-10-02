import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/core/annotation_models.dart';
import 'package:genoz/core/compare_models.dart';
import 'package:genoz/core/genoz_core.dart';
import 'package:genoz/features/analysis/analysis_screen.dart';
import 'package:genoz/features/annotation/annotation_store.dart';
import 'package:genoz/features/annotation/annotations_screen.dart';
import 'package:genoz/features/annotation/sources_section.dart';
import 'package:genoz/features/compare/compare_controller.dart';
import 'package:genoz/l10n/generated/app_localizations.dart';
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

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  }
  await tester.pumpAndSettle();
}

const _clinvarManifest = {
  'id': 'clinvar_teste',
  'name': 'ClinVar teste',
  'kind': 'sites',
  'build': 'GRCh38',
  'source': 'ClinVar (NCBI)',
  'version': '20260905',
  'date': '2026-09-05',
  'license': 'livre com atribuição',
  'disclaimer': 'Não é para uso diagnóstico direto.',
  'fields': [
    {'key': 'CLNSIG', 'label_pt': 'Significado clínico (segundo o ClinVar)', 'label_en': 'x'},
    {'key': 'CLNDN', 'label_pt': 'Condição', 'label_en': 'x'},
  ],
  'records': 2,
};

AnnotRecord _rec(String name, List<String> fields, {String ref = '', String alt = ''}) =>
    AnnotRecord(chrom: '1', start: 1000, end: 1000, reference: ref, alt: alt, name: name, fields: fields);

void main() {
  test('manifesto e linha da tabela', () {
    final m = PackageManifest.fromJson(_clinvarManifest);
    expect((m.isSites, m.fields.first.key, m.records), (true, 'CLNSIG', 2));
    final genes = PackageManifest.fromJson({..._clinvarManifest, 'id': 'g', 'kind': 'intervals', 'source': 'GENCODE'});
    final line = annotationLine(
      [
        AnnotHit('g', [_rec('BRCA2', const []), _rec('ZAR1L', const [])]),
        AnnotHit('clinvar_teste', [_rec('38010', const ['Pathogenic', 'Familial_cancer|not_provided'])]),
      ],
      {'g': genes, 'clinvar_teste': m},
    );
    expect(line, 'BRCA2, ZAR1L · ClinVar: Pathogenic');
    expect(sourceText('Familial_cancer|not_provided'), 'Familial cancer; not provided');
  });

  test('build da análise para escolher pacotes', () {
    final s = CompareSummary.parse(fixture('compare_summary.json'));
    expect(analysisBuild(s), 'GRCh38');
  });

  group('instalação pelo catálogo', () {
    late TestEnv env;
    tearDown(() => env.dispose());

    test('SHA-256 diferente: recusado e nada instalado; igual: instalado; remover', () async {
      env = await TestEnv.create();
      final c = env.container;
      final entry = (await c.read(annotationCatalogProvider.future)).first;
      expect(entry.url, startsWith('https://ftp.ncbi.nlm.nih.gov/'));
      expect(entry.sha256, hasLength(64));
      final file = SourceFile(name: 'clinvar.vcf.gz', path: await env.sourceFile('clinvar.vcf.gz'));
      final actions = c.read(annotationActionsProvider);

      env.core.sha256Result = '0' * 64;
      await expectLater(actions.fromCatalog(entry, file), throwsA(isA<AnnotationInstallError>()));
      expect((await c.read(installedPackagesProvider.future)).where((p) => p.manifest.id == entry.id), isEmpty);
      expect(await env.storage.blobs.exists('anotacao/${entry.id}/manifest.json'), isFalse);

      env.core.sha256Result = entry.sha256;
      final m = await actions.fromCatalog(entry, file);
      expect(m.id, entry.id);
      final installed = await c.read(installedPackagesProvider.future);
      final p = installed.firstWhere((p) => p.manifest.id == entry.id);
      expect((p.embedded, p.manifest.build), (false, entry.build));

      await actions.remove(p);
      expect((await c.read(installedPackagesProvider.future)).where((p) => p.manifest.id == entry.id), isEmpty);
      expect(env.core.forgotten, contains(p.dir));
    });

    test('pacote próprio (BED/TSV)', () async {
      env = await TestEnv.create();
      final file = SourceFile(name: 'aula.tsv', path: await env.sourceFile('aula.tsv', 'chrom\tstart\tend\tnome\n1\t1\t2\tX\n'));
      final m = await env.container.read(annotationActionsProvider).custom(file, name: 'Genes da aula', build: 'GRCh37');
      expect((m.name, m.build, m.kind), ('Genes da aula', 'GRCh37', 'intervals'));
    });
  });

  testWidgets('tabela mostra gene e o que o ClinVar diz; ficha atribui à fonte; busca por gene', (tester) async {
    final env = (await tester.runAsync(TestEnv.create))!;
    final (pid, a, b) = (await tester.runAsync(() => projectWithTwoFiles(env)))!;
    // Pacote "instalado" (manifesto real) + respostas do núcleo falso.
    await tester.runAsync(() async {
      final file = SourceFile(name: 'x', path: await env.sourceFile('x'));
      await env.container.read(annotationActionsProvider).custom(file, name: 'ignorado', build: 'GRCh38');
    });
    final pkgs = (await tester.runAsync(() => env.container.read(installedPackagesProvider.future)))!;
    final custom = pkgs.firstWhere((p) => !p.embedded);
    await tester.runAsync(() => env.storage.blobs.writeBytes(
          '${custom.dir}/manifest.json',
          Uint8List.fromList(utf8.encode(jsonEncode({..._clinvarManifest, 'id': custom.manifest.id}))),
        ));
    env.container.invalidate(installedPackagesProvider);
    env.core.annotations[custom.dir] = (rows) => [
      for (final r in rows)
        r.pos == 1000
            ? [AnnotHit(custom.manifest.id, [_rec('38010', const ['Pathogenic', 'Familial_cancer'], ref: 'A', alt: 'G')])]
            : <AnnotHit>[],
    ];
    // Um pacote de intervalos (genes) para a busca por nome.
    await tester.runAsync(() async {
      final file = SourceFile(name: 'genes.bed', path: await env.sourceFile('genes.bed'));
      await env.container.read(annotationActionsProvider).custom(file, name: 'Genes', build: 'GRCh38');
    });
    final genes = (await tester.runAsync(() => env.container.read(installedPackagesProvider.future)))!
        .firstWhere((p) => !p.embedded && p.dir != custom.dir);
    env.core.names['${genes.dir}/BRCA2'] = [
      const AnnotRecord(chrom: '1', start: 1500, end: 2500, reference: '', alt: '', name: 'BRCA2', fields: []),
    ];
    await tester.runAsync(() => env.container.read(compareControllerProvider.notifier).run(
          projectId: pid,
          a: (file: a, sample: null),
          b: (file: b, sample: null),
          options: const CompareOptions(),
          journalMessage: (x, y, id) => '',
        ));
    final id = (env.container.read(compareControllerProvider) as CompareSucceeded).analysisId;
    await tester.pumpWidget(_app(env.container, AnalysisScreen(analysisId: id, initialTab: 1)));
    await settle(tester);
    expect(find.text('ClinVar: Pathogenic'), findsOneWidget);

    await tester.tap(find.text('1:1000  A > G'));
    await settle(tester);
    expect(find.text('O que as fontes dizem'), findsOneWidget);
    expect(find.text('ClinVar (NCBI) · versão 20260905 (2026-09-05)'), findsOneWidget);
    expect(find.text('Significado clínico (segundo o ClinVar): Pathogenic'), findsOneWidget);
    expect(find.textContaining('O Genoz não classifica variantes'), findsOneWidget);
    Navigator.of(tester.element(find.text('O que as fontes dizem'))).pop();
    await settle(tester);

    // Busca pelo nome do gene: vira a região do gene.
    await tester.enterText(find.byType(TextField).first, 'brca2');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(find.textContaining('BRCA2: 1:1'), findsOneWidget);
    expect(find.text('1:2000  C > T'), findsOneWidget);
    expect(find.text('1:1000  A > G'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });

  testWidgets('tela de anotações: catálogo com link, licença e SHA-256; sem internet no app', (tester) async {
    final env = (await tester.runAsync(TestEnv.create))!;
    // Os genes embutidos são copiados de verdade (E/S real): fora do relógio falso.
    final pkgs = (await tester.runAsync(() => env.container.read(installedPackagesProvider.future)))!;
    expect([for (final p in pkgs) p.manifest.id], ['gencode_v50_grch38', 'gencode_v50_grch37']);
    await tester.pumpWidget(_app(env.container, const AnnotationsScreen()));
    await settle(tester);
    expect(find.textContaining('não tem acesso à internet'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ClinVar 2026-09-05 (GRCh38)'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Baixar no navegador'), findsWidgets);
    expect(find.text('Importar arquivo baixado'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });
}
