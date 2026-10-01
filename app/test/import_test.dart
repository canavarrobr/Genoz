import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/core/genoz_core.dart';
import 'package:genoz/features/import/import_controller.dart';

import 'support.dart';

void main() {
  late TestEnv env;
  tearDown(() => env.dispose());

  Future<String> project() async => (await env.repo.createProject('P')).id;
  ImportController controller() => env.container.read(importControllerProvider.notifier);
  ImportState state() => env.container.read(importControllerProvider);
  Future<List<File>> storedFiles(String projectId) async {
    final dir = Directory(env.storage.projectDir(projectId));
    if (!await dir.exists()) return [];
    return dir.list(recursive: true).where((e) => e is File).cast<File>().toList();
  }

  test('importação válida copia o arquivo e grava no banco', () async {
    env = await TestEnv.create();
    final pid = await project();
    final src = await env.sourceFile('amostra.vcf.gz');

    await controller().importFile(projectId: pid, source: SourceFile(name: 'amostra.vcf.gz', path: src));

    expect(state(), isA<ImportSucceeded>());
    final files = await env.repo.watchFiles(pid).first;
    expect(files.single.displayName, 'amostra.vcf.gz');
    expect(files.single.storedPath, endsWith('.vcf.gz'));
    expect(await File(env.storage.absolute(files.single.storedPath)).exists(), isTrue);
    expect(await File(src).exists(), isTrue, reason: 'o original não é tocado');
  });

  test('arquivo inválido é recusado e a cópia é apagada', () async {
    env = await TestEnv.create(core: FakeGenozCore(reportJson: fixture('report_invalid.json')));
    final pid = await project();
    await controller().importFile(projectId: pid, source: SourceFile(name: 'c.vcf.gz', path: await env.sourceFile('c.vcf.gz')));

    expect(state(), isA<ImportRejected>());
    expect(await env.repo.watchFiles(pid).first, isEmpty);
    expect(await storedFiles(pid), isEmpty);
  });

  test('arquivo parcialmente válido é aceito', () async {
    env = await TestEnv.create(core: FakeGenozCore(reportJson: fixture('report_partial.json')));
    final pid = await project();
    await controller().importFile(projectId: pid, source: SourceFile(name: 'p.vcf', path: await env.sourceFile('p.vcf')));
    expect(state(), isA<ImportSucceeded>());
  });

  test('mesmo conteúdo duas vezes é detectado pelo SHA-256', () async {
    env = await TestEnv.create();
    final pid = await project();
    final src = await env.sourceFile('a.vcf');
    await controller().importFile(projectId: pid, source: SourceFile(name: 'a.vcf', path: src));
    controller().acknowledge();
    await controller().importFile(projectId: pid, source: SourceFile(name: 'copia.vcf', path: src));

    expect(state(), isA<ImportDuplicate>());
    expect(await env.repo.watchFiles(pid).first, hasLength(1));
    expect(await storedFiles(pid), hasLength(1));
  });

  test('falha do núcleo vira mensagem e nada é gravado', () async {
    env = await TestEnv.create(core: FakeGenozCore(failWith: 'cabeçalho VCF inválido: linha #CHROM não encontrada'));
    final pid = await project();
    await controller().importFile(projectId: pid, source: SourceFile(name: 'x.txt', path: await env.sourceFile('x.txt')));

    expect((state() as ImportError).message, contains('#CHROM'));
    expect(await storedFiles(pid), isEmpty);
  });

  test('cancelar interrompe e limpa', () async {
    env = await TestEnv.create(core: FakeGenozCore(reportJson: fixture('report_valid.json'), hold: true));
    final pid = await project();
    final running = controller().importFile(projectId: pid, source: SourceFile(name: 'g.vcf', path: await env.sourceFile('g.vcf')));
    await pumpEventQueue();
    expect(state(), isA<ImportRunning>());
    controller().cancel();
    await running;

    expect(state(), isA<ImportWasCancelled>());
    expect(await env.repo.watchFiles(pid).first, isEmpty);
    expect(await storedFiles(pid), isEmpty);
  });

  test('fluxo de bytes (content:// no Android) grava direto no destino', () async {
    env = await TestEnv.create();
    final pid = await project();
    await controller().importFile(
      projectId: pid,
      source: SourceFile(
        name: 'nuvem.vcf',
        open: () => Stream.fromIterable([
          '##fileformat=VCFv4.3\n'.codeUnits,
          '#CHROM\tPOS\n'.codeUnits,
        ]),
        size: 33,
      ),
    );
    expect(state(), isA<ImportSucceeded>());
    final stored = (await env.repo.watchFiles(pid).first).single;
    expect(await File(env.storage.absolute(stored.storedPath)).readAsString(), startsWith('##fileformat'));
  });
}
