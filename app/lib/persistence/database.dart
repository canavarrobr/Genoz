// Banco local do Genoz (SQLite via Drift).
//
// Guarda somente METADADOS: projetos, arquivos importados e seus relatórios.
// Os arquivos genômicos ficam como arquivos na pasta privada do app
// (ADR-003). Ninguém fora desta pasta `persistence/` sabe que existe SQL.
//
// Para mudar o esquema: altere as tabelas, aumente `schemaVersion` e
// acrescente um passo em `_migrations`. A migração roda sozinha ao abrir.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProjectFiles extends Table {
  TextColumn get id => text()();
  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();

  /// Nome original do arquivo, como o usuário o conhece.
  TextColumn get displayName => text()();

  /// Caminho RELATIVO à pasta de dados do app (o absoluto muda no iOS).
  TextColumn get storedPath => text()();
  TextColumn get sha256 => text()();
  IntColumn get bytes => integer()();
  TextColumn get compression => text()();
  TextColumn get fileFormat => text().nullable()();
  TextColumn get build => text()();
  TextColumn get buildConfidence => text()();
  TextColumn get verdict => text()();
  IntColumn get recordsOk => integer()();
  IntColumn get errors => integer()();
  IntColumn get warnings => integer()();

  /// Lista JSON com os nomes das amostras.
  TextColumn get samplesJson => text()();

  /// Relatório de inspeção completo (JSON produzido pelo núcleo Rust).
  TextColumn get reportJson => text()();
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ---- Esquema v2 (Módulo 4) -------------------------------------------------

/// Uma comparação A × B. Os resultados ficam em arquivos na pasta `resultDir`.
@DataClassName('Analysis')
class Analyses extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileAId => text()();
  TextColumn get fileBId => text()();
  TextColumn get sampleA => text().nullable()();
  TextColumn get sampleB => text().nullable()();

  /// `CompareOptions` do núcleo, em JSON.
  TextColumn get optionsJson => text()();

  /// Pasta RELATIVA com rows.bgz, rows.idx, summary.json, stats_*.json e manifest.json.
  TextColumn get resultDir => text()();
  TextColumn get summaryJson => text()();

  /// ID derivado do conteúdo (manifesto): a mesma análise tem o mesmo ID em qualquer aparelho.
  TextColumn get contentId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Filtros de tabela salvos (`RowFilter` do núcleo, em JSON). Valem para o projeto todo.
class SavedFilters extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get filterJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Nota, etiquetas e favorito de uma variante (chave `chrom:pos:ref:alt`).
class VariantNotes extends Table {
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get variantKey => text()();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Lista JSON de etiquetas.
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {projectId, variantKey};
}

/// Diário automático do projeto: o que foi feito e quando.
class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();

  /// `import`, `compare`, `export`, `filter`, `delete_file`, `delete_analysis`, `note`.
  TextColumn get kind => text()();
  TextColumn get message => text()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Projects, ProjectFiles, Analyses, SavedFilters, VariantNotes, JournalEntries])
class GenozDatabase extends _$GenozDatabase {
  GenozDatabase(super.executor);

  /// Banco padrão do app, no armazenamento privado da plataforma
  /// (no navegador: sqlite3.wasm sobre OPFS/IndexedDB, Módulo 5).
  factory GenozDatabase.open() => GenozDatabase(
    driftDatabase(
      name: 'genoz',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      for (var v = from; v < to; v++) {
        await _upgradeFrom(m, v);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Um passo de migração, a partir da versão `from`.
  /// Ex. futuro: `case 2: await m.addColumn(projectFiles, projectFiles.novaColuna);`
  Future<void> _upgradeFrom(Migrator m, int from) async {
    switch (from) {
      case 1: // v1 → v2 (Módulo 4): análises, filtros salvos, notas e diário.
        await m.createTable(analyses);
        await m.createTable(savedFilters);
        await m.createTable(variantNotes);
        await m.createTable(journalEntries);
    }
  }
}
