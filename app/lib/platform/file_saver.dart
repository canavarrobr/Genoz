// "Salvar como" de um arquivo do armazenamento do app.
//
// Android: o sistema pergunta o destino e o arquivo é copiado em fluxo (vários GB sem
// carregar na memória). Navegador e outras plataformas: o seletor de arquivos com os bytes.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../persistence/app_storage.dart';

const _channel = MethodChannel('genoz/arquivos');

/// Devolve `false` se o usuário cancelou.
Future<bool> saveStoredFile(AppStorage storage, String relative, String fileName, {String mime = 'application/octet-stream'}) async {
  final native = storage.blobs.nativePath(relative);
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && native != null) {
    return await _channel.invokeMethod<bool>('salvar', {'caminho': native, 'nome': fileName, 'tipo': mime}) ?? false;
  }
  final saved = await FilePicker.saveFile(fileName: fileName, bytes: await storage.blobs.readBytes(relative));
  // No navegador o download não devolve caminho: considera salvo.
  return kIsWeb || saved != null;
}

/// Bytes pequenos (relatórios): o seletor do sistema basta.
Future<bool> saveBytes(Uint8List bytes, String fileName) async {
  final saved = await FilePicker.saveFile(fileName: fileName, bytes: bytes);
  return kIsWeb || saved != null;
}
