// BlobStore para o navegador: OPFS (Origin Private File System).
// Os arquivos ficam no armazenamento privado do site, neste navegador; nada é enviado.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'blob_store.dart';

Future<BlobStore> openPlatformBlobStore() async {
  final root = await web.window.navigator.storage.getDirectory().toDart;
  return OpfsBlobStore(root);
}

class OpfsBlobStore implements BlobStore {
  OpfsBlobStore(this._root);

  final web.FileSystemDirectoryHandle _root;

  List<String> _parts(String relative) =>
      relative.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty && s != '.').toList();

  Future<web.FileSystemDirectoryHandle> _dir(List<String> parts, {required bool create}) async {
    var d = _root;
    for (final name in parts) {
      d = await d.getDirectoryHandle(name, web.FileSystemGetDirectoryOptions(create: create)).toDart;
    }
    return d;
  }

  Future<web.FileSystemFileHandle> _file(String relative, {required bool create}) async {
    final parts = _parts(relative);
    final dir = await _dir(parts.sublist(0, parts.length - 1), create: create);
    return dir.getFileHandle(parts.last, web.FileSystemGetFileOptions(create: create)).toDart;
  }

  @override
  String? nativePath(String relative) => null;

  @override
  Future<int> writeStream(String relative, Stream<List<int>> bytes, {void Function(int written)? onProgress}) async {
    final handle = await _file(relative, create: true);
    final writable = await handle.createWritable().toDart;
    var written = 0;
    try {
      await for (final chunk in bytes) {
        final data = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
        await writable.write(data.toJS).toDart;
        written += data.length;
        onProgress?.call(written);
      }
    } finally {
      await writable.close().toDart;
    }
    return written;
  }

  @override
  Future<void> writeBytes(String relative, Uint8List bytes) => writeStream(relative, Stream.value(bytes));

  @override
  Future<Uint8List> readBytes(String relative) async {
    final file = await (await _file(relative, create: false)).getFile().toDart;
    final buffer = await file.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  }

  @override
  Future<String> readString(String relative) async {
    final file = await (await _file(relative, create: false)).getFile().toDart;
    return (await file.text().toDart).toDart;
  }

  @override
  Future<bool> exists(String relative) async => await size(relative) != null;

  @override
  Future<int?> size(String relative) async {
    try {
      final file = await (await _file(relative, create: false)).getFile().toDart;
      return file.size;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> move(String from, String to) async {
    // O OPFS não tem "renomear" em todos os navegadores: copia e apaga.
    await writeBytes(to, await readBytes(from));
    await deleteFile(from);
  }

  @override
  Future<void> deleteFile(String relative) async {
    final parts = _parts(relative);
    try {
      final dir = await _dir(parts.sublist(0, parts.length - 1), create: false);
      await dir.removeEntry(parts.last).toDart;
    } catch (_) {
      // Já não existe.
    }
  }

  @override
  Future<void> deleteDir(String relative) async {
    final parts = _parts(relative);
    try {
      final parent = await _dir(parts.sublist(0, parts.length - 1), create: false);
      await parent.removeEntry(parts.last, web.FileSystemRemoveOptions(recursive: true)).toDart;
    } catch (_) {
      // Já não existe.
    }
  }
}
