import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genoz/core/annotation_models.dart';
import 'package:genoz/core/compare_models.dart';
import 'package:genoz/core/genoz_core.dart';
import 'package:genoz/core/inspect_report.dart';
import 'package:genoz/persistence/app_storage.dart';
import 'package:genoz/persistence/database.dart';
import 'package:genoz/persistence/project_repository.dart';
import 'package:genoz/platform/blob_store.dart';
import 'package:genoz/platform/blob_store_io.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

/// Núcleo falso: copia o arquivo e devolve um relatório pré-gravado
/// (gerado pelo `genoz-cli inspect --json` real).
class FakeGenozCore implements GenozCore {
  FakeGenozCore({this.reportJson, this.failWith, this.hold = false, this.compareFailWith});

  String? reportJson;
  String? failWith;
  String? compareFailWith;

  /// Parâmetros recebidos na última comparação (para os testes conferirem).
  CompareOptions? lastOptions;
  CompareInputFile? lastA;
  CompareInputFile? lastB;
  CompareInputFile? lastReference;
  bool lastChip = false;

  /// Armazenamento do teste (definido por TestEnv).
  late AppStorage storage;

  /// Se verdadeiro, a importação fica parada até `cancel()`.
  bool hold;
  final _cancelled = <String>{};
  final _waiting = <String, Completer<void>>{};

  @override
  String get coreVersion => '0.0.0-teste';

  @override
  Stream<CoreImportEvent> importVcf({required SourceFile source, required String destRelative, required String jobId}) async* {
    yield const ImportProgress(validating: false, bytesDone: 10, bytesTotal: 100);
    final dest = File(storage.absolute(destRelative));
    await dest.parent.create(recursive: true);
    if (source.path != null) {
      await File(source.path!).copy(dest.path);
    } else {
      await storage.blobs.writeStream(destRelative, source.open!());
    }
    // Como o núcleo real, respeita um cancelamento que chegou antes da espera.
    if (hold && !_cancelled.contains(jobId)) {
      final c = _waiting[jobId] = Completer<void>();
      await c.future;
    }
    if (_cancelled.contains(jobId)) {
      await dest.delete();
      yield const ImportCancelled();
      return;
    }
    if (failWith != null) {
      await dest.delete();
      yield ImportFailed(failWith!);
      return;
    }
    yield const ImportProgress(validating: true, bytesDone: 100, bytesTotal: 100);
    // Como o núcleo real: o SHA-256 do relatório é o do conteúdo copiado.
    final report = jsonDecode(reportJson!) as Map<String, dynamic>;
    (report['digest'] as Map<String, dynamic>)['sha256'] = sha256.convert(await dest.readAsBytes()).toString();
    yield ImportDone(jsonEncode(report));
  }

  @override
  void cancel(String jobId) {
    _cancelled.add(jobId);
    _waiting[jobId]?.complete();
  }

