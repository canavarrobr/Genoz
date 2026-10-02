// Interface do núcleo científico, vista pelo app.
//
// Duas implementações, mesma lógica científica (Rust):
// - NativeGenozCore (Android/iOS): funções por CAMINHO, em streaming — arquivos grandes;
// - WebGenozCore (navegador): funções por BYTES + OPFS — não existem caminhos.
// Os testes usam um núcleo falso (`FakeGenozCore`). Caminhos aqui são RELATIVOS
// ao armazenamento do app (AppStorage).

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/app_storage.dart';
import '../src/rust/api/analysis.dart' as rust_analysis;
import '../src/rust/api/annotation.dart' as rust_annot;
import '../src/rust/api/family.dart' as rust_family;
import '../src/rust/api/genoz.dart' as rust;
import '../src/rust/api/memory.dart' as rust_memory;
import '../src/rust/api/vault.dart' as rust_vault;
import 'annotation_models.dart';
import 'compare_models.dart';
import 'density.dart';
export 'density.dart';

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
/// Resultado da construção de um pacote de anotação.
class AnnotBuildResult {
  const AnnotBuildResult(this.manifest, this.skipped);
  final PackageManifest manifest;

  /// Linhas do arquivo de origem ignoradas (malformadas).
  final int skipped;
}

String _rowsJson(List<ComparisonRow> rows) =>
    jsonEncode([for (final r in rows) {'chrom': r.chrom, 'pos': r.pos, 'ref': r.reference, 'alt': r.alt}]);

Future<Uint8List> _allBytes(SourceFile source) async {
  final b = BytesBuilder(copy: false);
  await for (final chunk in source.open!()) {
    b.add(chunk);
  }
  return b.takeBytes();
}

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

// ---- Relatórios e cofre .genoz (Módulo 11) ---------------------------------

/// Erro ao abrir/criar um `.genoz`. `code`: `senha` (senha errada, arquivo alterado ou
/// incompleto), `formato` (não é .genoz), `versao` (de um Genoz mais novo) ou `outro`.
class VaultError implements Exception {
  const VaultError(this.code, [this.detail = '']);
  final String code;
  final String detail;

  static VaultError from(Object e) {
    final s = '$e';
    return switch (s) {
      'senha' || 'formato' || 'versao' => VaultError(s),
      _ => VaultError('outro', s),
    };
  }

  @override
  String toString() => detail.isEmpty ? 'VaultError($code)' : detail;
}

/// 32 bytes do gerador seguro do sistema (sal + prefixo do nonce do cofre).
Uint8List secureRandom32() {
  final r = Random.secure();
  return Uint8List.fromList(List.generate(32, (_) => r.nextInt(256)));
}

