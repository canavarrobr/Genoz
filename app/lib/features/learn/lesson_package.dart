// Pacote de aula do professor (`.genozaula`): um ZIP com
//   aula.json        título, instruções, perguntas, quem é A e quem é B
//   arquivos/<nome>  os VCFs (conferidos por SHA-256 na importação)
//
// Perguntas calculadas (contagens, concordância...) não levam gabarito: a
// resposta é calculada no aparelho do aluno a partir dos próprios arquivos.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import 'content.dart';

const packageSchema = 1;
const packageExtension = 'genozaula';

/// Limite de tamanho do pacote (descompactado), para não travar o aparelho.
const packageMaxBytes = 400 * 1024 * 1024;

class PackageFile {
  const PackageFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

class LessonPackage {
  const LessonPackage({
    required this.title,
    required this.instructions,
    required this.exercises,
    required this.a,
    required this.b,
    required this.files,
  });

  final String title;
  final String instructions;
  final List<Exercise> exercises;
  final DatasetSide a;
  final DatasetSide b;
  final List<PackageFile> files;

  Uint8List encode() {
    final archive = Archive();
    archive.addFile(
      ArchiveFile.string(
        'aula.json',
        const JsonEncoder.withIndent('  ').convert({
          'schema': packageSchema,
          'app': 'genoz',
          'title': title,
          'instructions': instructions,
          'a': a.toJson(),
          'b': b.toJson(),
          'files': [
            for (final f in files)
              {'name': f.name, 'sha256': sha256.convert(f.bytes).toString(), 'bytes': f.bytes.length},
          ],
          'exercises': [for (final e in exercises) e.toJson()],
        }),
      ),
    );
    for (final f in files) {
      archive.addFile(ArchiveFile.bytes('arquivos/${f.name}', f.bytes));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  /// Lê e confere um pacote. Lança [LessonPackageError] com mensagem clara.
  static LessonPackage decode(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw LessonPackageError.notPackage;
    }
    final manifest = archive.findFile('aula.json');
    if (manifest == null) throw LessonPackageError.notPackage;
    final Map<String, dynamic> j;
    try {
      j = jsonDecode(utf8.decode(manifest.content)) as Map<String, dynamic>;
    } catch (_) {
      throw LessonPackageError.notPackage;
    }
    if (j['app'] != 'genoz') throw LessonPackageError.notPackage;
    final schema = j['schema'];
    if (schema is! int || schema > packageSchema) throw LessonPackageError.newerVersion;

    var total = 0;
    final files = <PackageFile>[];
    for (final f in (j['files'] as List? ?? const [])) {
      final m = f as Map<String, dynamic>;
      final name = safeName(m['name'] as String? ?? '');
      final entry = archive.findFile('arquivos/$name');
      if (name.isEmpty || entry == null) throw LessonPackageError.missingFile;
      total += entry.size;
      if (total > packageMaxBytes) throw LessonPackageError.tooLarge;
      final data = entry.content;
      if (sha256.convert(data).toString() != m['sha256']) throw LessonPackageError.corrupted;
      files.add(PackageFile(name, Uint8List.fromList(data)));
    }
    final a = DatasetSide.fromJson(j['a'] as Map<String, dynamic>);
    final b = DatasetSide.fromJson(j['b'] as Map<String, dynamic>);
    if (files.isEmpty || !files.any((f) => f.name == a.file) || !files.any((f) => f.name == b.file)) {
      throw LessonPackageError.missingFile;
    }
    return LessonPackage(
      title: (j['title'] as String? ?? '').trim(),
      instructions: (j['instructions'] as String? ?? '').trim(),
      exercises: [for (final e in (j['exercises'] as List? ?? const [])) Exercise.fromJson(e as Map<String, dynamic>)],
      a: a,
      b: b,
      files: files,
    );
  }
}

/// Só o nome do arquivo (nada de pastas nem `..`).
String safeName(String name) {
  final base = name.split(RegExp(r'[/\\]')).last.trim();
  return base == '.' || base == '..' ? '' : base;
}

enum LessonPackageError implements Exception { notPackage, newerVersion, missingFile, corrupted, tooLarge }

/// Perguntas que o professor pode incluir: todas calculadas a partir do
/// resultado, então valem para qualquer par de arquivos.
final teacherExerciseTemplates = <Exercise>[
  Exercise(
    id: 'p_so_a',
    kind: ExerciseKind.number,
    compute: 'count:only_a',
    prompt: const LText('Quantas variantes aparecem somente em A?', 'How many variants appear only in A?'),
    explain: const LText('Veja a categoria "somente em A" no Resumo.', 'See the "only in A" category in the Summary.'),
  ),
  Exercise(
    id: 'p_so_b',
    kind: ExerciseKind.number,
    compute: 'count:only_b',
    prompt: const LText('Quantas variantes aparecem somente em B?', 'How many variants appear only in B?'),
    explain: const LText('Veja a categoria "somente em B" no Resumo.', 'See the "only in B" category in the Summary.'),
  ),
  Exercise(
    id: 'p_nos_dois',
    kind: ExerciseKind.number,
    compute: 'count:shared+genotype_difference',
    prompt: const LText(
      'Quantas variantes estão nas duas amostras (genótipo igual ou diferente)?',
      'How many variants are in both samples (equal or different genotype)?',
    ),
    explain: const LText('Centro do diagrama de interseções.', 'Center of the intersection diagram.'),
  ),
  Exercise(
    id: 'p_gt_diferente',
    kind: ExerciseKind.number,
    compute: 'count:genotype_difference',
    prompt: const LText(
      'Em quantas variantes as duas amostras têm genótipos diferentes?',
      'In how many variants do the two samples have different genotypes?',
    ),
    explain: const LText('Categoria "genótipo diferente".', '"Different genotype" category.'),
  ),
  Exercise(
    id: 'p_concordancia',
    kind: ExerciseKind.percent,
    compute: 'percent:concordance',
    prompt: const LText(
      'Qual a concordância de genótipos, em %? (uma casa decimal)',
      'What is the genotype concordance, in %? (one decimal place)',
    ),
    explain: const LText('Iguais ÷ (iguais + genótipo diferente).', 'Equal ÷ (equal + different genotype).'),
  ),
  Exercise(
    id: 'p_jaccard',
    kind: ExerciseKind.percent,
    compute: 'percent:jaccard',
    prompt: const LText(
      'Qual o índice de Jaccard, em %? (uma casa decimal)',
      'What is the Jaccard index, in %? (one decimal place)',
    ),
    explain: const LText('Está no Resumo.', 'It is in the Summary.'),
  ),
  Exercise(
    id: 'p_top_a',
    kind: ExerciseKind.text,
    compute: 'top_chrom:only_a',
    prompt: const LText(
      'Em qual cromossomo há mais variantes somente em A?',
      'Which chromosome has the most variants only in A?',
    ),
    explain: const LText('Use o Mapa com a categoria "somente em A".', 'Use the Map with the "only in A" category.'),
  ),
  Exercise(
    id: 'p_top_b',
    kind: ExerciseKind.text,
    compute: 'top_chrom:only_b',
    prompt: const LText(
      'Em qual cromossomo há mais variantes somente em B?',
      'Which chromosome has the most variants only in B?',
    ),
    explain: const LText('Use o Mapa com a categoria "somente em B".', 'Use the Map with the "only in B" category.'),
  ),
];
