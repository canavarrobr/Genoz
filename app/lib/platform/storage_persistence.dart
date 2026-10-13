// Armazenamento persistente do navegador (Módulo 13).
//
// No navegador, o OPFS pode ser apagado pelo próprio navegador se faltar espaço.
// `navigator.storage.persist()` pede que ele não faça isso (API local, sem rede).
// No celular o armazenamento do app já é permanente: `null` = não se aplica.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'storage_persistence_io.dart' if (dart.library.js_interop) 'storage_persistence_web.dart' as impl;

/// `true` concedido, `false` negado, `null` não se aplica (fora do navegador) ou indisponível.
Future<bool?> requestPersistentStorage() => impl.requestPersistentStorage();

final persistentStorageProvider = FutureProvider<bool?>((ref) => requestPersistentStorage());
