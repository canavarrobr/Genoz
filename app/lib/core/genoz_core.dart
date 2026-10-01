// Interface do núcleo científico, vista pelo app.
//
// Duas implementações, mesma lógica científica (Rust):
// - NativeGenozCore (Android/iOS): funções por CAMINHO, em streaming — arquivos grandes;
// - WebGenozCore (navegador): funções por BYTES + OPFS — não existem caminhos.
// Os testes usam um núcleo falso (`FakeGenozCore`). Caminhos aqui são RELATIVOS
// ao armazenamento do app (AppStorage).

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/app_storage.dart';
import '../src/rust/api/analysis.dart' as rust_analysis;
import '../src/rust/api/genoz.dart' as rust;
import '../src/rust/api/memory.dart' as rust_memory;
import 'compare_models.dart';

// ---- Importação ------------------------------------------------------------

/// Arquivo escolhido pelo usuário: por caminho (celular) ou como fluxo de bytes
/// (navegador, ou `content://` no Android).
class SourceFile {
  const SourceFile({required this.name, this.path, this.open, this.size});

  final String name;
  final String? path;
  final Stream<List<int>> Function()? open;
  final int? size;
}

sealed class CoreImportEvent {
  const CoreImportEvent();
}

class ImportProgress extends CoreImportEvent {
  const ImportProgress({required this.validating, required this.bytesDone, required this.bytesTotal});

  /// `false` = copiando e calculando o hash; `true` = validando o VCF.
  final bool validating;
  final int bytesDone;
  final int bytesTotal;

  /// `null` = progresso indeterminado.
  double? get fraction => bytesTotal <= 0 ? null : (bytesDone / bytesTotal).clamp(0, 1);
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
    required this.relativePath,
    required this.displayName,
    required this.sha256,
    required this.bytes,
    this.sample,
  });

  final String relativePath;
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

  /// `null` = progresso indeterminado.
  double? get fraction => bytesTotal <= 0 ? null : (bytesDone / bytesTotal).clamp(0, 1);
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

class ExportResult {
  const ExportResult(this.bytes, this.rows);
  final Uint8List bytes;
  final int rows;
}

abstract interface class GenozCore {
  String get coreVersion;

  /// Copia a origem para `destRelative`, calcula o SHA-256 e valida.
  Stream<CoreImportEvent> importVcf({required SourceFile source, required String destRelative, required String jobId});

  void cancel(String jobId);

  Future<void> writeSyntheticExample({
    required String destRelative,
    required int seed,
    required int samples,
    required int variantsPerChrom,
  });

  /// Compara A × B e grava o resultado em `outDirRelative`.
  Stream<CoreCompareEvent> compare({
    required CompareInputFile a,
    required CompareInputFile b,
    required CompareOptions options,
    required String outDirRelative,
    required String createdAt,
    required String jobId,
  });

  Future<RowsPage> page({required String resultDirRelative, required RowFilter filter, required int start, required int count});

  /// Linhas filtradas exportadas (o manifesto fica em `<resultado>/manifest.json`).
  Future<ExportResult> export({
    required String resultDirRelative,
    required RowFilter filter,
    required ExportFormat format,
    required String sampleA,
    required String sampleB,
  });

  void forgetResult(String resultDirRelative);

  /// Interpreta `chr7:117.5M-117.6M`, `chr1:1000`, `X`... `null` se não for região.
  Region? parseRegion(String text);
}

