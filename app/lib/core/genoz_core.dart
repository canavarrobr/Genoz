// Interface do núcleo científico, vista pelo app.
//
// O app depende desta interface, e não diretamente da ponte Rust, para que
// os testes possam usar um núcleo falso (`FakeGenozCore`) sem compilar Rust.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../src/rust/api/genoz.dart' as rust;

sealed class CoreImportEvent {
  const CoreImportEvent();
}

class ImportProgress extends CoreImportEvent {
  const ImportProgress({
    required this.validating,
    required this.bytesDone,
    required this.bytesTotal,
  });

  /// `false` = copiando e calculando o hash; `true` = validando o VCF.
  final bool validating;
  final int bytesDone;
  final int bytesTotal;

  double get fraction => bytesTotal == 0 ? 0 : (bytesDone / bytesTotal).clamp(0, 1);
}

class ImportDone extends CoreImportEvent {
  const ImportDone(this.reportJson);
  final String reportJson;
}

class ImportFailed extends CoreImportEvent {
  const ImportFailed(this.message);
  final String message;
}

class ImportCancelled extends CoreImportEvent {
  const ImportCancelled();
}

abstract interface class GenozCore {
  String get coreVersion;

  /// Copia `sourcePath` para `destPath`, calcula o SHA-256 e valida.
  Stream<CoreImportEvent> importVcf({
    required String sourcePath,
    required String destPath,
    required String jobId,
  });

  void cancel(String jobId);

  Future<void> writeSyntheticExample({
    required String destPath,
    required int seed,
    required int samples,
    required int variantsPerChrom,
  });
}

/// Implementação real: chama o `genoz_core` (Rust) pela ponte gerada.
class RustGenozCore implements GenozCore {
  const RustGenozCore();

  @override
  String get coreVersion => rust.coreVersion();

  @override
  Stream<CoreImportEvent> importVcf({
    required String sourcePath,
    required String destPath,
    required String jobId,
  }) =>
      rust
          .importVcf(sourcePath: sourcePath, destPath: destPath, jobId: jobId)
          .map((e) => switch (e) {
                rust.ImportEvent_Progress(:final phase, :final bytesDone, :final bytesTotal) =>
                  ImportProgress(
                    validating: phase == rust.ImportPhase.validating,
                    bytesDone: bytesDone.toInt(),
                    bytesTotal: bytesTotal.toInt(),
                  ),
                rust.ImportEvent_Done(:final reportJson) => ImportDone(reportJson),
                rust.ImportEvent_Failed(:final message) => ImportFailed(message),
                rust.ImportEvent_Cancelled() => const ImportCancelled(),
              });

  @override
  void cancel(String jobId) => rust.cancelJob(jobId: jobId);

  @override
  Future<void> writeSyntheticExample({
    required String destPath,
    required int seed,
    required int samples,
    required int variantsPerChrom,
  }) =>
      rust.writeSyntheticExample(
        destPath: destPath,
        seed: BigInt.from(seed),
        samples: samples,
        variantsPerChrom: variantsPerChrom,
        grch37: false,
      );
}

/// Substituído nos testes por um núcleo falso.
final genozCoreProvider = Provider<GenozCore>((ref) => const RustGenozCore());
