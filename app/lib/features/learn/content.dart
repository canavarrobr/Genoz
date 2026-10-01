// Conteúdo do modo estudante: trilhas, exercícios, glossário e datasets
// didáticos (fictícios), embutidos no app. Aulas importadas de pacotes de
// professor ficam no armazenamento privado (`aprender/aulas/`).

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../persistence/app_storage.dart';

const learnDir = 'aprender';
const lessonsDir = '$learnDir/aulas';
const datasetAssetDir = 'assets/aprender/dados';

/// Texto em português e inglês.
class LText {
  const LText(this.pt, this.en);
  final String pt;
  final String en;

  factory LText.fromJson(Object? j) {
    if (j is String) return LText(j, j);
    final m = (j as Map?) ?? const {};
    final pt = m['pt'] as String? ?? m['en'] as String? ?? '';
    return LText(pt, m['en'] as String? ?? pt);
  }

  Map<String, String> toJson() => {'pt': pt, 'en': en};

  String of(BuildContext context) => Localizations.localeOf(context).languageCode == 'en' ? en : pt;
}

class DatasetSide {
  const DatasetSide(this.file, this.sample);
  final String file;
  final String? sample;

  factory DatasetSide.fromJson(Map<String, dynamic> j) => DatasetSide(j['file'] as String, j['sample'] as String?);
  Map<String, dynamic> toJson() => {'file': file, if (sample != null) 'sample': sample};
}

class Dataset {
  const Dataset({required this.id, required this.title, required this.files, required this.a, required this.b});
  final String id;
  final LText title;
  final List<String> files;
  final DatasetSide a;
  final DatasetSide b;

  factory Dataset.fromJson(String id, Map<String, dynamic> j) => Dataset(
    id: id,
    title: LText.fromJson(j['title']),
    files: (j['files'] as List).cast<String>(),
    a: DatasetSide.fromJson(j['a'] as Map<String, dynamic>),
    b: DatasetSide.fromJson(j['b'] as Map<String, dynamic>),
  );
}

/// Tela da análise que um passo da trilha abre.
enum LessonTab { summary, table, map, qc }

class LessonStep {
  const LessonStep({required this.text, this.terms = const [], this.open});
  final LText text;
  final List<String> terms;
  final LessonTab? open;

  factory LessonStep.fromJson(Map<String, dynamic> j) => LessonStep(
    text: LText.fromJson(j['text']),
    terms: ((j['terms'] as List?) ?? const []).cast<String>(),
    open: LessonTab.values.where((t) => t.name == j['open']).firstOrNull,
  );

  Map<String, dynamic> toJson() => {
    'text': text.toJson(),
    if (terms.isNotEmpty) 'terms': terms,
    if (open != null) 'open': open!.name,
  };
}

enum ExerciseKind { number, percent, text, genotype, choice }

class Exercise {
  const Exercise({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.explain,
    this.compute,
    this.choices = const [],
    this.answer,
  });

  final String id;
  final ExerciseKind kind;
  final LText prompt;
  final LText explain;

  /// Como calcular a resposta a partir do resultado real (ex.: `count:only_a`).
  final String? compute;
  final List<LText> choices;

  /// Índice da alternativa certa (só `choice`).
  final int? answer;

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id: j['id'] as String,
    kind: ExerciseKind.values.byName(j['kind'] as String),
    prompt: LText.fromJson(j['prompt']),
    explain: LText.fromJson(j['explain']),
    compute: j['compute'] as String?,
    choices: [for (final c in (j['choices'] as List?) ?? const []) LText.fromJson(c)],
    answer: j['answer'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'prompt': prompt.toJson(),
    'explain': explain.toJson(),
    if (compute != null) 'compute': compute,
    if (choices.isNotEmpty) 'choices': [for (final c in choices) c.toJson()],
    if (answer != null) 'answer': answer,
  };
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.steps,
    required this.exercises,
    this.dataset,
    this.projectId,
    this.analysisId,
  });

  final String id;
  final LText title;
  final LText summary;
  final List<LessonStep> steps;
  final List<Exercise> exercises;

  /// Dataset embutido (trilhas do app).
  final String? dataset;

  /// Aula importada de um pacote: já vem com projeto e análise prontos.
  final String? projectId;
  final String? analysisId;

  bool get imported => projectId != null;

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
    id: j['id'] as String,
    title: LText.fromJson(j['title']),
    summary: LText.fromJson(j['summary']),
    steps: [for (final s in (j['steps'] as List?) ?? const []) LessonStep.fromJson(s as Map<String, dynamic>)],
    exercises: [for (final e in (j['exercises'] as List?) ?? const []) Exercise.fromJson(e as Map<String, dynamic>)],
    dataset: j['dataset'] as String?,
    projectId: j['project_id'] as String?,
    analysisId: j['analysis_id'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title.toJson(),
    'summary': summary.toJson(),
    'steps': [for (final s in steps) s.toJson()],
    'exercises': [for (final e in exercises) e.toJson()],
    if (dataset != null) 'dataset': dataset,
    if (projectId != null) 'project_id': projectId,
    if (analysisId != null) 'analysis_id': analysisId,
  };
}

class GlossaryTerm {
  const GlossaryTerm(this.id, this.term, this.definition);
  final String id;
  final LText term;
  final LText definition;

  factory GlossaryTerm.fromJson(Map<String, dynamic> j) =>
      GlossaryTerm(j['id'] as String, LText.fromJson(j['term']), LText.fromJson(j['def']));
}

class LearnContent {
  const LearnContent({required this.datasets, required this.lessons, required this.glossary});
  final Map<String, Dataset> datasets;

  /// Trilhas do app primeiro, depois as aulas importadas.
  final List<Lesson> lessons;
  final List<GlossaryTerm> glossary;

  GlossaryTerm? term(String id) => glossary.where((t) => t.id == id).firstOrNull;

  static LearnContent parse(String trilhasJson, String glossaryJson, List<Lesson> imported) {
    final t = jsonDecode(trilhasJson) as Map<String, dynamic>;
    return LearnContent(
      datasets: {
        for (final e in (t['datasets'] as Map<String, dynamic>).entries)
          e.key: Dataset.fromJson(e.key, e.value as Map<String, dynamic>),
      },
      lessons: [for (final l in t['lessons'] as List) Lesson.fromJson(l as Map<String, dynamic>), ...imported],
      glossary: [for (final g in jsonDecode(glossaryJson) as List) GlossaryTerm.fromJson(g as Map<String, dynamic>)],
    );
  }
}

/// Carrega trilhas e glossário embutidos + aulas importadas (sem o cache do rootBundle:
/// os arquivos são pequenos e o conteúdo é relido quando uma aula é importada).
/// Invalidar depois de importar uma aula.
final learnContentProvider = FutureProvider<LearnContent>((ref) async {
  final blobs = ref.read(appStorageProvider).blobs;
  final imported = <Lesson>[];
  final index = '$lessonsDir/indice.json';
  if (await blobs.exists(index)) {
    for (final id in (jsonDecode(await blobs.readString(index)) as List).cast<String>()) {
      final path = '$lessonsDir/$id.json';
      if (await blobs.exists(path)) {
        imported.add(Lesson.fromJson(jsonDecode(await blobs.readString(path)) as Map<String, dynamic>));
      }
    }
  }
  return LearnContent.parse(
    await rootBundle.loadString('assets/aprender/trilhas.json', cache: false),
    await rootBundle.loadString('assets/aprender/glossario.json', cache: false),
    imported,
  );
});
