// BlobStore para Android/iOS: pasta privada do app (getApplicationSupportDirectory).

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'blob_store.dart';

Future<BlobStore> openPlatformBlobStore() async =>
    IoBlobStore((await getApplicationSupportDirectory()).path);

class IoBlobStore implements BlobStore {
  IoBlobStore(this.root);

  final String root;

  String _abs(String relative) => p.join(root, relative);

  @override
  String? nativePath(String relative) => _abs(relative);

  @override
  Future<int> writeStream(String relative, Stream<List<int>> bytes, {void Function(int written)? onProgress}) async {
    final f = File(_abs(relative));
    await f.parent.create(recursive: true);
    final sink = f.openWrite();
    var written = 0;
    try {
      await for (final chunk in bytes) {
        sink.add(chunk);
        written += chunk.length;
        onProgress?.call(written);
      }
    } finally {
      await sink.close();
    }
    return written;
  }

  @override
  Future<void> writeBytes(String relative, Uint8List bytes) async {
    final f = File(_abs(relative));
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List> readBytes(String relative) => File(_abs(relative)).readAsBytes();

  @override
  Future<String> readString(String relative) => File(_abs(relative)).readAsString();

  @override
  Future<bool> exists(String relative) => File(_abs(relative)).exists();

  @override
  Future<int?> size(String relative) async {
    final f = File(_abs(relative));
    return await f.exists() ? f.length() : null;
  }

  @override
  Future<void> deleteFile(String relative) async {
    final f = File(_abs(relative));
    if (await f.exists()) await f.delete();
  }

  @override
  Future<void> move(String from, String to) async {
    final dest = File(_abs(to));
    await dest.parent.create(recursive: true);
    if (await dest.exists()) await dest.delete();
    await File(_abs(from)).rename(dest.path);
  }

  @override
  Future<void> deleteDir(String relative) async {
    final d = Directory(_abs(relative));
    if (await d.exists()) await d.delete(recursive: true);
  }
}
