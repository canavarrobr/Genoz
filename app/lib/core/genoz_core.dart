// Interface do núcleo científico, vista pelo app.
//
// O app depende desta interface, e não diretamente da ponte Rust, para que
// os testes possam usar um núcleo falso (`FakeGenozCore`) sem compilar Rust.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../src/rust/api/analysis.dart' as rust_analysis;
import '../src/rust/api/genoz.dart' as rust;
import 'compare_models.dart';

// ---- Importação ------------------------------------------------------------

sealed class CoreImportEvent {
  const CoreImportEvent();
}

class ImportProgress extends CoreImportEvent {
  const ImportProgress({required this.validating, required this.bytesDone, required this.bytesTotal});

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

// ---- Comparação ------------------------------------------------------------

/// Um lado da comparação (arquivo já importado).
class CompareInputFile {
  const CompareInputFile({
    required this.path,
    required this.displayName,
    required this.sha256,
    required this.bytes,
    this.sample,
  });

  final String path;
  final String displayName;
  final String sha256;
  final int bytes;
  final String? sample;
}

sealed class CoreCompareEvent {
  const CoreCompareEvent();
}

class CompareProgress extends CoreCompareEvent {
  const CompareProgress(this.bytesDone, this.bytesTotal);
  final int bytesDone;
  final int bytesTotal;
  double get fraction => bytesTotal == 0 ? 0 : (bytesDone / bytesTotal).clamp(0, 1);
}

class CompareDone extends CoreCompareEvent {
  const CompareDone(this.summaryJson, this.manifestJson);
  final String summaryJson;
  final String manifestJson;
}

class CompareFailed extends CoreCompareEvent {
  const CompareFailed(this.message);
  final String message;
}

class CompareCancelled extends CoreCompareEvent {
  const CompareCancelled();
}

class RowsPage {
  const RowsPage(this.total, this.rows);
  final int total;
  final List<ComparisonRow> rows;
}

enum ExportFormat { csv, tsv, json, vcf }

abstract interface class GenozCore {
  String get coreVersion;

  /// Copia `sourcePath` para `destPath`, calcula o SHA-256 e valida.
  Stream<CoreImportEvent> importVcf({required String sourcePath, required String destPath, required String jobId});

  void cancel(String jobId);

  Future<void> writeSyntheticExample({
    required String destPath,
    required int seed,
    required int samples,
    required int variantsPerChrom,
  });

  /// Compara A × B e grava o resultado em `outDir`.
  Stream<CoreCompareEvent> compare({
    required CompareInputFile a,
    required CompareInputFile b,
    required CompareOptions options,
    required String outDir,
    required String createdAt,
    required String jobId,
  });

  Future<RowsPage> page({required String outDir, required RowFilter filter, required int start, required int count});

  /// Exporta as linhas filtradas; o manifesto é copiado para `<destino>.manifest.json`.
  Future<int> export({
    required String outDir,
    required RowFilter filter,
    required ExportFormat format,
    required String sampleA,
    required String sampleB,
    required String destPath,
  });

  void forgetResult(String outDir);

  /// Interpreta `chr7:117.5M-117.6M`, `chr1:1000`, `X`... `null` se não for região.
  Region? parseRegion(String text);
}

/// Implementação real: chama o `genoz_core` (Rust) pela ponte gerada.
class RustGenozCore implements GenozCore {
  const RustGenozCore();

  @override
  String get coreVersion => rust.coreVersion();

  @override
  Stream<CoreImportEvent> importVcf({required String sourcePath, required String destPath, required String jobId}) =>
      rust.importVcf(sourcePath: sourcePath, destPath: destPath, jobId: jobId).map((e) => switch (e) {
            rust.ImportEvent_Progress(:final phase, :final bytesDone, :final bytesTotal) => ImportProgress(
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

  static rust_analysis.CompareSide _side(CompareInputFile f) => rust_analysis.CompareSide(
        path: f.path,
        displayName: f.displayName,
        sha256: f.sha256,
        bytes: BigInt.from(f.bytes),
        sample: f.sample,
      );

  @override
  Stream<CoreCompareEvent> compare({
    required CompareInputFile a,
    required CompareInputFile b,
    required CompareOptions options,
    required String outDir,
    required String createdAt,
    required String jobId,
  }) =>
      rust_analysis
          .compareFiles(
            a: _side(a),
            b: _side(b),
            optionsJson: options.toJsonString(),
            outDir: outDir,
            createdAt: createdAt,
            jobId: jobId,
          )
          .map((e) => switch (e) {
                rust_analysis.CompareEvent_Progress(:final bytesDone, :final bytesTotal) =>
                  CompareProgress(bytesDone.toInt(), bytesTotal.toInt()),
                rust_analysis.CompareEvent_Done(:final summaryJson, :final manifestJson) =>
                  CompareDone(summaryJson, manifestJson),
                rust_analysis.CompareEvent_Failed(:final message) => CompareFailed(message),
                rust_analysis.CompareEvent_Cancelled() => const CompareCancelled(),
              });

  @override
  Future<RowsPage> page({required String outDir, required RowFilter filter, required int start, required int count}) async {
    final p = await rust_analysis.resultPage(
      outDir: outDir,
      filterJson: filter.toJsonString(),
      start: start,
      count: count,
    );
    return RowsPage(p.total, ComparisonRow.parseList(p.rowsJson));
  }

  @override
  Future<int> export({
    required String outDir,
    required RowFilter filter,
    required ExportFormat format,
    required String sampleA,
    required String sampleB,
    required String destPath,
  }) async =>
      (await rust_analysis.exportRows(
        outDir: outDir,
        filterJson: filter.toJsonString(),
        format: format.name,
        sampleA: sampleA,
        sampleB: sampleB,
        destPath: destPath,
      ))
          .toInt();

  @override
  void forgetResult(String outDir) => rust_analysis.forgetResult(outDir: outDir);

  @override
  Region? parseRegion(String text) {
    final json = rust_analysis.parseRegion(text: text);
    return json == null ? null : Region.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }
}

/// Substituído nos testes por um núcleo falso.
final genozCoreProvider = Provider<GenozCore>((ref) => const RustGenozCore());
