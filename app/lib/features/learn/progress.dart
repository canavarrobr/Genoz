// Progresso do modo estudante (no aparelho, em `aprender/progresso.json`):
// qual projeto/análise cada trilha usa e quais exercícios já foram acertados.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/compare_models.dart';
import '../../core/genoz_core.dart';
import '../../persistence/analysis_repository.dart';
import '../../persistence/app_storage.dart';
import '../../persistence/project_repository.dart';
import '../compare/compare_controller.dart';
import '../import/import_controller.dart';
import 'content.dart';
import 'lesson_package.dart';

const progressFile = '$learnDir/progresso.json';

class LessonRun {
  const LessonRun(this.projectId, this.analysisId);
  final String projectId;
  final String analysisId;
}

class LearnProgress {
  const LearnProgress({this.runs = const {}, this.answers = const {}});

  /// Trilha → projeto e análise abertos para ela.
  final Map<String, LessonRun> runs;

  /// Trilha → exercício → acertou?
  final Map<String, Map<String, bool>> answers;

  int correct(String lessonId) => (answers[lessonId] ?? const {}).values.where((v) => v).length;

  factory LearnProgress.fromJson(Map<String, dynamic> j) => LearnProgress(
    runs: {
      for (final e in ((j['runs'] as Map?) ?? const {}).entries)
        e.key as String: LessonRun(e.value['project_id'] as String, e.value['analysis_id'] as String),
    },
    answers: {
      for (final e in ((j['answers'] as Map?) ?? const {}).entries)
        e.key as String: (e.value as Map).map((k, v) => MapEntry(k as String, v as bool)),
    },
  );

  Map<String, dynamic> toJson() => {
    'schema': 1,
    'runs': {
      for (final e in runs.entries) e.key: {'project_id': e.value.projectId, 'analysis_id': e.value.analysisId},
    },
    'answers': answers,
  };
}

class LearnProgressController extends AsyncNotifier<LearnProgress> {
  @override
  Future<LearnProgress> build() async {
    final blobs = ref.read(appStorageProvider).blobs;
    try {
      if (!await blobs.exists(progressFile)) return const LearnProgress();
      return LearnProgress.fromJson(jsonDecode(await blobs.readString(progressFile)) as Map<String, dynamic>);
    } catch (_) {
      return const LearnProgress();
    }
  }

  Future<void> _save(LearnProgress next) async {
    state = AsyncData(next);
    await ref
        .read(appStorageProvider)
        .blobs
        .writeBytes(progressFile, Uint8List.fromList(utf8.encode(jsonEncode(next.toJson()))));
  }

  Future<void> setRun(String lessonId, LessonRun run) async {
    final p = await future;
    await _save(LearnProgress(runs: {...p.runs, lessonId: run}, answers: p.answers));
  }

  Future<void> setAnswer(String lessonId, String exerciseId, bool correct) async {
    final p = await future;
    // Um acerto não vira erro se a pessoa responder de novo errado só para testar.
    final prev = p.answers[lessonId]?[exerciseId] ?? false;
    await _save(
      LearnProgress(
        runs: p.runs,
        answers: {
          ...p.answers,
          lessonId: {...?p.answers[lessonId], exerciseId: prev || correct},
        },
      ),
    );
  }
}

final learnProgressProvider = AsyncNotifierProvider<LearnProgressController, LearnProgress>(
  LearnProgressController.new,
);

