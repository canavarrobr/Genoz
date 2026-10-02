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

Future<ReproResult> verifyReproducibility(Ref ref, Analysis analysis) async {
  final storage = ref.read(appStorageProvider);
  final core = ref.read(genozCoreProvider);
  final repo = ref.read(projectRepositoryProvider);
  final manifest =
      jsonDecode(await storage.blobs.readString('${analysis.resultDir}/manifest.json')) as Map<String, dynamic>;
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
    final file = await repo.findBySha(analysis.projectId, sha);
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
  CompareInputFile side(ProjectFile f, String? sample) => CompareInputFile(
        relativePath: f.storedPath,
        displayName: f.displayName,
        sha256: f.sha256,
        bytes: f.bytes,
        sample: sample,
      );
  final a = byRole['a']!;
  final b = byRole['b']!;
  String? newManifest;
  String? error;
  try {
    await for (final e in core.compare(
      a: side(a, analysis.sampleA),
      b: side(b, analysis.sampleB),
      options: CompareOptions.parse(analysis.optionsJson),
      outDirRelative: out,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      jobId: 'reexecucao_${analysis.id}',
      chip: a.isChip,
      reference: byRole['reference'] == null ? null : side(byRole['reference']!, null),
    )) {
      switch (e) {
        case CompareDone(:final manifestJson):
          newManifest = manifestJson;
        case CompareFailed(:final message):
          error = message;
        case CompareCancelled():
          error = 'cancelada';
        case CompareProgress():
          break;
      }
    }
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

final reproducibilityProvider = Provider<Future<ReproResult> Function(Analysis)>(
  (ref) => (a) => verifyReproducibility(ref, a),
);