  @override
  Future<void> writeSyntheticExample({
    required String destRelative,
    required int seed,
    required int samples,
    required int variantsPerChrom,
  }) async {
    final f = File(storage.absolute(destRelative));
    await f.parent.create(recursive: true);
    await f.writeAsString('##fileformat=VCFv4.3\n');
  }

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
    lastOptions = options;
    lastReference = reference;
    lastChip = chip;
    lastA = a;
    lastB = b;
    yield const CompareProgress(50, 100);
    if (compareFailWith != null) {
      yield CompareFailed(compareFailWith!);
      return;
    }
    // Resultado real (genoz-cli compare pessoa_a × pessoa_b), copiado para a pasta.
    final outDir = storage.absolute(outDirRelative);
    await Directory(outDir).create(recursive: true);
    for (final (from, to) in [
      ('compare_summary.json', 'summary.json'),
      ('compare_stats_a.json', 'stats_a.json'),
      ('compare_stats_b.json', 'stats_b.json'),
      ('compare_manifest.json', 'manifest.json'),
    ]) {
      await File('$outDir/$to').writeAsString(fixture(from));
    }
    yield CompareDone(fixture('compare_summary.json'), fixture('compare_manifest.json'));
  }

  List<ComparisonRow> get _rows => ComparisonRow.parseList(fixture('compare_rows.json'));

  /// Filtra só por categoria e ID (suficiente para os testes de tela).
  List<ComparisonRow> _filtered(RowFilter f) => [
        for (final r in _rows)
          if ((f.categories.isEmpty || f.categories.contains(r.category)) &&
              (f.idContains == null || r.ids.any((i) => i.contains(f.idContains!))) &&
              (f.region == null || (r.chrom == f.region!.chrom && r.pos >= f.region!.start && r.pos <= f.region!.end)))
            r,
      ];

  @override
  Future<RowsPage> page({required String resultDirRelative, required RowFilter filter, required int start, required int count}) async {
    final all = _filtered(filter);
    return RowsPage(all.length, all.skip(start).take(count).toList());
  }

  @override
  Future<ExportResult> export({
    required String resultDirRelative,
    required RowFilter filter,
    required ExportFormat format,
    required String sampleA,
    required String sampleB,
  }) async {
    final rows = _filtered(filter);
    return ExportResult(Uint8List.fromList('${format.name}:${rows.length}'.codeUnits), rows.length);
  }

  @override
  Future<DensityMap> density({required String resultDirRelative, required RowFilter filter, int binSize = 1000000}) async {
    // Mesma regra do núcleo: faixa = (pos - 1) ~/ binSize; listas do tamanho da maior posição.
    final byChrom = <String, List<ComparisonRow>>{};
    for (final r in _filtered(filter)) {
      byChrom.putIfAbsent(r.chrom, () => []).add(r);
    }
    final chroms = <ChromDensity>[];
    for (final e in byChrom.entries) {
      final maxPos = e.value.map((r) => r.pos).reduce((a, b) => a > b ? a : b);
      final bins = (maxPos - 1) ~/ binSize + 1;
      final counts = <String, List<int>>{};
      for (final r in e.value) {
        counts.putIfAbsent(r.category, () => List.filled(bins, 0))[(r.pos - 1) ~/ binSize]++;
      }
      chroms.add(ChromDensity(chrom: e.key, maxPos: maxPos, total: e.value.length, counts: counts));
    }
    return DensityMap(binSize: binSize, total: chroms.fold(0, (a, c) => a + c.total), chroms: chroms);
  }

  @override
  void forgetResult(String resultDirRelative) {}

  /// Anotação falsa: o teste define o que cada pacote devolve.
  Map<String, List<List<AnnotHit>> Function(List<ComparisonRow>)> annotations = {};
  Map<String, List<AnnotRecord>> names = {};
  String sha256Result = '';
  final forgotten = <String>[];

  @override
  Future<AnnotBuildResult> buildAnnotation({
    required String kind,
    required SourceFile source,
    required String outDirRelative,
    required Map<String, Object?> meta,
  }) async {
    final manifest = {...meta, 'kind': kind == 'custom' || kind == 'gtf' ? 'intervals' : 'sites', 'fields': [], 'records': 1};
    await storage.blobs.writeBytes('$outDirRelative/manifest.json', Uint8List.fromList(utf8.encode(jsonEncode(manifest))));
    return AnnotBuildResult(PackageManifest.fromJson(manifest), 0);
  }

  @override
  Future<String> sha256Of(SourceFile source) async => sha256ByName[source.name] ?? sha256Result;

  @override
  Future<List<List<AnnotHit>>> annotate({required List<String> packages, required List<ComparisonRow> rows}) async {
    final out = [for (final _ in rows) <AnnotHit>[]];
    for (final p in packages) {
      final f = annotations[p];
      if (f == null) continue;
      final hits = f(rows);
      for (var i = 0; i < rows.length; i++) {
        out[i].addAll(hits[i]);
      }
    }
    return out;
  }

  @override
  Future<List<AnnotRecord>> findName({required String package, required String name}) async =>
      names['$package/${name.toUpperCase()}'] ?? const [];

  @override
  void forgetAnnotation(String package) => forgotten.add(package);

  // ---- Módulo 11: relatório e cofre (formato falso: JSON com a senha, só para testes) ----
  final reports = <({String project, String lang, bool pdf})>[];
  Map<String, String> sha256ByName = {};

  @override
  Future<Uint8List> analysisReport({
    required String resultDirRelative,
    required String summaryJson,
    required String project,
    required String generatedAt,
    required String lang,
    required bool pdf,
  }) async {
    reports.add((project: project, lang: lang, pdf: pdf));
    return Uint8List.fromList(utf8.encode(pdf ? '%PDF-1.4 falso' : '<!doctype html>'));
  }

  @override
  Future<int> sealVault({
    required Map<String, Uint8List> inline,
    required Map<String, String> files,
    required String outRelative,
    required String password,
  }) async {
    final entries = <String, String>{for (final e in inline.entries) e.key: base64Encode(e.value)};
    for (final e in files.entries) {
      entries[e.key] = base64Encode(await storage.blobs.readBytes(e.value));
    }
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'falso_genoz': password, 'entries': entries})));
    await storage.blobs.writeBytes(outRelative, bytes);
    return bytes.length;
  }

  @override
  Future<List<String>> openVault({required SourceFile source, required String password, required String stagingRelative}) async {
    final raw = source.path != null
        ? await File(source.path!).readAsBytes()
        : (await source.open!().expand((c) => c).toList());
    final Map<String, dynamic> j;
    try {
      j = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
    } catch (_) {
      throw const VaultError('formato');
    }
    if (j['falso_genoz'] != password) throw const VaultError('senha');
    final entries = (j['entries'] as Map<String, dynamic>).cast<String, String>();
    for (final e in entries.entries) {
      await storage.blobs.writeBytes('$stagingRelative/${e.key}', base64Decode(e.value));
    }
    return entries.keys.toList();
  }

  @override
  Region? parseRegion(String text) {
    final m = RegExp(r'^(?:chr)?(\w+):(\d+)(?:-(\d+))?$').firstMatch(text.trim());
    if (m == null) return null;
    final start = int.parse(m[2]!);
    return Region(m[1]!, start, m[3] == null ? start : int.parse(m[3]!));
  }
}

