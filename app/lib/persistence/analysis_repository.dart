// Análises, filtros salvos, notas de variantes e diário do projeto.
// Como o ProjectRepository, é a única porta de acesso a essas tabelas.

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/compare_models.dart';
import 'app_storage.dart';
import 'database.dart';
import 'project_repository.dart';

class AnalysisRepository {
  AnalysisRepository(this._db, this._storage);

  final GenozDatabase _db;
  final AppStorage _storage;

  // ---- Diário ----

  Future<void> log(String projectId, String kind, String message) => _db.into(_db.journalEntries).insert(
        JournalEntriesCompanion.insert(projectId: projectId, kind: kind, message: message, createdAt: DateTime.now()),
      );

  Stream<List<JournalEntry>> watchJournal(String projectId) => (_db.select(_db.journalEntries)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([(t) => OrderingTerm.desc(t.id)]))
      .watch();

  // ---- Análises ----

  Future<Analysis> addAnalysis({
    required String id,
    required String projectId,
    required String fileAId,
    required String fileBId,
    required String? sampleA,
    required String? sampleB,
    required String optionsJson,
    required String resultDir,
    required String summaryJson,
    required String manifestJson,
  }) async {
    final contentId = (jsonDecode(manifestJson) as Map<String, dynamic>)['analysis_id'] as String;
    final a = Analysis(
      id: id,
      projectId: projectId,
      fileAId: fileAId,
      fileBId: fileBId,
      sampleA: sampleA,
      sampleB: sampleB,
      optionsJson: optionsJson,
      resultDir: resultDir,
      summaryJson: summaryJson,
      contentId: contentId,
      createdAt: DateTime.now(),
    );
    await _db.into(_db.analyses).insert(a);
    return a;
  }

  Stream<List<Analysis>> watchAnalyses(String projectId) => (_db.select(_db.analyses)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  // ---- Família e populações (Módulo 12) ----

  Future<FamilyAnalysis> addFamilyAnalysis({
    required String id,
    required String projectId,
    required String fileId,
    required String optionsJson,
    required String resultDir,
    required int sampleCount,
    required bool hasTrio,
    required String manifestJson,
  }) async {
    final row = FamilyAnalysis(
      id: id,
      projectId: projectId,
      fileId: fileId,
      optionsJson: optionsJson,
      resultDir: resultDir,
      sampleCount: sampleCount,
      hasTrio: hasTrio,
      contentId: (jsonDecode(manifestJson) as Map<String, dynamic>)['analysis_id'] as String,
      createdAt: DateTime.now(),
    );
    await _db.into(_db.familyAnalyses).insert(row);
    return row;
  }

  Stream<List<FamilyAnalysis>> watchFamilyAnalyses(String projectId) => (_db.select(_db.familyAnalyses)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Future<FamilyAnalysis?> getFamilyAnalysis(String id) =>
      (_db.select(_db.familyAnalyses)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> deleteFamilyAnalysis(FamilyAnalysis a) async {
    await (_db.delete(_db.familyAnalyses)..where((t) => t.id.equals(a.id))).go();
    await _storage.deleteDir(a.resultDir);
  }

  Future<Analysis?> getAnalysis(String id) =>
      (_db.select(_db.analyses)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> deleteAnalysis(Analysis a) async {
    await (_db.delete(_db.analyses)..where((t) => t.id.equals(a.id))).go();
    await _storage.deleteDir(a.resultDir);
  }

  // ---- Filtros salvos ----

  Future<void> saveFilter(String projectId, String name, RowFilter filter) => _db.into(_db.savedFilters).insert(
        SavedFilter(
          id: newId(),
          projectId: projectId,
          name: name.trim(),
          filterJson: filter.toJsonString(),
          createdAt: DateTime.now(),
        ),
      );

  Stream<List<SavedFilter>> watchFilters(String projectId) => (_db.select(_db.savedFilters)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();

  Future<void> deleteFilter(String id) => (_db.delete(_db.savedFilters)..where((t) => t.id.equals(id))).go();

  // ---- Notas, etiquetas e favoritos ----

  Stream<VariantNote?> watchNote(String projectId, String key) => (_db.select(_db.variantNotes)
        ..where((t) => t.projectId.equals(projectId) & t.variantKey.equals(key)))
      .watchSingleOrNull();

  Stream<List<VariantNote>> watchNotes(String projectId) => (_db.select(_db.variantNotes)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  /// Grava nota/etiquetas/favorito. Se tudo ficar vazio, a entrada é removida.
  Future<void> saveNote(String projectId, String key, {required String note, required List<String> tags, required bool favorite}) async {
    final clean = [for (final t in tags) if (t.trim().isNotEmpty) t.trim()];
    if (note.trim().isEmpty && clean.isEmpty && !favorite) {
      await (_db.delete(_db.variantNotes)..where((t) => t.projectId.equals(projectId) & t.variantKey.equals(key))).go();
      return;
    }
    await _db.into(_db.variantNotes).insertOnConflictUpdate(VariantNote(
          projectId: projectId,
          variantKey: key,
          note: note.trim(),
          tagsJson: jsonEncode(clean),
          favorite: favorite,
          updatedAt: DateTime.now(),
        ));
  }
}

extension AnalysisX on Analysis {
  CompareSummary get summary => CompareSummary.parse(summaryJson);
}

extension VariantNoteX on VariantNote {
  List<String> get tags => (jsonDecode(tagsJson) as List).cast<String>();
}

final analysisRepositoryProvider = Provider<AnalysisRepository>(
  (ref) => AnalysisRepository(ref.watch(databaseProvider), ref.watch(appStorageProvider)),
);

final analysesProvider = StreamProvider.family<List<Analysis>, String>(
  (ref, projectId) => ref.watch(analysisRepositoryProvider).watchAnalyses(projectId),
);

final familyAnalysesProvider = StreamProvider.family<List<FamilyAnalysis>, String>(
  (ref, projectId) => ref.watch(analysisRepositoryProvider).watchFamilyAnalyses(projectId),
);

final familyAnalysisProvider = FutureProvider.family<FamilyAnalysis?, String>(
  (ref, id) => ref.watch(analysisRepositoryProvider).getFamilyAnalysis(id),
);

final analysisProvider = FutureProvider.family<Analysis?, String>(
  (ref, id) => ref.watch(analysisRepositoryProvider).getAnalysis(id),
);

final savedFiltersProvider = StreamProvider.family<List<SavedFilter>, String>(
  (ref, projectId) => ref.watch(analysisRepositoryProvider).watchFilters(projectId),
);

final journalProvider = StreamProvider.family<List<JournalEntry>, String>(
  (ref, projectId) => ref.watch(analysisRepositoryProvider).watchJournal(projectId),
);

final notesProvider = StreamProvider.family<List<VariantNote>, String>(
  (ref, projectId) => ref.watch(analysisRepositoryProvider).watchNotes(projectId),
);

final noteProvider = StreamProvider.family<VariantNote?, ({String projectId, String key})>(
  (ref, k) => ref.watch(analysisRepositoryProvider).watchNote(k.projectId, k.key),
);
