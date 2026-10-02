// Executa uma comparação A × B no núcleo Rust, com progresso e cancelamento,
// e registra a análise no banco e no diário do projeto.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/compare_models.dart';
import '../../core/genoz_core.dart';
import '../../persistence/analysis_repository.dart';
import '../../persistence/app_storage.dart';
import '../../platform/network_audit.dart';
import '../../persistence/database.dart';
import '../../persistence/project_repository.dart';

sealed class CompareState {
  const CompareState();
}

class CompareIdle extends CompareState {
  const CompareIdle();
}

class CompareRunning extends CompareState {
  const CompareRunning(this.jobId, [this.fraction]);
  final String jobId;
  final double? fraction;
}

class CompareSucceeded extends CompareState {
  const CompareSucceeded(this.analysisId);
  final String analysisId;
}

class CompareError extends CompareState {
  const CompareError(this.message);
  final String message;
}

class CompareWasCancelled extends CompareState {
  const CompareWasCancelled();
}

/// Um lado escolhido na tela: arquivo importado + amostra (null = primeira).
typedef CompareChoice = ({ProjectFile file, String? sample});

class CompareController extends Notifier<CompareState> {
  StreamSubscription<CoreCompareEvent>? _sub;

  @override
  CompareState build() {
    ref.onDispose(() => _sub?.cancel());
    return const CompareIdle();
  }

  bool get isRunning => state is CompareRunning;

  Future<void> run({
    required String projectId,
    required CompareChoice a,
    required CompareChoice b,
    required CompareOptions options,
    required String Function(String a, String b, String id) journalMessage,
    ProjectFile? reference,
  }) async {
    if (isRunning) return;
    final storage = ref.read(appStorageProvider);
    final core = ref.read(genozCoreProvider);
    final repo = ref.read(analysisRepositoryProvider);

    final analysisId = newId();
    final resultDir = storage.analysisRelative(projectId, analysisId);
    state = CompareRunning(analysisId);
    CompareInputFile side(CompareChoice c) => CompareInputFile(
          relativePath: c.file.storedPath,
          displayName: c.file.displayName,
          sha256: c.file.sha256,
          bytes: c.file.bytes,
          sample: c.sample,
        );

    NetworkAudit.instance.beginAnalysis();
    final done = Completer<void>();
    _sub = core
        .compare(
          a: side(a),
          b: side(b),
          options: options,
          outDirRelative: resultDir,
          createdAt: DateTime.now().toUtc().toIso8601String(),
          jobId: analysisId,
          // A é chip: comparação restrita aos sítios do chip.
          chip: a.file.isChip,
          reference: reference == null ? null : side((file: reference, sample: null)),
        )
        .listen((event) async {
      switch (event) {
        case CompareProgress(:final fraction):
          state = CompareRunning(analysisId, fraction);
        case CompareCancelled():
          state = const CompareWasCancelled();
          done.complete();
        case CompareFailed(:final message):
          state = CompareError(message);
          done.complete();
        case CompareDone(:final summaryJson, :final manifestJson):
          final saved = await repo.addAnalysis(
            id: analysisId,
            projectId: projectId,
            fileAId: a.file.id,
            fileBId: b.file.id,
            sampleA: a.sample,
            sampleB: b.sample,
            optionsJson: options.toJsonString(),
            resultDir: resultDir,
            summaryJson: summaryJson,
            manifestJson: manifestJson,
          );
          final s = saved.summary;
          await repo.log(
            projectId,
            'compare',
            journalMessage(s.a.sample ?? a.file.displayName, s.b.sample ?? b.file.displayName, saved.contentId.substring(0, 8)),
          );
          state = CompareSucceeded(analysisId);
          done.complete();
      }
    }, onError: (Object e) {
      state = CompareError(e.toString());
      if (!done.isCompleted) done.complete();
    });
    await done.future;
    NetworkAudit.instance.endAnalysis();
    await _sub?.cancel();
    _sub = null;
  }

  void cancel() {
    final s = state;
    if (s is CompareRunning) ref.read(genozCoreProvider).cancel(s.jobId);
  }

  void acknowledge() {
    if (!isRunning) state = const CompareIdle();
  }
}

final compareControllerProvider = NotifierProvider<CompareController, CompareState>(CompareController.new);
