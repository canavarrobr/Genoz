// Família e populações (Módulo 12): rodar a análise e gerar a família fictícia.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/family_models.dart';
import '../../core/genoz_core.dart';
import '../../persistence/analysis_repository.dart';
import '../../persistence/app_storage.dart';
import '../../persistence/database.dart';
import '../../persistence/project_repository.dart';
import '../import/import_controller.dart';

/// Máximo de amostras numa análise (igual ao núcleo).
const familyMaxSamples = 32;

/// Arquivos que servem para Família e populações: VCF com 2+ amostras.
bool isMultiSampleVcf(ProjectFile f) => !f.isChip && !f.isFasta && f.sampleNames.length >= 2;

CompareInputFile familyInput(ProjectFile f) => CompareInputFile(
      relativePath: f.storedPath,
      displayName: f.displayName,
      sha256: f.sha256,
      bytes: f.bytes,
    );

class FamilyActions {
  FamilyActions(this._ref);
  final Ref _ref;

  /// Roda a análise, salva no banco e devolve o ID.
  Future<String> run({
    required String projectId,
    required ProjectFile file,
    required FamilyOptions options,
    required String journalMessage,
  }) async {
    final storage = _ref.read(appStorageProvider);
    final id = newId();
    final dir = storage.analysisRelative(projectId, id);
    try {
      final r = await _ref.read(genozCoreProvider).analyzeFamily(
            input: familyInput(file),
            optionsJson: options.toJsonString(),
            outDirRelative: dir,
            createdAt: DateTime.now().toUtc().toIso8601String(),
          );
      final result = FamilyResult.parse(r.result);
      final repo = _ref.read(analysisRepositoryProvider);
      await repo.addFamilyAnalysis(
        id: id,
        projectId: projectId,
        fileId: file.id,
        optionsJson: options.toJsonString(),
        resultDir: dir,
        sampleCount: result.samples.length,
        hasTrio: result.trio != null,
        manifestJson: r.manifest,
      );
      await repo.log(projectId, 'family', journalMessage);
      return id;
    } catch (_) {
      await storage.deleteDir(dir);
      rethrow;
    }
  }

  /// Gera a família fictícia e a importa no projeto.
  Future<void> importSynthetic(String projectId) async {
    final storage = _ref.read(appStorageProvider);
    final tmp = storage.newFileRelative(projectId, 'tmp_${newId()}', 'x.vcf.gz');
    try {
      await storage.blobs.writeBytes(tmp, await _ref.read(genozCoreProvider).syntheticFamily(2026));
      final native = storage.blobs.nativePath(tmp);
      const name = 'familia_ficticia.vcf.gz';
      await _ref.read(importControllerProvider.notifier).importFile(
            projectId: projectId,
            source: native != null
                ? SourceFile(name: name, path: native)
                : SourceFile(
                    name: name,
                    open: () => Stream.fromFuture(storage.blobs.readBytes(tmp)),
                    size: await storage.blobs.size(tmp),
                  ),
          );
    } finally {
      await storage.deleteFile(tmp);
    }
  }
}

final familyActionsProvider = Provider<FamilyActions>(FamilyActions.new);

final familyResultProvider = FutureProvider.family<FamilyResult?, String>((ref, id) async {
  final a = await ref.watch(familyAnalysisProvider(id).future);
  if (a == null) return null;
  return FamilyResult.parse(await ref.read(appStorageProvider).blobs.readString('${a.resultDir}/familia.json'));
});