class TestEnv {
  TestEnv._(this.dir, this.db, this.storage, this.core, this.container);

  final Directory dir;
  final GenozDatabase db;
  final AppStorage storage;
  final FakeGenozCore core;
  final ProviderContainer container;

  static Future<TestEnv> create({FakeGenozCore? core}) async {
    final dir = await Directory.systemTemp.createTemp('genoz_test_');
    final db = GenozDatabase(NativeDatabase.memory());
    final storage = AppStorage(IoBlobStore(dir.path));
    final fake = core ?? FakeGenozCore(reportJson: fixture('report_valid.json'));
    fake.storage = storage;
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      appStorageProvider.overrideWithValue(storage),
      genozCoreProvider.overrideWithValue(fake),
    ]);
    return TestEnv._(dir, db, storage, fake, container);
  }

  ProjectRepository get repo => container.read(projectRepositoryProvider);

  /// Um arquivo "escolhido pelo usuário" fora da pasta do app.
  Future<String> sourceFile(String name, [String content = '##fileformat=VCFv4.3\n']) async {
    final f = File('${dir.path}/fora/$name');
    await f.parent.create(recursive: true);
    await f.writeAsString(content);
    return f.path;
  }

  Future<void> dispose() async {
    container.dispose();
    await db.close();
    // No Windows um arquivo recém-fechado pode continuar travado por instantes:
    // tenta de novo e, se não der, deixa a pasta temporária para o sistema limpar.
    for (var i = 0; i < 5; i++) {
      try {
        await dir.delete(recursive: true);
        return;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }
}

/// Armazenamento em memória (testes de widget sem E/S real).
class MemoryBlobStore implements BlobStore {
  final files = <String, Uint8List>{};

  @override
  Future<int> writeStream(String relative, Stream<List<int>> bytes, {void Function(int written)? onProgress}) async {
    final b = BytesBuilder();
    await for (final chunk in bytes) {
      b.add(chunk);
      onProgress?.call(b.length);
    }
    files[relative] = b.takeBytes();
    return files[relative]!.length;
  }

  @override
  Future<void> writeBytes(String relative, Uint8List bytes) async => files[relative] = bytes;

  @override
  Future<Uint8List> readBytes(String relative) async => files[relative] ?? (throw StateError('não existe: $relative'));

  @override
  Future<String> readString(String relative) async => utf8.decode(await readBytes(relative));

  @override
  Future<bool> exists(String relative) async => files.containsKey(relative);

  @override
  Future<int?> size(String relative) async => files[relative]?.length;

  @override
  Future<void> deleteFile(String relative) async => files.remove(relative);

  @override
  Future<void> deleteDir(String relative) async => files.removeWhere((k, _) => k.startsWith('$relative/'));

  @override
  Future<void> move(String from, String to) async => files[to] = files.remove(from) ?? (throw StateError('não existe: $from'));

  @override
  String? nativePath(String relative) => null;
}

/// Projeto com dois arquivos já importados (relatório real do núcleo), pronto para comparar.
Future<(String, ProjectFile, ProjectFile)> projectWithTwoFiles(TestEnv env) async {
  final p = await env.repo.createProject('Comparação');
  final report = InspectReport.parse(fixture('report_valid.json'));
  for (final id in ['fa', 'fb']) {
    await env.repo.addImportedFile(
      projectId: p.id,
      fileId: id,
      displayName: '$id.vcf',
      storedPath: 'projetos/${p.id}/arquivos/$id.vcf',
      report: report,
      reportJson: fixture('report_valid.json'),
    );
  }
  return (p.id, (await env.repo.getFile('fa'))!, (await env.repo.getFile('fb'))!);
}