Region? _parseRegion(String text) {
  final json = rust_analysis.parseRegion(text: text);
  return json == null ? null : Region.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

// ---- Android / iOS --------------------------------------------------------

/// Núcleo nativo: lê e grava arquivos direto no disco, em streaming.
class NativeGenozCore implements GenozCore {
  const NativeGenozCore(this.storage);
  final AppStorage storage;

  @override
  String get coreVersion => rust.coreVersion();

  @override
  Stream<CoreImportEvent> importVcf({required SourceFile source, required String destRelative, required String jobId}) async* {
    final dest = storage.absolute(destRelative);
    var origin = source.path;
    if (origin == null) {
      // Sem caminho (ex.: `content://`): grava os bytes no destino e valida lá mesmo.
      final progress = StreamController<CoreImportEvent>();
      final writing = storage.blobs
          .writeStream(destRelative, source.open!(),
              onProgress: (n) => progress.add(ImportProgress(validating: false, bytesDone: n, bytesTotal: source.size ?? 0)))
          .whenComplete(progress.close);
      yield* progress.stream;
      await writing;
      origin = dest;
    }
    yield* rust.importVcf(sourcePath: origin, destPath: dest, jobId: jobId).map((e) => switch (e) {
          rust.ImportEvent_Progress(:final phase, :final bytesDone, :final bytesTotal) => ImportProgress(
              validating: phase == rust.ImportPhase.validating,
              bytesDone: bytesDone.toInt(),
              bytesTotal: bytesTotal.toInt(),
            ),
          rust.ImportEvent_Done(:final reportJson) => ImportDone(reportJson),
          rust.ImportEvent_Failed(:final message) => ImportFailed(message),
          rust.ImportEvent_Cancelled() => const ImportCancelled(),
        });
  }

  @override
  void cancel(String jobId) => rust.cancelJob(jobId: jobId);

  @override
  Future<void> writeSyntheticExample({
    required String destRelative,
    required int seed,
    required int samples,
    required int variantsPerChrom,
  }) =>
      rust.writeSyntheticExample(
        destPath: storage.absolute(destRelative),
        seed: BigInt.from(seed),
        samples: samples,
        variantsPerChrom: variantsPerChrom,
        grch37: false,
      );

  rust_analysis.CompareSide _side(CompareInputFile f) => rust_analysis.CompareSide(
        path: storage.absolute(f.relativePath),
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
    required String outDirRelative,
    required String createdAt,
    required String jobId,
  }) =>
      rust_analysis
          .compareFiles(
            a: _side(a),
            b: _side(b),
            optionsJson: options.toJsonString(),
            outDir: storage.absolute(outDirRelative),
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
  Future<RowsPage> page({required String resultDirRelative, required RowFilter filter, required int start, required int count}) async {
    final p = await rust_analysis.resultPage(
      outDir: storage.absolute(resultDirRelative),
      filterJson: filter.toJsonString(),
      start: start,
      count: count,
    );
    return RowsPage(p.total, ComparisonRow.parseList(p.rowsJson));
  }

  @override
  Future<ExportResult> export({
    required String resultDirRelative,
    required RowFilter filter,
    required ExportFormat format,
    required String sampleA,
    required String sampleB,
  }) async {
    final rel = '$resultDirRelative/exportacao.${format.name}';
    final n = await rust_analysis.exportRows(
      outDir: storage.absolute(resultDirRelative),
      filterJson: filter.toJsonString(),
      format: format.name,
      sampleA: sampleA,
      sampleB: sampleB,
      destPath: storage.absolute(rel),
    );
    final bytes = await storage.blobs.readBytes(rel);
    await storage.blobs.deleteFile(rel);
    await storage.blobs.deleteFile('$rel.manifest.json');
    return ExportResult(bytes, n.toInt());
  }

  @override
  void forgetResult(String resultDirRelative) => rust_analysis.forgetResult(outDir: storage.absolute(resultDirRelative));

  @override
  Region? parseRegion(String text) => _parseRegion(text);
}

// ---- Navegador ------------------------------------------------------------

/// Tamanho máximo de cada arquivo no navegador (memória do WebAssembly).
/// Acima disso o app avisa — nunca envia o arquivo para um servidor.
const webMaxFileBytes = 400 * 1024 * 1024;

String webTooLarge(int bytes) =>
    'arquivo de ${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB: acima do limite de '
    '${webMaxFileBytes ~/ (1024 * 1024)} MB por arquivo no navegador. Use o app Android para arquivos maiores.';

/// Núcleo no navegador: arquivos no OPFS, processamento em memória (WASM em Web Workers).
class WebGenozCore implements GenozCore {
  WebGenozCore(this.storage);
  final AppStorage storage;
  final _cancelled = <String>{};

  @override
  String get coreVersion => rust.coreVersion();

  @override
  Stream<CoreImportEvent> importVcf({required SourceFile source, required String destRelative, required String jobId}) async* {
    final blobs = storage.blobs;
    try {
      if ((source.size ?? 0) > webMaxFileBytes) {
        yield ImportFailed(webTooLarge(source.size!));
        return;
      }
      final progress = StreamController<CoreImportEvent>();
      final writing = blobs
          .writeStream(destRelative, source.open!(),
              onProgress: (n) => progress.add(ImportProgress(validating: false, bytesDone: n, bytesTotal: source.size ?? 0)))
          .whenComplete(progress.close);
      yield* progress.stream;
      final written = await writing;
      if (written > webMaxFileBytes) {
        await blobs.deleteFile(destRelative);
        yield ImportFailed(webTooLarge(written));
        return;
      }
      if (_cancelled.remove(jobId)) {
        await blobs.deleteFile(destRelative);
        yield const ImportCancelled();
        return;
      }
      yield const ImportProgress(validating: true, bytesDone: 0, bytesTotal: 0);
      final report = await rust_memory.inspectBytes(data: await blobs.readBytes(destRelative));
      if (_cancelled.remove(jobId)) {
        await blobs.deleteFile(destRelative);
        yield const ImportCancelled();
        return;
      }
      yield ImportDone(report);
    } catch (e) {
      await blobs.deleteFile(destRelative);
      yield ImportFailed(e.toString());
    }
  }

  @override
  void cancel(String jobId) => _cancelled.add(jobId);

  @override
  Future<void> writeSyntheticExample({
    required String destRelative,
    required int seed,
    required int samples,
    required int variantsPerChrom,
  }) async {
    final bytes = await rust_memory.syntheticBytes(seed: BigInt.from(seed), samples: samples, variantsPerChrom: variantsPerChrom);
    await storage.blobs.writeBytes(destRelative, bytes);
  }

  Future<rust_memory.MemorySide> _side(CompareInputFile f) async => rust_memory.MemorySide(
        displayName: f.displayName,
        sha256: f.sha256,
        sample: f.sample,
        data: await storage.blobs.readBytes(f.relativePath),
      );

  @override
  Stream<CoreCompareEvent> compare({
    required CompareInputFile a,
    required CompareInputFile b,
    required CompareOptions options,
    required String outDirRelative,
    required String createdAt,
    required String jobId,
  }) async* {
    for (final f in [a, b]) {
      if (f.bytes > webMaxFileBytes) {
        yield CompareFailed(webTooLarge(f.bytes));
        return;
      }
    }
    yield const CompareProgress(0, 0);
    try {
      final out = await rust_memory.compareBytes(
        a: await _side(a),
        b: await _side(b),
        optionsJson: options.toJsonString(),
        createdAt: createdAt,
      );
      if (_cancelled.remove(jobId)) {
        yield const CompareCancelled();
        return;
      }
      final blobs = storage.blobs;
      await blobs.writeBytes('$outDirRelative/rows.bgz', out.rowsBgz);
      await blobs.writeBytes('$outDirRelative/rows.idx', out.rowsIdx);
      for (final (name, text) in [
        ('summary.json', out.summaryJson),
        ('stats_a.json', out.statsAJson),
        ('stats_b.json', out.statsBJson),
        ('manifest.json', out.manifestJson),
      ]) {
        await blobs.writeBytes('$outDirRelative/$name', Uint8List.fromList(utf8.encode(text)));
      }
      yield CompareDone(out.summaryJson, out.manifestJson);
    } catch (e) {
      await storage.blobs.deleteDir(outDirRelative);
      yield CompareFailed(e.toString());
    }
  }

  Future<void> _ensureLoaded(String resultDirRelative) async {
    if (rust_memory.resultIsLoaded(key: resultDirRelative)) return;
    await rust_memory.resultLoad(
      key: resultDirRelative,
      rowsBgz: await storage.blobs.readBytes('$resultDirRelative/rows.bgz'),
      rowsIdx: await storage.blobs.readBytes('$resultDirRelative/rows.idx'),
    );
  }

  @override
  Future<RowsPage> page({required String resultDirRelative, required RowFilter filter, required int start, required int count}) async {
    await _ensureLoaded(resultDirRelative);
    final p = await rust_memory.resultPageLoaded(
      key: resultDirRelative,
      filterJson: filter.toJsonString(),
      start: start,
      count: count,
    );
    return RowsPage(p.total, ComparisonRow.parseList(p.rowsJson));
  }

  @override
  Future<ExportResult> export({
    required String resultDirRelative,
    required RowFilter filter,
    required ExportFormat format,
    required String sampleA,
    required String sampleB,
  }) async {
    await _ensureLoaded(resultDirRelative);
    final e = await rust_memory.exportLoaded(
      key: resultDirRelative,
      filterJson: filter.toJsonString(),
      format: format.name,
      sampleA: sampleA,
      sampleB: sampleB,
    );
    return ExportResult(e.data, e.rows.toInt());
  }

  @override
  void forgetResult(String resultDirRelative) => rust_memory.resultUnload(key: resultDirRelative);

  @override
  Region? parseRegion(String text) => _parseRegion(text);
}

/// Núcleo da plataforma atual. Substituído nos testes por um núcleo falso.
final genozCoreProvider = Provider<GenozCore>((ref) {
  final storage = ref.watch(appStorageProvider);
  return kIsWeb ? WebGenozCore(storage) : NativeGenozCore(storage);
});
