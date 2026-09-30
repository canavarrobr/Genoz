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

@DriftDatabase(tables: [Projects, ProjectFiles])
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      for (var v = from; v < to; v++) {
        await _migrations[v]?.call(m);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Passos de migração: a chave é a versão de ORIGEM.
  /// Ex.: `1: (m) => m.addColumn(projectFiles, projectFiles.novaColuna)`.
  static final Map<int, Future<void> Function(Migrator m)> _migrations = {};
}
