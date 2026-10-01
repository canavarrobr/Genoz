import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/core/compare_models.dart';
import 'package:genoz/features/compare/compare_controller.dart';
import 'package:genoz/features/learn/content.dart';
import 'package:genoz/features/learn/glossary_screen.dart';
import 'package:genoz/features/learn/grading.dart';
import 'package:genoz/features/learn/learn_screen.dart';
import 'package:genoz/features/learn/lesson_package.dart';
import 'package:genoz/features/learn/lesson_screen.dart';
import 'package:genoz/features/learn/progress.dart';
import 'package:genoz/l10n/generated/app_localizations.dart';
import 'package:genoz/persistence/analysis_repository.dart';
import 'package:genoz/persistence/database.dart';
import 'package:genoz/ui/theme.dart';

import 'support.dart';

LearnContent _content() => LearnContent.parse(
  File('assets/aprender/trilhas.json').readAsStringSync(),
  File('assets/aprender/glossario.json').readAsStringSync(),
  const [],
);

Future<Analysis> _analysis(TestEnv env) async {
  final (pid, a, b) = await projectWithTwoFiles(env);
  await env.container
      .read(compareControllerProvider.notifier)
      .run(
        projectId: pid,
        a: (file: a, sample: null),
        b: (file: b, sample: null),
        options: const CompareOptions(),
        journalMessage: (x, y, id) => '',
      );
  final id = (env.container.read(compareControllerProvider) as CompareSucceeded).analysisId;
  final analysis = await env.container.read(analysisProvider(id).future);
  return analysis!;
}

Exercise _ex(String compute, ExerciseKind kind) =>
    Exercise(id: compute, kind: kind, compute: compute, prompt: const LText('', ''), explain: const LText('', ''));

Widget _material(ProviderContainer c, Widget home) => UncontrolledProviderScope(
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
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    if (i > 3 &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty &&
        find.byType(LinearProgressIndicator).evaluate().isEmpty) {
      break;
    }
  }
  await tester.pumpAndSettle();
}

