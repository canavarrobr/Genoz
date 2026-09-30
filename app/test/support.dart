import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genoz/core/compare_models.dart';
import 'package:genoz/core/genoz_core.dart';
import 'package:genoz/persistence/app_storage.dart';
import 'package:genoz/persistence/database.dart';
import 'package:genoz/persistence/project_repository.dart';

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

  /// Se verdadeiro, a importação fica parada até `cancel()`.
  bool hold;
  final _cancelled = <String>{};
  final _waiting = <String, Completer<void>>{};

  @override
  String get coreVersion => '0.0.0-teste';

  @override
  Stream<CoreImportEvent> importVcf({
    required String sourcePath,
    required String destPath,
    required String jobId,
  }) async* {
    yield const ImportProgress(validating: false, bytesDone: 10, bytesTotal: 100);
    final dest = File(destPath);
    await dest.parent.create(recursive: true);
    if (sourcePath != destPath) await File(sourcePath).copy(destPath);
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
    yield ImportDone(reportJson!);
  }

  @override
  void cancel(String jobId) {
    _cancelled.add(jobId);
    _waiting[jobId]?.complete();
  }

  @override
  Future<void> writeSyntheticExample({
    required String destPath,
    required int seed,
    required int samples,
    required int variantsPerChrom,
  }) async {
    await File(destPath).parent.create(recursive: true);
    await File(destPath).writeAsString('##fileformat=VCFv4.3\n');
  }

  @override
  Stream<CoreCompareEvent> compare({
    required CompareInputFile a,
    required CompareInputFile b,
    required CompareOptions options,
    required String outDir,
    required String createdAt,
    required String jobId,
  }) async* {
    lastOptions = options;
    lastA = a;
    lastB = b;
    yield const CompareProgress(50, 100);
    if (compareFailWith != null) {
      yield CompareFailed(compareFailWith!);
      return;
    }
    // Resultado real (genoz-cli compare pessoa_a × pessoa_b), copiado para a pasta.
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
              (f.idContains == null || r.ids.any((i) => i.contains(f.idContains!))))
            r,
      ];

  @override
  Future<RowsPage> page({required String outDir, required RowFilter filter, required int start, required int count}) async {
    final all = _filtered(filter);
    return RowsPage(all.length, all.skip(start).take(count).toList());
  }

  @override
  Future<int> export({
    required String outDir,
    required RowFilter filter,
    required ExportFormat format,
    required String sampleA,
    required String sampleB,
    required String destPath,
  }) async {
    final rows = _filtered(filter);
    await File(destPath).parent.create(recursive: true);
    await File(destPath).writeAsString('${format.name}:${rows.length}');
    return rows.length;
  }

  @override
  void forgetResult(String outDir) {}

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
    final storage = AppStorage(dir.path);
    final fake = core ?? FakeGenozCore(reportJson: fixture('report_valid.json'));
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
    await dir.delete(recursive: true);
  }
}
