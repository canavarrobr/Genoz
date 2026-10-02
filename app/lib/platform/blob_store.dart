// Armazenamento de arquivos do app, independente de plataforma.
//
// - Android/iOS: pasta privada do app (dart:io).
// - Navegador: OPFS (Origin Private File System), privado do site.
//
// Todos os caminhos são RELATIVOS à raiz do armazenamento
// (ex.: `projetos/<id>/arquivos/<arquivo>.vcf.gz`). Nenhuma tela usa dart:io.

import 'dart:typed_data';

import 'blob_store_io.dart' if (dart.library.js_interop) 'blob_store_web.dart' as impl;

abstract interface class BlobStore {
  /// Grava um fluxo de bytes (cria as pastas necessárias). Devolve o total gravado.
  Future<int> writeStream(String relative, Stream<List<int>> bytes, {void Function(int written)? onProgress});

  Future<void> writeBytes(String relative, Uint8List bytes);

  Future<Uint8List> readBytes(String relative);

  Future<String> readString(String relative);

  Future<bool> exists(String relative);

  /// Tamanho em bytes, ou `null` se não existir.
  Future<int?> size(String relative);

  Future<void> deleteFile(String relative);

  Future<void> deleteDir(String relative);

  /// Move um arquivo (cria as pastas do destino; substitui o destino se existir).
  Future<void> move(String from, String to);

  /// Caminho real no disco (só no Android/iOS; `null` no navegador).
  String? nativePath(String relative);
}

/// Abre o armazenamento da plataforma atual.
Future<BlobStore> openBlobStore() => impl.openPlatformBlobStore();