class LessonOpenError implements Exception {
  LessonOpenError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Garante que a trilha tem projeto + análise prontos e devolve o ID da análise.
/// Na primeira vez: cria o projeto, importa os arquivos fictícios embutidos e compara.
Future<String> openLesson(
  WidgetRef ref,
  Lesson lesson,
  LearnContent content, {
  required String projectName,
  required String projectDescription,
  required String Function(String a, String b, String id) journalMessage,
}) async {
  if (lesson.analysisId != null) return lesson.analysisId!;
  final progress = await ref.read(learnProgressProvider.future);
  final existing = progress.runs[lesson.id];
  if (existing != null && await ref.read(analysisProvider(existing.analysisId).future) != null) {
    return existing.analysisId;
  }
  final dataset = content.datasets[lesson.dataset] ?? (throw LessonOpenError('dataset ${lesson.dataset}?'));
  final project = await ref.read(projectRepositoryProvider).createProject(projectName, description: projectDescription);
  final files = {
    for (final name in dataset.files) name: (await rootBundle.load('$datasetAssetDir/$name')).buffer.asUint8List(),
  };
  final analysisId = await importAndCompare(ref, project.id, files, dataset.a, dataset.b, journalMessage);
  await ref.read(learnProgressProvider.notifier).setRun(lesson.id, LessonRun(project.id, analysisId));
  return analysisId;
}

/// Importa os arquivos (bytes) para o projeto e compara A × B. Devolve o ID da análise.
Future<String> importAndCompare(
  WidgetRef ref,
  String projectId,
  Map<String, Uint8List> files,
  DatasetSide a,
  DatasetSide b,
  String Function(String a, String b, String id) journalMessage,
) async {
  final repo = ref.read(projectRepositoryProvider);
  final importer = ref.read(importControllerProvider.notifier);
  final ids = <String, String>{}; // nome → fileId
  for (final e in files.entries) {
    final bytes = e.value;
    await importer.importFile(
      projectId: projectId,
      source: SourceFile(name: e.key, open: () => Stream.value(bytes), size: bytes.length),
    );
    final st = ref.read(importControllerProvider);
    importer.acknowledge();
    if (st is! ImportSucceeded) throw LessonOpenError(st is ImportError ? st.message : '${e.key}: ${st.runtimeType}');
    ids[e.key] = st.fileId;
  }
  Future<CompareChoice> side(DatasetSide s) async => (file: (await repo.getFile(ids[s.file]!))!, sample: s.sample);
  final compare = ref.read(compareControllerProvider.notifier);
  await compare.run(
    projectId: projectId,
    a: await side(a),
    b: await side(b),
    options: const CompareOptions(),
    journalMessage: journalMessage,
  );
  final st = ref.read(compareControllerProvider);
  compare.acknowledge();
  if (st is! CompareSucceeded) throw LessonOpenError(st is CompareError ? st.message : '${st.runtimeType}');
  return st.analysisId;
}

/// Importa um pacote de aula: projeto + arquivos + comparação + aula na lista.
Future<Lesson> importLessonPackage(
  WidgetRef ref,
  LessonPackage pkg, {
  required String projectDescription,
  required LText openStepText,
  required String Function(String a, String b, String id) journalMessage,
}) async {
  final project = await ref
      .read(projectRepositoryProvider)
      .createProject(pkg.title.isEmpty ? 'Aula' : pkg.title, description: projectDescription);
  final analysisId = await importAndCompare(
    ref,
    project.id,
    {for (final f in pkg.files) f.name: f.bytes},
    pkg.a,
    pkg.b,
    journalMessage,
  );
  final lesson = Lesson(
    id: newId(),
    title: LText(pkg.title, pkg.title),
    summary: LText(pkg.instructions, pkg.instructions),
    // Sempre há um passo com o botão para abrir a comparação (de onde saem as respostas).
    steps: [
      LessonStep(
        text: pkg.instructions.isEmpty ? openStepText : LText(pkg.instructions, pkg.instructions),
        open: LessonTab.summary,
      ),
    ],
    exercises: pkg.exercises,
    projectId: project.id,
    analysisId: analysisId,
  );
  final blobs = ref.read(appStorageProvider).blobs;
  await blobs.writeBytes('$lessonsDir/${lesson.id}.json', Uint8List.fromList(utf8.encode(jsonEncode(lesson.toJson()))));
  final index = '$lessonsDir/indice.json';
  final ids = await blobs.exists(index)
      ? (jsonDecode(await blobs.readString(index)) as List).cast<String>()
      : <String>[];
  await blobs.writeBytes(index, Uint8List.fromList(utf8.encode(jsonEncode([...ids, lesson.id]))));
  ref.invalidate(learnContentProvider);
  return lesson;
}