void main() {
  group('conteúdo embutido', () {
    test('trilhas, datasets e glossário são consistentes', () {
      final c = _content();
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(c.lessons.length, greaterThanOrEqualTo(3));
      for (final d in c.datasets.values) {
        for (final f in d.files) {
          expect(File('$datasetAssetDir/$f').existsSync(), isTrue, reason: f);
          expect(pubspec, contains('$datasetAssetDir/$f'), reason: 'asset declarado: $f');
        }
        expect(d.files, contains(d.a.file));
        expect(d.files, contains(d.b.file));
      }
      final ids = <String>{};
      for (final lesson in c.lessons) {
        expect(c.datasets, contains(lesson.dataset), reason: lesson.id);
        expect(lesson.title.pt, isNotEmpty);
        expect(lesson.title.en, isNotEmpty);
        for (final s in lesson.steps) {
          for (final t in s.terms) {
            expect(c.term(t), isNotNull, reason: 'termo $t em ${lesson.id}');
          }
        }
        for (final e in lesson.exercises) {
          expect(ids.add('${lesson.id}/${e.id}'), isTrue, reason: 'id repetido ${e.id}');
          expect(e.prompt.en, isNotEmpty, reason: e.id);
          if (e.kind == ExerciseKind.choice) {
            expect(e.answer, inInclusiveRange(0, e.choices.length - 1), reason: e.id);
          } else {
            expect(e.compute, matches(RegExp(r'^(count|percent|top_chrom|gt):')), reason: e.id);
          }
        }
      }
      for (final g in c.glossary) {
        expect(g.term.pt.isNotEmpty && g.term.en.isNotEmpty, isTrue, reason: g.id);
        expect(g.definition.pt.isNotEmpty && g.definition.en.isNotEmpty, isTrue, reason: g.id);
      }
    });

    test('dataset sintético: válido, gerado pelo núcleo e com as duas amostras', () {
      final gz = File('$datasetAssetDir/sintetico_aula.vcf.gz').readAsBytesSync();
      final text = utf8.decode(GZipDecoder().decodeBytes(gz));
      expect(text, contains('#CHROM'));
      expect(text, contains('SINT_1'));
      expect(text, contains('SINT_2'));
      for (var c = 1; c <= 22; c++) {
        expect(text, contains('\nchr$c\t'), reason: 'cromossomo $c');
      }
    });
  });

  group('correção automática (pessoa_a × pessoa_b)', () {
    late TestEnv env;
    tearDown(() => env.dispose());

    test('respostas calculadas do resultado', () async {
      env = await TestEnv.create();
      final a = await _analysis(env);
      Future<ExpectedAnswer> exp(String compute, ExerciseKind kind) async =>
          (await expectedAnswer(_ex(compute, kind), a, env.core))!;

      expect((await exp('count:only_a', ExerciseKind.number)).display, '4');
      final both = await exp('count:shared+genotype_difference', ExerciseKind.number);
      expect(both.accepts('6'), isTrue);
      expect(both.accepts('5'), isFalse);
      final conc = await exp('percent:concordance', ExerciseKind.percent);
      expect(conc.accepts('83,3'), isTrue);
      expect(conc.accepts('83.3%'), isTrue);
      expect(conc.accepts('83'), isFalse);
      final top = await exp('top_chrom:only_a', ExerciseKind.text);
      expect(top.accepts('chr1'), isTrue);
      expect(top.accepts('2'), isFalse);
      final gt = await exp('gt:b:1:2000', ExerciseKind.genotype);
      expect(gt.display, '1/1');
      expect(gt.accepts('1|1'), isTrue);
      expect(gt.accepts('0/1'), isFalse);
      // 1:11000: A 1/0 e B 0|1 — o mesmo genótipo.
      expect((await exp('gt:a:1:11000', ExerciseKind.genotype)).accepts('0|1'), isTrue);
      final choice = Exercise(
        id: 'c',
        kind: ExerciseKind.choice,
        prompt: const LText('', ''),
        explain: const LText('', ''),
        choices: const [LText('x', 'x'), LText('y', 'y')],
        answer: 1,
      );
      final ce = (await expectedAnswer(choice, a, env.core))!;
      expect(ce.accepts('1'), isTrue);
      expect(ce.accepts('0'), isFalse);
    });
  });

  test('normalizações', () {
    expect(normalizeGenotype('1|0'), '0/1');
    expect(normalizeGenotype(' 1 / 1 '), '1/1');
    expect(normalizeGenotype('./.'), './.');
    expect(normalizeChrom('chrx'), 'X');
    expect(normalizeChrom('chrM'), 'MT');
    expect(parseCount('1.234'), 1234);
    expect(parsePercent(' 12,5 % '), 12.5);
  });

  group('pacote de aula', () {
    LessonPackage pkg() => LessonPackage(
      title: 'Aula 1',
      instructions: 'Compare A e B.',
      exercises: [teacherExerciseTemplates.first],
      a: const DatasetSide('a.vcf', null),
      b: const DatasetSide('b.vcf', 'S2'),
      files: [
        PackageFile('a.vcf', Uint8List.fromList(utf8.encode('##fileformat=VCFv4.3\nA\n'))),
        PackageFile('b.vcf', Uint8List.fromList(utf8.encode('##fileformat=VCFv4.3\nB\n'))),
      ],
    );

    test('ida e volta preserva tudo', () {
      final back = LessonPackage.decode(pkg().encode());
      expect(back.title, 'Aula 1');
      expect(back.instructions, 'Compare A e B.');
      expect(back.b.sample, 'S2');
      expect(back.files.map((f) => f.name), ['a.vcf', 'b.vcf']);
      expect(utf8.decode(back.files[1].bytes), contains('B'));
      expect(back.exercises.single.compute, 'count:only_a');
    });

    /// Reescreve o aula.json de um pacote válido (os arquivos continuam os mesmos).
    Uint8List withManifest(Map<String, dynamic> Function(Map<String, dynamic>) edit) {
      final original = ZipDecoder().decodeBytes(pkg().encode());
      final m = jsonDecode(utf8.decode(original.findFile('aula.json')!.content)) as Map<String, dynamic>;
      final rebuilt = Archive();
      for (final f in original.files) {
        rebuilt.addFile(
          f.name == 'aula.json' ? ArchiveFile.string('aula.json', jsonEncode(edit(m))) : ArchiveFile.bytes(f.name, f.content),
        );
      }
      return ZipEncoder().encodeBytes(rebuilt);
    }

    test('erros claros: não é pacote, versão nova, arquivo faltando, arquivo alterado', () {
      Matcher fails(LessonPackageError e) => throwsA(e);
      expect(() => LessonPackage.decode(Uint8List.fromList([1, 2, 3])), fails(LessonPackageError.notPackage));
      expect(() => LessonPackage.decode(withManifest((m) => m..['schema'] = 99)), fails(LessonPackageError.newerVersion));
      expect(
        () => LessonPackage.decode(
          withManifest((m) => m..['files'] = [(m['files'] as List).first..['sha256'] = '00', (m['files'] as List).last]),
        ),
        fails(LessonPackageError.corrupted),
      );
      expect(
        () => LessonPackage.decode(withManifest((m) => m..['files'] = [(m['files'] as List).first])),
        fails(LessonPackageError.missingFile),
        reason: 'B aponta para um arquivo que não está no pacote',
      );
    });

    test('nomes de arquivo não escapam da pasta', () {
      expect(safeName('../../etc/x.vcf'), 'x.vcf');
      expect(safeName(r'..\..\x.vcf'), 'x.vcf');
      expect(safeName('..'), '');
    });
  });

  testWidgets('trilha: preparar os dados com os arquivos embutidos e acertar um exercício', (tester) async {
    final env = (await tester.runAsync(TestEnv.create))!;
    // O núcleo falso devolve o resultado real de pessoa_a × pessoa_b.
    await tester.pumpWidget(_material(env.container, const LearnScreen()));
    await settle(tester);
    expect(find.text('Primeiros passos: comparar duas pessoas'), findsOneWidget);
    expect(find.text('Glossário'), findsOneWidget);

    await tester.tap(find.text('Primeiros passos: comparar duas pessoas'));
    await settle(tester);
    expect(find.byType(LessonScreen), findsOneWidget);

    final lessonList = find.descendant(of: find.byType(LessonScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Preparar os dados da aula'), 300, scrollable: lessonList);
    await tester.ensureVisible(find.text('Preparar os dados da aula'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preparar os dados da aula'));
    // Importa os dois arquivos embutidos e compara (E/S real): espera a trilha ganhar sua análise.
    for (var i = 0; i < 100 && find.text('Preparar os dados da aula').evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    }
    await settle(tester);

    final progress = (await tester.runAsync(() => env.container.read(learnProgressProvider.future)))!;
    final run = progress.runs['primeiros_passos']!;
    final files = (await tester.runAsync(() => env.repo.watchFiles(run.projectId).first))!;
    expect(files.map((f) => f.displayName).toSet(), {'pessoa_a.vcf', 'pessoa_b.vcf'});

    final card = find.byKey(const ValueKey('primeiros_passos/pp_so_a'));
    await tester.scrollUntilVisible(card, 300, scrollable: lessonList);
    await tester.ensureVisible(find.descendant(of: card, matching: find.text('Conferir')));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: card, matching: find.byType(TextField)), '4');
    await tester.tap(find.descendant(of: card, matching: find.text('Conferir')));
    await settle(tester);
    expect(find.descendant(of: card, matching: find.text('Certo!')), findsOneWidget);
    final after = (await tester.runAsync(() => env.container.read(learnProgressProvider.future)))!;
    expect(after.answers['primeiros_passos']?['pp_so_a'], isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });

  testWidgets('telas do modo estudante cabem em tela pequena (320×568) com fonte 130%', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final env = (await tester.runAsync(TestEnv.create))!;
    for (final screen in <Widget>[
      const LearnScreen(),
      const LessonScreen(lessonId: 'primeiros_passos'),
      const LessonScreen(lessonId: 'genoma_no_mapa'),
      const GlossaryScreen(),
    ]) {
      await tester.pumpWidget(_material(env.container, screen));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: '$screen');
    }
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });
}
