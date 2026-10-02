// "Verificar reprodutibilidade" (Módulo 11): confere os SHA-256 das entradas, refaz
// a análise numa pasta temporária com os mesmos parâmetros e compara saída por saída
// com o manifesto. A análise original não é tocada.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/compare_models.dart';
import '../../core/genoz_core.dart';
import '../../persistence/app_storage.dart';
import '../../persistence/database.dart';
import '../../persistence/project_repository.dart';
import '../vault/project_vault.dart' show tempDir;

class InputCheck {
  const InputCheck({required this.role, required this.name, required this.ok, this.problem});
  final String role;
  final String name;
  final bool ok;

  /// `ausente` (não está no projeto), `alterado` (SHA-256 diferente), `nao_suportado`.
  final String? problem;
}

class OutputCheck {
  const OutputCheck({required this.name, required this.expected, this.actual});
  final String name;
  final String expected;
  final String? actual;
  bool get matches => actual == expected;
}

class ReproResult {
  const ReproResult({required this.inputs, required this.outputs, this.sameId, this.error});
  final List<InputCheck> inputs;
  final List<OutputCheck> outputs;

  /// O ID da reexecução é o mesmo? `null` se não chegou a reexecutar.
  final bool? sameId;
  final String? error;

  bool get inputsOk => inputs.every((i) => i.ok);
  int get identical => outputs.where((o) => o.matches).length;
  bool get reproduced => inputsOk && error == null && sameId == true && outputs.isNotEmpty && identical == outputs.length;
}

SourceFile storedSource(AppStorage storage, ProjectFile f) {
  final native = storage.blobs.nativePath(f.storedPath);
  return SourceFile(
    name: f.displayName,
    path: native,
    open: native == null ? () => Stream.fromFuture(storage.blobs.readBytes(f.storedPath)) : null,
    size: f.bytes,
  );
}

/// Núcleo comum: confere entradas, reexecuta com `rerun` numa pasta temporária e
/// compara saída por saída. `rerun` devolve o JSON do manifesto novo.
Future<ReproResult> _verify(
  Ref ref, {
  required String projectId,
  required String resultDir,
  required Future<String> Function(Map<String, ProjectFile> byRole, String outDir) rerun,
}) async {
  final storage = ref.read(appStorageProvider);
  final core = ref.read(genozCoreProvider);
  final repo = ref.read(projectRepositoryProvider);
  final manifest = jsonDecode(await storage.blobs.readString('$resultDir/manifest.json')) as Map<String, dynamic>;
  final expected = [
    for (final o in manifest['outputs'] as List)
      (name: (o as Map<String, dynamic>)['name'] as String, sha: o['sha256'] as String),
  ];

  // 1. Entradas: estão no projeto e com o mesmo SHA-256 de quando a análise foi feita?
  final inputs = <InputCheck>[];
  final byRole = <String, ProjectFile>{};
  for (final i in manifest['inputs'] as List) {
    final role = (i as Map<String, dynamic>)['role'] as String;
    final name = i['name'] as String;
    final sha = i['sha256'] as String;
    if (role.startsWith('callable')) {
      inputs.add(InputCheck(role: role, name: name, ok: false, problem: 'nao_suportado'));
      continue;
    }
    final file = await repo.findBySha(projectId, sha);
    if (file == null) {
      inputs.add(InputCheck(role: role, name: name, ok: false, problem: 'ausente'));
      continue;
    }
    final now = await core.sha256Of(storedSource(storage, file));
    final ok = now.toLowerCase() == sha.toLowerCase();
    inputs.add(InputCheck(role: role, name: file.displayName, ok: ok, problem: ok ? null : 'alterado'));
    byRole[role] = file;
  }
  final pending = [for (final e in expected) OutputCheck(name: e.name, expected: e.sha)];
  if (inputs.any((i) => !i.ok)) return ReproResult(inputs: inputs, outputs: pending);

  // 2. Reexecuta numa pasta temporária, com os mesmos parâmetros.
  final out = '$tempDir/reexecucao_${newId()}';
  String? newManifest;
  String? error;
  try {
    newManifest = await rerun(byRole, out);
  } catch (e) {
    error = '$e';
  } finally {
    core.forgetResult(out);
    await storage.blobs.deleteDir(out);
  }
  if (newManifest == null) return ReproResult(inputs: inputs, outputs: pending, error: error ?? 'sem resultado');
  final again = jsonDecode(newManifest) as Map<String, dynamic>;
  final actual = {
    for (final o in again['outputs'] as List) (o as Map<String, dynamic>)['name'] as String: o['sha256'] as String,
  };
  return ReproResult(
    inputs: inputs,
    outputs: [for (final e in expected) OutputCheck(name: e.name, expected: e.sha, actual: actual[e.name])],
    sameId: again['analysis_id'] == manifest['analysis_id'],
  );
}

CompareInputFile _side(ProjectFile f, String? sample) => CompareInputFile(
      relativePath: f.storedPath,
      displayName: f.displayName,
      sha256: f.sha256,
      bytes: f.bytes,
      sample: sample,
    );

Future<ReproResult> verifyReproducibility(Ref ref, Analysis analysis) => _verify(
      ref,
      projectId: analysis.projectId,
      resultDir: analysis.resultDir,
      rerun: (byRole, out) async {
        final a = byRole['a']!;
        final b = byRole['b']!;
        await for (final e in ref.read(genozCoreProvider).compare(
          a: _side(a, analysis.sampleA),
          b: _side(b, analysis.sampleB),
          options: CompareOptions.parse(analysis.optionsJson),
          outDirRelative: out,
          createdAt: DateTime.now().toUtc().toIso8601String(),
          jobId: 'reexecucao_${analysis.id}',
          chip: a.isChip,
          reference: byRole['reference'] == null ? null : _side(byRole['reference']!, null),
        )) {
          switch (e) {
            case CompareDone(:final manifestJson):
              return manifestJson;
            case CompareFailed(:final message):
              throw StateError(message);
            case CompareCancelled():
              throw StateError('cancelada');
            case CompareProgress():
              break;
          }
        }
        throw StateError('sem resultado');
      },
    );

/// Família e populações (Módulo 12): mesmo VCF, mesmas opções.
Future<ReproResult> verifyFamilyReproducibility(Ref ref, FamilyAnalysis analysis) => _verify(
      ref,
      projectId: analysis.projectId,
      resultDir: analysis.resultDir,
      rerun: (byRole, out) async => (await ref.read(genozCoreProvider).analyzeFamily(
            input: _side(byRole['a']!, null),
            optionsJson: analysis.optionsJson,
            outDirRelative: out,
            createdAt: DateTime.now().toUtc().toIso8601String(),
          ))
              .manifest,
    );

final reproducibilityProvider = Provider<Future<ReproResult> Function(Analysis)>(
  (ref) => (a) => verifyReproducibility(ref, a),
);

final familyReproducibilityProvider = Provider<Future<ReproResult> Function(FamilyAnalysis)>(
  (ref) => (a) => verifyFamilyReproducibility(ref, a),
);
