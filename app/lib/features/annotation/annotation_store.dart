// Pacotes de anotação instalados no aparelho (Módulo 10).
//
// Cada pacote é uma pasta `anotacao/<id>/` (manifest.json, records.bgz, records.idx).
// Os genes do GENCODE vêm embutidos no app e são copiados na primeira vez.
// Pacotes do catálogo são baixados PELO NAVEGADOR DO SISTEMA (o app não tem
// permissão de internet) e só são aceitos se o SHA-256 bater com o do catálogo.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/annotation_models.dart';
import '../../core/genoz_core.dart';
import '../../persistence/app_storage.dart';

const annotationDir = 'anotacao';
const _installedIndex = '$annotationDir/instalados.json';

/// Pacotes que já vêm no app (gerados por `genoz-cli anot build --from gtf`).
const embeddedPackages = ['gencode_v50_grch38', 'gencode_v50_grch37'];
const _packageFiles = ['manifest.json', 'records.bgz', 'records.idx'];

class InstalledPackage {
  const InstalledPackage({required this.dir, required this.manifest, required this.embedded});

  /// Pasta relativa no armazenamento do app.
  final String dir;
  final PackageManifest manifest;
  final bool embedded;
}

final annotationCatalogProvider = FutureProvider<List<CatalogEntry>>((ref) async {
  final j =
      jsonDecode(await rootBundle.loadString('assets/anotacao/catalogo.json', cache: false)) as Map<String, dynamic>;
  return [for (final p in j['packages'] as List) CatalogEntry.fromJson(p as Map<String, dynamic>)];
});

Future<List<String>> _readIndex(AppStorage storage) async {
  if (!await storage.blobs.exists(_installedIndex)) return [];
  return (jsonDecode(await storage.blobs.readString(_installedIndex)) as List).cast<String>();
}

Future<void> _writeIndex(AppStorage storage, List<String> ids) =>
    storage.blobs.writeBytes(_installedIndex, Uint8List.fromList(utf8.encode(jsonEncode(ids))));

/// Copia os pacotes embutidos para o armazenamento (uma vez; de novo depois de "Apagar tudo").
Future<void> ensureEmbedded(AppStorage storage) async {
  for (final id in embeddedPackages) {
    final dir = '$annotationDir/$id';
    if (await storage.blobs.exists('$dir/manifest.json')) continue;
    try {
      // Grava o manifesto por último: pasta sem manifesto = cópia incompleta.
      for (final f in [..._packageFiles.where((f) => f != 'manifest.json'), 'manifest.json']) {
        final data = await rootBundle.load('assets/anotacao/$id/$f');
        await storage.blobs.writeBytes('$dir/$f', data.buffer.asUint8List());
      }
    } on FlutterError {
      // Asset ausente (ex.: testes): segue sem esse pacote.
    }
  }
}

final installedPackagesProvider = FutureProvider<List<InstalledPackage>>((ref) async {
  final storage = ref.read(appStorageProvider);
  await ensureEmbedded(storage);
  final ids = [...embeddedPackages, ...await _readIndex(storage)];
  final out = <InstalledPackage>[];
  for (final id in ids) {
    final dir = '$annotationDir/$id';
    if (!await storage.blobs.exists('$dir/manifest.json')) continue;
    out.add(
      InstalledPackage(
        dir: dir,
        manifest: PackageManifest.parse(await storage.blobs.readString('$dir/manifest.json')),
        embedded: embeddedPackages.contains(id),
      ),
    );
  }
  return out;
});

/// Pastas dos pacotes do mesmo build da análise (anotação de outro build daria posições erradas).
final packagesForBuildProvider = FutureProvider.family<List<InstalledPackage>, String>((ref, build) async {
  final all = await ref.watch(installedPackagesProvider.future);
  return [
    for (final p in all)
      if (p.manifest.build == build) p,
  ];
});

class AnnotationInstallError implements Exception {
  AnnotationInstallError(this.code, [this.detail = '']);

  /// `hash` (SHA-256 não confere) ou `build` (falha do núcleo, em `detail`).
  final String code;
  final String detail;
}

/// Instala um item do catálogo a partir do arquivo que o usuário baixou.
Future<PackageManifest> installFromCatalog(Ref ref, CatalogEntry entry, SourceFile file) async {
  final core = ref.read(genozCoreProvider);
  final sha = await core.sha256Of(file);
  if (sha.toLowerCase() != entry.sha256.toLowerCase()) throw AnnotationInstallError('hash', sha);
  return _install(ref, entry.id, entry.kind, file, {...entry.meta, 'id': entry.id});
}

/// Instala um BED/TSV do próprio usuário.
Future<PackageManifest> installCustom(Ref ref, SourceFile file, {required String name, required String build}) =>
    _install(ref, 'proprio_${newId().substring(0, 12)}', 'custom', file, {
      'name': name,
      'build': build,
      'source': file.name,
      'version': '1',
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'license': '',
    });

Future<PackageManifest> _install(Ref ref, String id, String kind, SourceFile file, Map<String, Object?> meta) async {
  final storage = ref.read(appStorageProvider);
  final core = ref.read(genozCoreProvider);
  final dir = '$annotationDir/$id';
  await storage.blobs.deleteDir(dir);
  core.forgetAnnotation(dir);
  final AnnotBuildResult r;
  try {
    r = await core.buildAnnotation(kind: kind, source: file, outDirRelative: dir, meta: {...meta, 'id': id});
  } catch (e) {
    await storage.blobs.deleteDir(dir);
    throw AnnotationInstallError('build', '$e');
  }
  final ids = await _readIndex(storage);
  if (!ids.contains(id)) await _writeIndex(storage, [...ids, id]);
  ref.invalidate(installedPackagesProvider);
  return r.manifest;
}

Future<void> removePackage(Ref ref, InstalledPackage p) async {
  final storage = ref.read(appStorageProvider);
  ref.read(genozCoreProvider).forgetAnnotation(p.dir);
  await storage.blobs.deleteDir(p.dir);
  final id = p.dir.split('/').last;
  await _writeIndex(storage, [
    for (final x in await _readIndex(storage))
      if (x != id) x,
  ]);
  ref.invalidate(installedPackagesProvider);
}

/// Ações sobre pacotes que precisam de `Ref` (a tela usa `ref.read(annotationActionsProvider)`).
class AnnotationActions {
  AnnotationActions(this._ref);
  final Ref _ref;

  Future<PackageManifest> fromCatalog(CatalogEntry e, SourceFile f) => installFromCatalog(_ref, e, f);
  Future<PackageManifest> custom(SourceFile f, {required String name, required String build}) =>
      installCustom(_ref, f, name: name, build: build);
  Future<void> remove(InstalledPackage p) => removePackage(_ref, p);
}

final annotationActionsProvider = Provider<AnnotationActions>(AnnotationActions.new);
