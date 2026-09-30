import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/core/inspect_report.dart';
import 'package:genoz/persistence/project_repository.dart';

import 'support.dart';

void main() {
  late TestEnv env;
  setUp(() async => env = await TestEnv.create());
  tearDown(() => env.dispose());

  test('relatório real do núcleo é lido pelo modelo Dart', () {
    final r = InspectReport.parse(fixture('report_valid.json'));
    expect(r.verdict, Verdict.valid);
    expect(r.build, 'GRCh38');
    expect(r.buildConfidence, 'high');
    expect(r.samples.map((s) => s.name), ['AMOSTRA_A', 'AMOSTRA_B']);
    expect(r.recordsOk, 9);
    expect(r.byKind['snv'], 6);
    expect(r.sha256, hasLength(64));

    final partial = InspectReport.parse(fixture('report_partial.json'));
    expect(partial.verdict, Verdict.partiallyValid);
    expect(partial.issues.where((i) => i.isError), hasLength(5));

    final invalid = InspectReport.parse(fixture('report_invalid.json'));
    expect(invalid.isUsable, isFalse);
    expect(invalid.fatal, contains('terminou antes'));
  });

  test('criar, listar, renomear e contar arquivos', () async {
    final p = await env.repo.createProject('  Aula de genética  ', description: '  ');
    expect(p.name, 'Aula de genética');
    expect(p.description, isNull);

    final report = InspectReport.parse(fixture('report_valid.json'));
    await env.repo.addImportedFile(
      projectId: p.id,
      fileId: 'f1',
      displayName: 'a.vcf',
      storedPath: 'projetos/${p.id}/arquivos/f1.vcf',
      report: report,
      reportJson: fixture('report_valid.json'),
    );
    final list = await env.repo.watchProjects().first;
    expect(list.single.fileCount, 1);

    await env.repo.renameProject(p.id, 'Novo nome');
    expect((await env.repo.watchProject(p.id).first)!.name, 'Novo nome');

    final file = (await env.repo.getFile('f1'))!;
    expect(file.sampleNames, ['AMOSTRA_A', 'AMOSTRA_B']);
    expect(file.verdictValue, Verdict.valid);
    expect(file.report.recordsOk, 9);
    expect(await env.repo.findBySha(p.id, report.sha256), isNotNull);
  });

  test('apagar projeto remove arquivos do banco e do disco', () async {
    final p = await env.repo.createProject('Temporário');
    final rel = env.storage.newFileRelative(p.id, 'f1', 'x.vcf.gz');
    final f = File(env.storage.absolute(rel));
    await f.parent.create(recursive: true);
    await f.writeAsString('dados');
    await env.repo.addImportedFile(
      projectId: p.id,
      fileId: 'f1',
      displayName: 'x.vcf.gz',
      storedPath: rel,
      report: InspectReport.parse(fixture('report_valid.json')),
      reportJson: fixture('report_valid.json'),
    );

    await env.repo.deleteProject(p.id);

    expect(await env.repo.getFile('f1'), isNull, reason: 'cascata no banco');
    expect(await Directory(env.storage.projectDir(p.id)).exists(), isFalse, reason: 'pasta apagada');
    expect(await env.repo.watchProjects().first, isEmpty);
  });

  test('extensão do arquivo é preservada', () {
    expect(env.storage.newFileRelative('p', 'f', 'Amostra.VCF.GZ'), endsWith('f.vcf.gz'));
    expect(env.storage.newFileRelative('p', 'f', 'a.vcf'), endsWith('f.vcf'));
    expect(env.storage.newFileRelative('p', 'f', 'a.vcf.bgz'), endsWith('f.vcf.gz'));
  });
}
