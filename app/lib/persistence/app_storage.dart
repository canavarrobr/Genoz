// Pastas privadas do app onde ficam os arquivos genômicos (ADR-003).
//
// Estrutura:  <suporte do app>/projetos/<projeto>/arquivos/<arquivo>.vcf[.gz]
// O banco guarda caminhos RELATIVOS a esta raiz.

import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppStorage {
  AppStorage(this.root);

  final String root;

  static Future<AppStorage> open() async {
    final dir = await getApplicationSupportDirectory();
    return AppStorage(dir.path);
  }

  String projectDir(String projectId) => p.join(root, 'projetos', projectId);

  String absolute(String relative) => p.join(root, relative);

  /// Caminho relativo para um novo arquivo, mantendo a extensão original.
  String newFileRelative(String projectId, String fileId, String originalName) {
    final lower = originalName.toLowerCase();
    final ext = lower.endsWith('.vcf.gz') || lower.endsWith('.vcf.bgz')
        ? '.vcf.gz'
        : lower.endsWith('.gz')
            ? '.gz'
            : '.vcf';
    return p.join('projetos', projectId, 'arquivos', '$fileId$ext');
  }

  /// Pasta relativa dos resultados de uma análise.
  String analysisRelative(String projectId, String analysisId) =>
      p.join('projetos', projectId, 'analises', analysisId);

  /// Pasta relativa das exportações do projeto.
  String exportsRelative(String projectId) => p.join('projetos', projectId, 'exportacoes');

  Future<void> deleteDir(String relative) async {
    final dir = Directory(absolute(relative));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> deleteProjectFiles(String projectId) async {
    final dir = Directory(projectDir(projectId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> deleteFile(String relative) async {
    final f = File(absolute(relative));
    if (await f.exists()) await f.delete();
  }
}

final _random = Random.secure();

/// Identificador aleatório de 128 bits em hexadecimal.
String newId() =>
    List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

/// Definido em `main()` depois de descobrir a pasta do app.
final appStorageProvider = Provider<AppStorage>(
  (ref) => throw UnimplementedError('appStorageProvider precisa ser definido em main()'),
);
