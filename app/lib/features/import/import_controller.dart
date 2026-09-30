// Controla a importação de um VCF: cópia + hash + validação no núcleo Rust,
// com progresso e cancelamento. Só grava no banco depois de validar.

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/genoz_core.dart';
import '../../core/inspect_report.dart';
import '../../persistence/analysis_repository.dart';
import '../../persistence/app_storage.dart';
import '../../persistence/project_repository.dart';

sealed class ImportState {
  const ImportState();
}

class ImportIdle extends ImportState {
  const ImportIdle();
}

class ImportRunning extends ImportState {
  const ImportRunning({required this.jobId, required this.fileName, this.progress});
  final String jobId;
  final String fileName;
  final ImportProgress? progress;
}

class ImportSucceeded extends ImportState {
  const ImportSucceeded({required this.fileId, required this.fileName});
  final String fileId;
  final String fileName;
}

/// O arquivo foi lido, mas não é utilizável (ex.: gzip truncado).
class ImportRejected extends ImportState {
  const ImportRejected({required this.fileName, required this.report});
  final String fileName;
  final InspectReport report;
}

class ImportDuplicate extends ImportState {
  const ImportDuplicate({required this.existingName});
  final String existingName;
}

class ImportError extends ImportState {
  const ImportError(this.message);
  final String message;
}

class ImportWasCancelled extends ImportState {
  const ImportWasCancelled();
}

class ImportController extends Notifier<ImportState> {
  StreamSubscription<CoreImportEvent>? _sub;

  @override
  ImportState build() {
    ref.onDispose(() => _sub?.cancel());
    return const ImportIdle();
  }

  bool get isRunning => state is ImportRunning;

  /// Importa um arquivo que só pode ser lido como fluxo de bytes (ex.: `content://`
  /// no Android). Os bytes vão direto para a pasta do projeto; o núcleo então
  /// calcula o hash e valida no próprio lugar.
  Future<void> importStream({
    required String projectId,
    required Stream<List<int>> bytes,
    required String displayName,
    int? totalBytes,
  }) async {
    if (isRunning) return;
    final storage = ref.read(appStorageProvider);
    final fileId = newId();
    final relative = storage.newFileRelative(projectId, fileId, displayName);
    final dest = File(storage.absolute(relative));
    state = ImportRunning(jobId: fileId, fileName: displayName);
    try {
      await dest.parent.create(recursive: true);
      final sink = dest.openWrite();
      var done = 0;
      await for (final chunk in bytes) {
        sink.add(chunk);
        done += chunk.length;
        state = ImportRunning(
          jobId: fileId,
          fileName: displayName,
          progress: ImportProgress(validating: false, bytesDone: done, bytesTotal: totalBytes ?? 0),
        );
      }
      await sink.close();
    } catch (e) {
      if (await dest.exists()) await dest.delete();
      state = ImportError(e.toString());
      return;
    }
    state = const ImportIdle();
    await importFile(
      projectId: projectId,
      sourcePath: dest.path,
      displayName: displayName,
      fileId: fileId,
    );
  }

  /// Importa um arquivo escolhido pelo usuário a partir do caminho.
  Future<void> importFile({
    required String projectId,
    required String sourcePath,
    required String displayName,
    String? fileId,
  }) async {
    if (isRunning) return;
    final storage = ref.read(appStorageProvider);
    final repo = ref.read(projectRepositoryProvider);
    final core = ref.read(genozCoreProvider);

    final id = fileId ?? newId();
    final relative = storage.newFileRelative(projectId, id, displayName);
    state = ImportRunning(jobId: id, fileName: displayName);

    final done = Completer<void>();
    _sub = core
        .importVcf(sourcePath: sourcePath, destPath: storage.absolute(relative), jobId: id)
        .listen((event) async {
      switch (event) {
        case ImportProgress():
          state = ImportRunning(jobId: id, fileName: displayName, progress: event);
        case ImportCancelled():
          state = const ImportWasCancelled();
          done.complete();
        case ImportFailed(:final message):
          state = ImportError(message);
          done.complete();
        case ImportDone(:final reportJson):
          final report = InspectReport.parse(reportJson);
          final existing = await repo.findBySha(projectId, report.sha256);
          if (existing != null) {
            await storage.deleteFile(relative);
            state = ImportDuplicate(existingName: existing.displayName);
          } else if (!report.isUsable) {
            await storage.deleteFile(relative);
            state = ImportRejected(fileName: displayName, report: report);
          } else {
            await repo.addImportedFile(
              projectId: projectId,
              fileId: id,
              displayName: displayName,
              storedPath: relative,
              report: report,
              reportJson: reportJson,
            );
            // O diário guarda só o nome; a tela traduz pelo tipo (`import`).
            await ref.read(analysisRepositoryProvider).log(projectId, 'import', displayName);
            state = ImportSucceeded(fileId: id, fileName: displayName);
          }
          done.complete();
      }
    }, onError: (Object e) {
      state = ImportError(e.toString());
      if (!done.isCompleted) done.complete();
    });
    await done.future;
    await _sub?.cancel();
    _sub = null;
  }

  /// Gera um VCF sintético numa pasta temporária do projeto e o importa.
  Future<void> importSyntheticExample(String projectId) async {
    if (isRunning) return;
    final storage = ref.read(appStorageProvider);
    final core = ref.read(genozCoreProvider);
    final seed = DateTime.now().millisecondsSinceEpoch % 100000;
    final tmpRelative = storage.newFileRelative(projectId, 'tmp_${newId()}', 'x.vcf.gz');
    final name = 'exemplo_sintetico_$seed.vcf.gz';
    state = ImportRunning(jobId: 'synth', fileName: name);
    try {
      await core.writeSyntheticExample(
        destPath: storage.absolute(tmpRelative),
        seed: seed,
        samples: 2,
        variantsPerChrom: 2000,
      );
      state = const ImportIdle();
      await importFile(projectId: projectId, sourcePath: storage.absolute(tmpRelative), displayName: name);
    } catch (e) {
      state = ImportError(e.toString());
    } finally {
      await storage.deleteFile(tmpRelative);
    }
  }

  void cancel() {
    final s = state;
    if (s is ImportRunning) ref.read(genozCoreProvider).cancel(s.jobId);
  }

  /// A tela já mostrou o resultado; volta ao estado inicial.
  void acknowledge() {
    if (!isRunning) state = const ImportIdle();
  }
}

final importControllerProvider = NotifierProvider<ImportController, ImportState>(ImportController.new);