/// Relatório (HTML ou PDF) de uma análise salva: lê estatísticas e manifesto da pasta.
Future<Uint8List> buildAnalysisReport(
  AppStorage storage, {
  required String resultDirRelative,
  required String summaryJson,
  required String project,
  required String generatedAt,
  required String lang,
  required bool pdf,
}) async {
  Future<String> optional(String name) async {
    final rel = '$resultDirRelative/$name';
    return await storage.blobs.exists(rel) ? storage.blobs.readString(rel) : '';
  }

  return rust_vault.analysisReport(
    summaryJson: summaryJson,
    statsAJson: await optional('stats_a.json'),
    statsBJson: await optional('stats_b.json'),
    manifestJson: await optional('manifest.json'),
    project: project,
    generatedAt: generatedAt,
    lang: lang,
    pdf: pdf,
  );
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
  /// Compara A × B. `chip`: A é um arquivo de chip de consumidor (comparação
  /// restrita aos sítios do chip). `reference`: FASTA local opcional
  /// (normaliza indels; no chip × VCF, julga homozigotos sem registro no VCF).
  Stream<CoreCompareEvent> compare({
    required CompareInputFile a,
    required CompareInputFile b,
    required CompareOptions options,
    required String outDirRelative,
    required String createdAt,
    required String jobId,
    CompareInputFile? reference,
    bool chip = false,
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

  /// Densidade de variantes por cromossomo/faixa/categoria (ideograma).
  Future<DensityMap> density({required String resultDirRelative, required RowFilter filter, int binSize = 1000000});

  void forgetResult(String resultDirRelative);

  // ---- Anotação local (Módulo 10) ----

  /// Constrói um pacote (`kind`: `gtf`, `clinvar` ou `custom`) a partir de um arquivo
  /// e grava `manifest.json`, `records.bgz` e `records.idx` em `outDirRelative`.
  Future<AnnotBuildResult> buildAnnotation({
    required String kind,
    required SourceFile source,
    required String outDirRelative,
    required Map<String, Object?> meta,
  });

  /// SHA-256 de um arquivo escolhido (conferência de download do catálogo).
  Future<String> sha256Of(SourceFile source);

  /// Anotação das linhas com os pacotes (pastas relativas). Uma lista por linha.
  Future<List<List<AnnotHit>>> annotate({required List<String> packages, required List<ComparisonRow> rows});

  /// Procura um nome (ex.: gene) num pacote.
  Future<List<AnnotRecord>> findName({required String package, required String name});

  void forgetAnnotation(String package);

  // ---- Família e populações (Módulo 12) ----

  /// Analisa um VCF multiamostra e grava `familia.json` e `manifest.json` em `outDirRelative`.
  /// Devolve o JSON do resultado e o do manifesto.
  Future<({String result, String manifest})> analyzeFamily({
    required CompareInputFile input,
    required String optionsJson,
    required String outDirRelative,
    required String createdAt,
  });

  /// VCF (BGZF) de uma família fictícia.
  Future<Uint8List> syntheticFamily(int seed);

  // ---- Relatório e cofre .genoz (Módulo 11) ----

  /// Relatório HTML autocontido ou PDF de uma análise salva.
  Future<Uint8List> analysisReport({
    required String resultDirRelative,
    required String summaryJson,
    required String project,
    required String generatedAt,
    required String lang,
    required bool pdf,
  });

  /// Cifra com senha um pacote com `inline` (ex.: projeto.json) e arquivos do
  /// armazenamento (`caminho no pacote → caminho relativo`). Grava em `outRelative`.
  Future<int> sealVault({
    required Map<String, Uint8List> inline,
    required Map<String, String> files,
    required String outRelative,
    required String password,
  });

  /// Abre um `.genoz` e extrai tudo em `stagingRelative/<caminho>` (nada fica se der
  /// erro). Lança [VaultError]. Devolve os caminhos do pacote.
  Future<List<String>> openVault({required SourceFile source, required String password, required String stagingRelative});

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
    CompareInputFile? reference,
    bool chip = false,
  }) =>
      (chip
              ? rust_analysis.compareChipFiles(
                  chip: _side(a),
                  vcf: _side(b),
                  reference: reference == null ? null : _side(reference),
                  optionsJson: options.toJsonString(),
                  outDir: storage.absolute(outDirRelative),
                  createdAt: createdAt,
                  jobId: jobId,
                )
              : rust_analysis.compareFiles(
                  a: _side(a),
                  b: _side(b),
                  reference: reference == null ? null : _side(reference),
                  optionsJson: options.toJsonString(),
                  outDir: storage.absolute(outDirRelative),
                  createdAt: createdAt,
                  jobId: jobId,
                ))
          .map((e) => switch (e) {
                rust_analysis.CompareEvent_Progress(:final bytesDone, :final bytesTotal) =>
                  CompareProgress(bytesDone.toInt(), bytesTotal.toInt()),
                rust_analysis.CompareEvent_Done(:final summaryJson, :final manifestJson) =>
                  CompareDone(summaryJson, manifestJson),
                rust_analysis.CompareEvent_Failed(:final message) => CompareFailed(message),
                rust_analysis.CompareEvent_Cancelled() => const CompareCancelled(),
              });

  @override
  Future<DensityMap> density({required String resultDirRelative, required RowFilter filter, int binSize = 1000000}) async =>
      DensityMap.parse(await rust_analysis.resultDensity(
        outDir: storage.absolute(resultDirRelative),
        filterJson: filter.toJsonString(),
        binSize: BigInt.from(binSize),
      ));

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
  Future<AnnotBuildResult> buildAnnotation({
    required String kind,
    required SourceFile source,
    required String outDirRelative,
    required Map<String, Object?> meta,
  }) async {
    var path = source.path;
    String? temp;
    if (path == null) {
      // Origem só como fluxo (ex.: content:// no Android): grava uma cópia temporária.
      temp = '$outDirRelative.entrada';
      await storage.blobs.writeStream(temp, source.open!());
      path = storage.absolute(temp);
    }
    try {
      final r = await rust_annot.annotBuild(
        kind: kind,
        inputPath: path,
        outDir: storage.absolute(outDirRelative),
        metaJson: jsonEncode(meta),
      );
      return AnnotBuildResult(PackageManifest.parse(r.manifestJson), r.skipped.toInt());
    } finally {
      if (temp != null) await storage.blobs.deleteFile(temp);
    }
  }

  @override
  Future<String> sha256Of(SourceFile source) async => source.path != null
      ? rust_annot.sha256File(path: source.path!)
      : rust_annot.sha256OfBytes(data: await _allBytes(source));

  @override
  Future<List<List<AnnotHit>>> annotate({required List<String> packages, required List<ComparisonRow> rows}) async =>
      AnnotHit.parseRows(await rust_annot.annotAnnotate(
        packages: [for (final p in packages) storage.absolute(p)],
        rowsJson: _rowsJson(rows),
      ));

  @override
  Future<List<AnnotRecord>> findName({required String package, required String name}) async =>
      AnnotRecord.parseList(await rust_annot.annotFindName(package: storage.absolute(package), name: name));

  @override
  void forgetAnnotation(String package) => rust_annot.annotForget(key: storage.absolute(package));

  @override
  Future<({String result, String manifest})> analyzeFamily({
    required CompareInputFile input,
    required String optionsJson,
    required String outDirRelative,
    required String createdAt,
  }) async {
    final r = await rust_family.familyAnalyzeFile(
      path: storage.absolute(input.relativePath),
      inputName: input.displayName,
      inputSha256: input.sha256,
      inputBytes: BigInt.from(input.bytes),
      optionsJson: optionsJson,
      outDir: storage.absolute(outDirRelative),
      createdAt: createdAt,
    );
    return (result: r.resultJson, manifest: r.manifestJson);
  }

  @override
  Future<Uint8List> syntheticFamily(int seed) => rust_family.syntheticFamilyBytes(seed: BigInt.from(seed));

  @override
  Future<Uint8List> analysisReport({
    required String resultDirRelative,
    required String summaryJson,
    required String project,
    required String generatedAt,
    required String lang,
    required bool pdf,
  }) =>
      buildAnalysisReport(
        storage,
        resultDirRelative: resultDirRelative,
        summaryJson: summaryJson,
        project: project,
        generatedAt: generatedAt,
        lang: lang,
        pdf: pdf,
      );

  @override
  Future<int> sealVault({
    required Map<String, Uint8List> inline,
    required Map<String, String> files,
    required String outRelative,
    required String password,
  }) async {
    try {
      final n = await rust_vault.vaultSealFiles(
        inline: [for (final e in inline.entries) rust_vault.PackBytes(path: e.key, data: e.value)],
        files: [for (final e in files.entries) rust_vault.PackFile(path: e.key, sourcePath: storage.absolute(e.value))],
        outPath: storage.absolute(outRelative),
        password: password,
        random: secureRandom32(),
      );
      return n.toInt();
    } on String catch (e) {
      throw VaultError.from(e);
    }
  }

  @override
  Future<List<String>> openVault({required SourceFile source, required String password, required String stagingRelative}) async {
    var path = source.path;
    String? temp;
    if (path == null) {
      temp = '$stagingRelative.entrada';
      await storage.blobs.writeStream(temp, source.open!());
      path = storage.absolute(temp);
    }
    try {
      return await rust_vault.vaultOpenToDir(inPath: path, password: password, outDir: storage.absolute(stagingRelative));
    } on String catch (e) {
      throw VaultError.from(e);
    } finally {
      if (temp != null) await storage.blobs.deleteFile(temp);
    }
  }

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
    CompareInputFile? reference,
    bool chip = false,
  }) async* {
    for (final f in [a, b, ?reference]) {
      if (f.bytes > webMaxFileBytes) {
        yield CompareFailed(webTooLarge(f.bytes));
        return;
      }
    }
    yield const CompareProgress(0, 0);
    try {
      final ref = reference == null ? null : await _side(reference);
      final out = chip
          ? await rust_memory.compareChipBytes(
              chip: await _side(a),
              vcf: await _side(b),
              reference: ref,
              optionsJson: options.toJsonString(),
              createdAt: createdAt,
            )
          : await rust_memory.compareBytes(
              a: await _side(a),
              b: await _side(b),
              reference: ref,
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
  Future<DensityMap> density({required String resultDirRelative, required RowFilter filter, int binSize = 1000000}) async {
    await _ensureLoaded(resultDirRelative);
    return DensityMap.parse(await rust_memory.resultDensityLoaded(
      key: resultDirRelative,
      filterJson: filter.toJsonString(),
      binSize: BigInt.from(binSize),
    ));
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
  Future<AnnotBuildResult> buildAnnotation({
    required String kind,
    required SourceFile source,
    required String outDirRelative,
    required Map<String, Object?> meta,
  }) async {
    if ((source.size ?? 0) > webMaxFileBytes) throw StateError(webTooLarge(source.size!));
    final b = await rust_annot.annotBuildBytes(kind: kind, data: await _allBytes(source), metaJson: jsonEncode(meta));
    final blobs = storage.blobs;
    await blobs.writeBytes('$outDirRelative/records.bgz', b.recordsBgz);
    await blobs.writeBytes('$outDirRelative/records.idx', b.indexJson);
    await blobs.writeBytes('$outDirRelative/manifest.json', Uint8List.fromList(utf8.encode(b.report.manifestJson)));
    rust_annot.annotForget(key: outDirRelative);
    return AnnotBuildResult(PackageManifest.parse(b.report.manifestJson), b.report.skipped.toInt());
  }

  @override
  Future<String> sha256Of(SourceFile source) async => rust_annot.sha256OfBytes(data: await _allBytes(source));

  /// No navegador o pacote é carregado na memória do núcleo uma vez.
  Future<void> _ensureAnnot(String package) async {
    if (rust_annot.annotIsLoaded(key: package)) return;
    final blobs = storage.blobs;
    await rust_annot.annotLoad(
      key: package,
      manifestJson: await blobs.readBytes('$package/manifest.json'),
      indexJson: await blobs.readBytes('$package/records.idx'),
      recordsBgz: await blobs.readBytes('$package/records.bgz'),
    );
  }

  @override
  Future<List<List<AnnotHit>>> annotate({required List<String> packages, required List<ComparisonRow> rows}) async {
    for (final p in packages) {
      await _ensureAnnot(p);
    }
    return AnnotHit.parseRows(await rust_annot.annotAnnotate(packages: packages, rowsJson: _rowsJson(rows)));
  }

  @override
  Future<List<AnnotRecord>> findName({required String package, required String name}) async {
    await _ensureAnnot(package);
    return AnnotRecord.parseList(await rust_annot.annotFindName(package: package, name: name));
  }

  @override
  void forgetAnnotation(String package) => rust_annot.annotForget(key: package);

  @override
  Future<({String result, String manifest})> analyzeFamily({
    required CompareInputFile input,
    required String optionsJson,
    required String outDirRelative,
    required String createdAt,
  }) async {
    if (input.bytes > webMaxFileBytes) throw StateError(webTooLarge(input.bytes));
    final r = await rust_family.familyAnalyzeBytes(
      data: await storage.blobs.readBytes(input.relativePath),
      inputName: input.displayName,
      inputSha256: input.sha256,
      optionsJson: optionsJson,
      createdAt: createdAt,
    );
    await storage.blobs.writeBytes('$outDirRelative/familia.json', Uint8List.fromList(utf8.encode(r.resultJson)));
    await storage.blobs.writeBytes('$outDirRelative/manifest.json', Uint8List.fromList(utf8.encode(r.manifestJson)));
    return (result: r.resultJson, manifest: r.manifestJson);
  }

  @override
  Future<Uint8List> syntheticFamily(int seed) => rust_family.syntheticFamilyBytes(seed: BigInt.from(seed));

  @override
  Future<Uint8List> analysisReport({
    required String resultDirRelative,
    required String summaryJson,
    required String project,
    required String generatedAt,
    required String lang,
    required bool pdf,
  }) =>
      buildAnalysisReport(
        storage,
        resultDirRelative: resultDirRelative,
        summaryJson: summaryJson,
        project: project,
        generatedAt: generatedAt,
        lang: lang,
        pdf: pdf,
      );

  @override
  Future<int> sealVault({
    required Map<String, Uint8List> inline,
    required Map<String, String> files,
    required String outRelative,
    required String password,
  }) async {
    final entries = [for (final e in inline.entries) rust_vault.PackBytes(path: e.key, data: e.value)];
    for (final e in files.entries) {
      entries.add(rust_vault.PackBytes(path: e.key, data: await storage.blobs.readBytes(e.value)));
    }
    try {
      final sealed = await rust_vault.vaultSealBytes(entries: entries, password: password, random: secureRandom32());
      await storage.blobs.writeBytes(outRelative, sealed);
      return sealed.length;
    } on String catch (e) {
      throw VaultError.from(e);
    }
  }

  @override
  Future<List<String>> openVault({required SourceFile source, required String password, required String stagingRelative}) async {
    if ((source.size ?? 0) > webMaxFileBytes) throw StateError(webTooLarge(source.size!));
    final List<rust_vault.PackBytes> entries;
    try {
      entries = await rust_vault.vaultOpenBytes(data: await _allBytes(source), password: password);
    } on String catch (e) {
      throw VaultError.from(e);
    }
    for (final e in entries) {
      await storage.blobs.writeBytes('$stagingRelative/${e.path}', e.data);
    }
    return [for (final e in entries) e.path];
  }

  @override
  Region? parseRegion(String text) => _parseRegion(text);
}

/// Núcleo da plataforma atual. Substituído nos testes por um núcleo falso.
final genozCoreProvider = Provider<GenozCore>((ref) {
  final storage = ref.watch(appStorageProvider);
  return kIsWeb ? WebGenozCore(storage) : NativeGenozCore(storage);
});
