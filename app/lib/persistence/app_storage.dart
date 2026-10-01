// Organização dos arquivos do app (ADR-003): genomas e resultados ficam como
// arquivos, no armazenamento da plataforma (pasta privada no celular, OPFS no
// navegador). O banco guarda só caminhos RELATIVOS.
//
// Estrutura:  projetos/<projeto>/arquivos/<arquivo>.vcf[.gz]
//             projetos/<projeto>/analises/<análise>/...
//             projetos/<projeto>/exportacoes/...

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../platform/blob_store.dart';

class AppStorage {
  AppStorage(this.blobs);

  final BlobStore blobs;

  static Future<AppStorage> open() async => AppStorage(await openBlobStore());

  // Caminhos com "/" em todas as plataformas (OPFS não aceita "\").
  static final _posix = p.Context(style: p.Style.posix);

  String projectRelative(String projectId) => _posix.join('projetos', projectId);

  /// Caminho relativo para um novo arquivo, mantendo a extensão original.
  String newFileRelative(String projectId, String fileId, String originalName) {
    final lower = originalName.toLowerCase();
    final ext = lower.endsWith('.vcf.gz') || lower.endsWith('.vcf.bgz')
        ? '.vcf.gz'
        : lower.endsWith('.gz')
            ? '.gz'
            : '.vcf';
    return _posix.join('projetos', projectId, 'arquivos', '$fileId$ext');
  }

  /// Pasta relativa dos resultados de uma análise.
  String analysisRelative(String projectId, String analysisId) =>
      _posix.join('projetos', projectId, 'analises', analysisId);

  /// Pasta relativa das exportações do projeto.
  String exportsRelative(String projectId) => _posix.join('projetos', projectId, 'exportacoes');

  /// Caminho real no disco (só Android/iOS). No navegador não existe caminho.
  String absolute(String relative) =>
      blobs.nativePath(relative) ?? (throw UnsupportedError('caminhos de arquivo não existem no navegador'));

  /// Pasta absoluta do projeto (só Android/iOS; usada em testes).
  String projectDir(String projectId) => absolute(projectRelative(projectId));

  Future<void> deleteDir(String relative) => blobs.deleteDir(relative);

  Future<void> deleteProjectFiles(String projectId) => blobs.deleteDir(projectRelative(projectId));

  Future<void> deleteFile(String relative) => blobs.deleteFile(relative);
}

final _random = Random.secure();

/// Identificador aleatório de 128 bits em hexadecimal.
String newId() => List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

/// Definido em `main()` depois de abrir o armazenamento da plataforma.
final appStorageProvider = Provider<AppStorage>(
  (ref) => throw UnimplementedError('appStorageProvider precisa ser definido em main()'),
);
