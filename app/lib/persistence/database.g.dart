// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Project copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectFilesTable extends ProjectFiles
    with TableInfo<$ProjectFilesTable, ProjectFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storedPathMeta = const VerificationMeta(
    'storedPath',
  );
  @override
  late final GeneratedColumn<String> storedPath = GeneratedColumn<String>(
    'stored_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _compressionMeta = const VerificationMeta(
    'compression',
  );
  @override
  late final GeneratedColumn<String> compression = GeneratedColumn<String>(
    'compression',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileFormatMeta = const VerificationMeta(
    'fileFormat',
  );
  @override
  late final GeneratedColumn<String> fileFormat = GeneratedColumn<String>(
    'file_format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _buildMeta = const VerificationMeta('build');
  @override
  late final GeneratedColumn<String> build = GeneratedColumn<String>(
    'build',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buildConfidenceMeta = const VerificationMeta(
    'buildConfidence',
  );
  @override
  late final GeneratedColumn<String> buildConfidence = GeneratedColumn<String>(
    'build_confidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verdictMeta = const VerificationMeta(
    'verdict',
  );
  @override
  late final GeneratedColumn<String> verdict = GeneratedColumn<String>(
    'verdict',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordsOkMeta = const VerificationMeta(
    'recordsOk',
  );
  @override
  late final GeneratedColumn<int> recordsOk = GeneratedColumn<int>(
    'records_ok',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorsMeta = const VerificationMeta('errors');
  @override
  late final GeneratedColumn<int> errors = GeneratedColumn<int>(
    'errors',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warningsMeta = const VerificationMeta(
    'warnings',
  );
  @override
  late final GeneratedColumn<int> warnings = GeneratedColumn<int>(
    'warnings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _samplesJsonMeta = const VerificationMeta(
    'samplesJson',
  );
  @override
  late final GeneratedColumn<String> samplesJson = GeneratedColumn<String>(
    'samples_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reportJsonMeta = const VerificationMeta(
    'reportJson',
  );
  @override
  late final GeneratedColumn<String> reportJson = GeneratedColumn<String>(
    'report_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    displayName,
    storedPath,
    sha256,
    bytes,
    compression,
    fileFormat,
    build,
    buildConfidence,
    verdict,
    recordsOk,
    errors,
    warnings,
    samplesJson,
    reportJson,
    importedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('stored_path')) {
      context.handle(
        _storedPathMeta,
        storedPath.isAcceptableOrUnknown(data['stored_path']!, _storedPathMeta),
      );
    } else if (isInserting) {
      context.missing(_storedPathMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('compression')) {
      context.handle(
        _compressionMeta,
        compression.isAcceptableOrUnknown(
          data['compression']!,
          _compressionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_compressionMeta);
    }
    if (data.containsKey('file_format')) {
      context.handle(
        _fileFormatMeta,
        fileFormat.isAcceptableOrUnknown(data['file_format']!, _fileFormatMeta),
      );
    }
    if (data.containsKey('build')) {
      context.handle(
        _buildMeta,
        build.isAcceptableOrUnknown(data['build']!, _buildMeta),
      );
    } else if (isInserting) {
      context.missing(_buildMeta);
    }
    if (data.containsKey('build_confidence')) {
      context.handle(
        _buildConfidenceMeta,
        buildConfidence.isAcceptableOrUnknown(
          data['build_confidence']!,
          _buildConfidenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_buildConfidenceMeta);
    }
    if (data.containsKey('verdict')) {
      context.handle(
        _verdictMeta,
        verdict.isAcceptableOrUnknown(data['verdict']!, _verdictMeta),
      );
    } else if (isInserting) {
      context.missing(_verdictMeta);
    }
    if (data.containsKey('records_ok')) {
      context.handle(
        _recordsOkMeta,
        recordsOk.isAcceptableOrUnknown(data['records_ok']!, _recordsOkMeta),
      );
    } else if (isInserting) {
      context.missing(_recordsOkMeta);
    }
    if (data.containsKey('errors')) {
      context.handle(
        _errorsMeta,
        errors.isAcceptableOrUnknown(data['errors']!, _errorsMeta),
      );
    } else if (isInserting) {
      context.missing(_errorsMeta);
    }
    if (data.containsKey('warnings')) {
      context.handle(
        _warningsMeta,
        warnings.isAcceptableOrUnknown(data['warnings']!, _warningsMeta),
      );
    } else if (isInserting) {
      context.missing(_warningsMeta);
    }
    if (data.containsKey('samples_json')) {
      context.handle(
        _samplesJsonMeta,
        samplesJson.isAcceptableOrUnknown(
          data['samples_json']!,
          _samplesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_samplesJsonMeta);
    }
    if (data.containsKey('report_json')) {
      context.handle(
        _reportJsonMeta,
        reportJson.isAcceptableOrUnknown(data['report_json']!, _reportJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_reportJsonMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      storedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stored_path'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      )!,
      compression: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}compression'],
      )!,
      fileFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_format'],
      ),
      build: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}build'],
      )!,
      buildConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}build_confidence'],
      )!,
      verdict: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verdict'],
      )!,
      recordsOk: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}records_ok'],
      )!,
      errors: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}errors'],
      )!,
      warnings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warnings'],
      )!,
      samplesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}samples_json'],
      )!,
      reportJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_json'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  $ProjectFilesTable createAlias(String alias) {
    return $ProjectFilesTable(attachedDatabase, alias);
  }
}

class ProjectFile extends DataClass implements Insertable<ProjectFile> {
  final String id;
  final String projectId;

  /// Nome original do arquivo, como o usuário o conhece.
  final String displayName;

  /// Caminho RELATIVO à pasta de dados do app (o absoluto muda no iOS).
  final String storedPath;
  final String sha256;
  final int bytes;
  final String compression;
  final String? fileFormat;
  final String build;
  final String buildConfidence;
  final String verdict;
  final int recordsOk;
  final int errors;
  final int warnings;

  /// Lista JSON com os nomes das amostras.
  final String samplesJson;

  /// Relatório de inspeção completo (JSON produzido pelo núcleo Rust).
  final String reportJson;
  final DateTime importedAt;
  const ProjectFile({
    required this.id,
    required this.projectId,
    required this.displayName,
    required this.storedPath,
    required this.sha256,
    required this.bytes,
    required this.compression,
    this.fileFormat,
    required this.build,
    required this.buildConfidence,
    required this.verdict,
    required this.recordsOk,
    required this.errors,
    required this.warnings,
    required this.samplesJson,
    required this.reportJson,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['display_name'] = Variable<String>(displayName);
    map['stored_path'] = Variable<String>(storedPath);
    map['sha256'] = Variable<String>(sha256);
    map['bytes'] = Variable<int>(bytes);
    map['compression'] = Variable<String>(compression);
    if (!nullToAbsent || fileFormat != null) {
      map['file_format'] = Variable<String>(fileFormat);
    }
    map['build'] = Variable<String>(build);
    map['build_confidence'] = Variable<String>(buildConfidence);
    map['verdict'] = Variable<String>(verdict);
    map['records_ok'] = Variable<int>(recordsOk);
    map['errors'] = Variable<int>(errors);
    map['warnings'] = Variable<int>(warnings);
    map['samples_json'] = Variable<String>(samplesJson);
    map['report_json'] = Variable<String>(reportJson);
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  ProjectFilesCompanion toCompanion(bool nullToAbsent) {
    return ProjectFilesCompanion(
      id: Value(id),
      projectId: Value(projectId),
      displayName: Value(displayName),
      storedPath: Value(storedPath),
      sha256: Value(sha256),
      bytes: Value(bytes),
      compression: Value(compression),
      fileFormat: fileFormat == null && nullToAbsent
          ? const Value.absent()
          : Value(fileFormat),
      build: Value(build),
      buildConfidence: Value(buildConfidence),
      verdict: Value(verdict),
      recordsOk: Value(recordsOk),
      errors: Value(errors),
      warnings: Value(warnings),
      samplesJson: Value(samplesJson),
      reportJson: Value(reportJson),
      importedAt: Value(importedAt),
    );
  }

  factory ProjectFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectFile(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      storedPath: serializer.fromJson<String>(json['storedPath']),
      sha256: serializer.fromJson<String>(json['sha256']),
      bytes: serializer.fromJson<int>(json['bytes']),
      compression: serializer.fromJson<String>(json['compression']),
      fileFormat: serializer.fromJson<String?>(json['fileFormat']),
      build: serializer.fromJson<String>(json['build']),
      buildConfidence: serializer.fromJson<String>(json['buildConfidence']),
      verdict: serializer.fromJson<String>(json['verdict']),
      recordsOk: serializer.fromJson<int>(json['recordsOk']),
      errors: serializer.fromJson<int>(json['errors']),
      warnings: serializer.fromJson<int>(json['warnings']),
      samplesJson: serializer.fromJson<String>(json['samplesJson']),
      reportJson: serializer.fromJson<String>(json['reportJson']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'displayName': serializer.toJson<String>(displayName),
      'storedPath': serializer.toJson<String>(storedPath),
      'sha256': serializer.toJson<String>(sha256),
      'bytes': serializer.toJson<int>(bytes),
      'compression': serializer.toJson<String>(compression),
      'fileFormat': serializer.toJson<String?>(fileFormat),
      'build': serializer.toJson<String>(build),
      'buildConfidence': serializer.toJson<String>(buildConfidence),
      'verdict': serializer.toJson<String>(verdict),
      'recordsOk': serializer.toJson<int>(recordsOk),
      'errors': serializer.toJson<int>(errors),
      'warnings': serializer.toJson<int>(warnings),
      'samplesJson': serializer.toJson<String>(samplesJson),
      'reportJson': serializer.toJson<String>(reportJson),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  ProjectFile copyWith({
    String? id,
    String? projectId,
    String? displayName,
    String? storedPath,
    String? sha256,
    int? bytes,
    String? compression,
    Value<String?> fileFormat = const Value.absent(),
    String? build,
    String? buildConfidence,
    String? verdict,
    int? recordsOk,
    int? errors,
    int? warnings,
    String? samplesJson,
    String? reportJson,
    DateTime? importedAt,
  }) => ProjectFile(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    displayName: displayName ?? this.displayName,
    storedPath: storedPath ?? this.storedPath,
    sha256: sha256 ?? this.sha256,
    bytes: bytes ?? this.bytes,
    compression: compression ?? this.compression,
    fileFormat: fileFormat.present ? fileFormat.value : this.fileFormat,
    build: build ?? this.build,
    buildConfidence: buildConfidence ?? this.buildConfidence,
    verdict: verdict ?? this.verdict,
    recordsOk: recordsOk ?? this.recordsOk,
    errors: errors ?? this.errors,
    warnings: warnings ?? this.warnings,
    samplesJson: samplesJson ?? this.samplesJson,
    reportJson: reportJson ?? this.reportJson,
    importedAt: importedAt ?? this.importedAt,
  );
  ProjectFile copyWithCompanion(ProjectFilesCompanion data) {
    return ProjectFile(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      storedPath: data.storedPath.present
          ? data.storedPath.value
          : this.storedPath,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      compression: data.compression.present
          ? data.compression.value
          : this.compression,
      fileFormat: data.fileFormat.present
          ? data.fileFormat.value
          : this.fileFormat,
      build: data.build.present ? data.build.value : this.build,
      buildConfidence: data.buildConfidence.present
          ? data.buildConfidence.value
          : this.buildConfidence,
      verdict: data.verdict.present ? data.verdict.value : this.verdict,
      recordsOk: data.recordsOk.present ? data.recordsOk.value : this.recordsOk,
      errors: data.errors.present ? data.errors.value : this.errors,
      warnings: data.warnings.present ? data.warnings.value : this.warnings,
      samplesJson: data.samplesJson.present
          ? data.samplesJson.value
          : this.samplesJson,
      reportJson: data.reportJson.present
          ? data.reportJson.value
          : this.reportJson,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectFile(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('displayName: $displayName, ')
          ..write('storedPath: $storedPath, ')
          ..write('sha256: $sha256, ')
          ..write('bytes: $bytes, ')
          ..write('compression: $compression, ')
          ..write('fileFormat: $fileFormat, ')
          ..write('build: $build, ')
          ..write('buildConfidence: $buildConfidence, ')
          ..write('verdict: $verdict, ')
          ..write('recordsOk: $recordsOk, ')
          ..write('errors: $errors, ')
          ..write('warnings: $warnings, ')
          ..write('samplesJson: $samplesJson, ')
          ..write('reportJson: $reportJson, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    displayName,
    storedPath,
    sha256,
    bytes,
    compression,
    fileFormat,
    build,
    buildConfidence,
    verdict,
    recordsOk,
    errors,
    warnings,
    samplesJson,
    reportJson,
    importedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectFile &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.displayName == this.displayName &&
          other.storedPath == this.storedPath &&
          other.sha256 == this.sha256 &&
          other.bytes == this.bytes &&
          other.compression == this.compression &&
          other.fileFormat == this.fileFormat &&
          other.build == this.build &&
          other.buildConfidence == this.buildConfidence &&
          other.verdict == this.verdict &&
          other.recordsOk == this.recordsOk &&
          other.errors == this.errors &&
          other.warnings == this.warnings &&
          other.samplesJson == this.samplesJson &&
          other.reportJson == this.reportJson &&
          other.importedAt == this.importedAt);
}

class ProjectFilesCompanion extends UpdateCompanion<ProjectFile> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> displayName;
  final Value<String> storedPath;
  final Value<String> sha256;
  final Value<int> bytes;
  final Value<String> compression;
  final Value<String?> fileFormat;
  final Value<String> build;
  final Value<String> buildConfidence;
  final Value<String> verdict;
  final Value<int> recordsOk;
  final Value<int> errors;
  final Value<int> warnings;
  final Value<String> samplesJson;
  final Value<String> reportJson;
  final Value<DateTime> importedAt;
  final Value<int> rowid;
  const ProjectFilesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.storedPath = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.bytes = const Value.absent(),
    this.compression = const Value.absent(),
    this.fileFormat = const Value.absent(),
    this.build = const Value.absent(),
    this.buildConfidence = const Value.absent(),
    this.verdict = const Value.absent(),
    this.recordsOk = const Value.absent(),
    this.errors = const Value.absent(),
    this.warnings = const Value.absent(),
    this.samplesJson = const Value.absent(),
    this.reportJson = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectFilesCompanion.insert({
    required String id,
    required String projectId,
    required String displayName,
    required String storedPath,
    required String sha256,
    required int bytes,
    required String compression,
    this.fileFormat = const Value.absent(),
    required String build,
    required String buildConfidence,
    required String verdict,
    required int recordsOk,
    required int errors,
    required int warnings,
    required String samplesJson,
    required String reportJson,
    required DateTime importedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       displayName = Value(displayName),
       storedPath = Value(storedPath),
       sha256 = Value(sha256),
       bytes = Value(bytes),
       compression = Value(compression),
       build = Value(build),
       buildConfidence = Value(buildConfidence),
       verdict = Value(verdict),
       recordsOk = Value(recordsOk),
       errors = Value(errors),
       warnings = Value(warnings),
       samplesJson = Value(samplesJson),
       reportJson = Value(reportJson),
       importedAt = Value(importedAt);
  static Insertable<ProjectFile> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? displayName,
    Expression<String>? storedPath,
    Expression<String>? sha256,
    Expression<int>? bytes,
    Expression<String>? compression,
    Expression<String>? fileFormat,
    Expression<String>? build,
    Expression<String>? buildConfidence,
    Expression<String>? verdict,
    Expression<int>? recordsOk,
    Expression<int>? errors,
    Expression<int>? warnings,
    Expression<String>? samplesJson,
    Expression<String>? reportJson,
    Expression<DateTime>? importedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (displayName != null) 'display_name': displayName,
      if (storedPath != null) 'stored_path': storedPath,
      if (sha256 != null) 'sha256': sha256,
      if (bytes != null) 'bytes': bytes,
      if (compression != null) 'compression': compression,
      if (fileFormat != null) 'file_format': fileFormat,
      if (build != null) 'build': build,
      if (buildConfidence != null) 'build_confidence': buildConfidence,
      if (verdict != null) 'verdict': verdict,
      if (recordsOk != null) 'records_ok': recordsOk,
      if (errors != null) 'errors': errors,
      if (warnings != null) 'warnings': warnings,
      if (samplesJson != null) 'samples_json': samplesJson,
      if (reportJson != null) 'report_json': reportJson,
      if (importedAt != null) 'imported_at': importedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectFilesCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? displayName,
    Value<String>? storedPath,
    Value<String>? sha256,
    Value<int>? bytes,
    Value<String>? compression,
    Value<String?>? fileFormat,
    Value<String>? build,
    Value<String>? buildConfidence,
    Value<String>? verdict,
    Value<int>? recordsOk,
    Value<int>? errors,
    Value<int>? warnings,
    Value<String>? samplesJson,
    Value<String>? reportJson,
    Value<DateTime>? importedAt,
    Value<int>? rowid,
  }) {
    return ProjectFilesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      displayName: displayName ?? this.displayName,
      storedPath: storedPath ?? this.storedPath,
      sha256: sha256 ?? this.sha256,
      bytes: bytes ?? this.bytes,
      compression: compression ?? this.compression,
      fileFormat: fileFormat ?? this.fileFormat,
      build: build ?? this.build,
      buildConfidence: buildConfidence ?? this.buildConfidence,
      verdict: verdict ?? this.verdict,
      recordsOk: recordsOk ?? this.recordsOk,
      errors: errors ?? this.errors,
      warnings: warnings ?? this.warnings,
      samplesJson: samplesJson ?? this.samplesJson,
      reportJson: reportJson ?? this.reportJson,
      importedAt: importedAt ?? this.importedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (storedPath.present) {
      map['stored_path'] = Variable<String>(storedPath.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (compression.present) {
      map['compression'] = Variable<String>(compression.value);
    }
    if (fileFormat.present) {
      map['file_format'] = Variable<String>(fileFormat.value);
    }
    if (build.present) {
      map['build'] = Variable<String>(build.value);
    }
    if (buildConfidence.present) {
      map['build_confidence'] = Variable<String>(buildConfidence.value);
    }
    if (verdict.present) {
      map['verdict'] = Variable<String>(verdict.value);
    }
    if (recordsOk.present) {
      map['records_ok'] = Variable<int>(recordsOk.value);
    }
    if (errors.present) {
      map['errors'] = Variable<int>(errors.value);
    }
    if (warnings.present) {
      map['warnings'] = Variable<int>(warnings.value);
    }
    if (samplesJson.present) {
      map['samples_json'] = Variable<String>(samplesJson.value);
    }
    if (reportJson.present) {
      map['report_json'] = Variable<String>(reportJson.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectFilesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('displayName: $displayName, ')
          ..write('storedPath: $storedPath, ')
          ..write('sha256: $sha256, ')
          ..write('bytes: $bytes, ')
          ..write('compression: $compression, ')
          ..write('fileFormat: $fileFormat, ')
          ..write('build: $build, ')
          ..write('buildConfidence: $buildConfidence, ')
          ..write('verdict: $verdict, ')
          ..write('recordsOk: $recordsOk, ')
          ..write('errors: $errors, ')
          ..write('warnings: $warnings, ')
          ..write('samplesJson: $samplesJson, ')
          ..write('reportJson: $reportJson, ')
          ..write('importedAt: $importedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$GenozDatabase extends GeneratedDatabase {
  _$GenozDatabase(QueryExecutor e) : super(e);
  $GenozDatabaseManager get managers => $GenozDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $ProjectFilesTable projectFiles = $ProjectFilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [projects, projectFiles];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('project_files', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$GenozDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProjectFilesTable, List<ProjectFile>>
  _projectFilesRefsTable(_$GenozDatabase db) => MultiTypedResultKey.fromTable(
    db.projectFiles,
    aliasName: 'projects__id__project_files__project_id',
  );

  $$ProjectFilesTableProcessedTableManager get projectFilesRefs {
    final manager = $$ProjectFilesTableTableManager(
      $_db,
      $_db.projectFiles,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_projectFilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$GenozDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> projectFilesRefs(
    Expression<bool> Function($$ProjectFilesTableFilterComposer f) f,
  ) {
    final $$ProjectFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectFiles,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectFilesTableFilterComposer(
            $db: $db,
            $table: $db.projectFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$GenozDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$GenozDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> projectFilesRefs<T extends Object>(
    Expression<T> Function($$ProjectFilesTableAnnotationComposer a) f,
  ) {
    final $$ProjectFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectFiles,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.projectFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$GenozDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, $$ProjectsTableReferences),
          Project,
          PrefetchHooks Function({bool projectFilesRefs})
        > {
  $$ProjectsTableTableManager(_$GenozDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectsTable, Project>(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectFilesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (projectFilesRefs) db.projectFiles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (projectFilesRefs)
                    await $_getPrefetchedData<
                      Project,
                      $ProjectsTable,
                      ProjectFile
                    >(
                      currentTable: table,
                      referencedTable: $$ProjectsTableReferences
                          ._projectFilesRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProjectsTableReferences(
                        db,
                        table,
                        p0,
                      ).projectFilesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.projectId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$GenozDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, $$ProjectsTableReferences),
      Project,
      PrefetchHooks Function({bool projectFilesRefs})
    >;
typedef $$ProjectFilesTableCreateCompanionBuilder =
    ProjectFilesCompanion Function({
      required String id,
      required String projectId,
      required String displayName,
      required String storedPath,
      required String sha256,
      required int bytes,
      required String compression,
      Value<String?> fileFormat,
      required String build,
      required String buildConfidence,
      required String verdict,
      required int recordsOk,
      required int errors,
      required int warnings,
      required String samplesJson,
      required String reportJson,
      required DateTime importedAt,
      Value<int> rowid,
    });
typedef $$ProjectFilesTableUpdateCompanionBuilder =
    ProjectFilesCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> displayName,
      Value<String> storedPath,
      Value<String> sha256,
      Value<int> bytes,
      Value<String> compression,
      Value<String?> fileFormat,
      Value<String> build,
      Value<String> buildConfidence,
      Value<String> verdict,
      Value<int> recordsOk,
      Value<int> errors,
      Value<int> warnings,
      Value<String> samplesJson,
      Value<String> reportJson,
      Value<DateTime> importedAt,
      Value<int> rowid,
    });

final class $$ProjectFilesTableReferences
    extends BaseReferences<_$GenozDatabase, $ProjectFilesTable, ProjectFile> {
  $$ProjectFilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$GenozDatabase db) =>
      db.projects.createAlias('project_files__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProjectFilesTableFilterComposer
    extends Composer<_$GenozDatabase, $ProjectFilesTable> {
  $$ProjectFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storedPath => $composableBuilder(
    column: $table.storedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get compression => $composableBuilder(
    column: $table.compression,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileFormat => $composableBuilder(
    column: $table.fileFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get build => $composableBuilder(
    column: $table.build,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get buildConfidence => $composableBuilder(
    column: $table.buildConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verdict => $composableBuilder(
    column: $table.verdict,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordsOk => $composableBuilder(
    column: $table.recordsOk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get errors => $composableBuilder(
    column: $table.errors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warnings => $composableBuilder(
    column: $table.warnings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get samplesJson => $composableBuilder(
    column: $table.samplesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportJson => $composableBuilder(
    column: $table.reportJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectFilesTableOrderingComposer
    extends Composer<_$GenozDatabase, $ProjectFilesTable> {
  $$ProjectFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storedPath => $composableBuilder(
    column: $table.storedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get compression => $composableBuilder(
    column: $table.compression,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileFormat => $composableBuilder(
    column: $table.fileFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get build => $composableBuilder(
    column: $table.build,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get buildConfidence => $composableBuilder(
    column: $table.buildConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verdict => $composableBuilder(
    column: $table.verdict,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordsOk => $composableBuilder(
    column: $table.recordsOk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get errors => $composableBuilder(
    column: $table.errors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warnings => $composableBuilder(
    column: $table.warnings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get samplesJson => $composableBuilder(
    column: $table.samplesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportJson => $composableBuilder(
    column: $table.reportJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectFilesTableAnnotationComposer
    extends Composer<_$GenozDatabase, $ProjectFilesTable> {
  $$ProjectFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storedPath => $composableBuilder(
    column: $table.storedPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get compression => $composableBuilder(
    column: $table.compression,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileFormat => $composableBuilder(
    column: $table.fileFormat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get build =>
      $composableBuilder(column: $table.build, builder: (column) => column);

  GeneratedColumn<String> get buildConfidence => $composableBuilder(
    column: $table.buildConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verdict =>
      $composableBuilder(column: $table.verdict, builder: (column) => column);

  GeneratedColumn<int> get recordsOk =>
      $composableBuilder(column: $table.recordsOk, builder: (column) => column);

  GeneratedColumn<int> get errors =>
      $composableBuilder(column: $table.errors, builder: (column) => column);

  GeneratedColumn<int> get warnings =>
      $composableBuilder(column: $table.warnings, builder: (column) => column);

  GeneratedColumn<String> get samplesJson => $composableBuilder(
    column: $table.samplesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reportJson => $composableBuilder(
    column: $table.reportJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectFilesTableTableManager
    extends
        RootTableManager<
          _$GenozDatabase,
          $ProjectFilesTable,
          ProjectFile,
          $$ProjectFilesTableFilterComposer,
          $$ProjectFilesTableOrderingComposer,
          $$ProjectFilesTableAnnotationComposer,
          $$ProjectFilesTableCreateCompanionBuilder,
          $$ProjectFilesTableUpdateCompanionBuilder,
          (ProjectFile, $$ProjectFilesTableReferences),
          ProjectFile,
          PrefetchHooks Function({bool projectId})
        > {
  $$ProjectFilesTableTableManager(_$GenozDatabase db, $ProjectFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> storedPath = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> bytes = const Value.absent(),
                Value<String> compression = const Value.absent(),
                Value<String?> fileFormat = const Value.absent(),
                Value<String> build = const Value.absent(),
                Value<String> buildConfidence = const Value.absent(),
                Value<String> verdict = const Value.absent(),
                Value<int> recordsOk = const Value.absent(),
                Value<int> errors = const Value.absent(),
                Value<int> warnings = const Value.absent(),
                Value<String> samplesJson = const Value.absent(),
                Value<String> reportJson = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectFilesCompanion(
                id: id,
                projectId: projectId,
                displayName: displayName,
                storedPath: storedPath,
                sha256: sha256,
                bytes: bytes,
                compression: compression,
                fileFormat: fileFormat,
                build: build,
                buildConfidence: buildConfidence,
                verdict: verdict,
                recordsOk: recordsOk,
                errors: errors,
                warnings: warnings,
                samplesJson: samplesJson,
                reportJson: reportJson,
                importedAt: importedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String displayName,
                required String storedPath,
                required String sha256,
                required int bytes,
                required String compression,
                Value<String?> fileFormat = const Value.absent(),
                required String build,
                required String buildConfidence,
                required String verdict,
                required int recordsOk,
                required int errors,
                required int warnings,
                required String samplesJson,
                required String reportJson,
                required DateTime importedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProjectFilesCompanion.insert(
                id: id,
                projectId: projectId,
                displayName: displayName,
                storedPath: storedPath,
                sha256: sha256,
                bytes: bytes,
                compression: compression,
                fileFormat: fileFormat,
                build: build,
                buildConfidence: buildConfidence,
                verdict: verdict,
                recordsOk: recordsOk,
                errors: errors,
                warnings: warnings,
                samplesJson: samplesJson,
                reportJson: reportJson,
                importedAt: importedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectFilesTable, ProjectFile>(table),
                  $$ProjectFilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$ProjectFilesTableReferences
                            ._projectIdTable(db),
                        referencedColumn: $$ProjectFilesTableReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProjectFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$GenozDatabase,
      $ProjectFilesTable,
      ProjectFile,
      $$ProjectFilesTableFilterComposer,
      $$ProjectFilesTableOrderingComposer,
      $$ProjectFilesTableAnnotationComposer,
      $$ProjectFilesTableCreateCompanionBuilder,
      $$ProjectFilesTableUpdateCompanionBuilder,
      (ProjectFile, $$ProjectFilesTableReferences),
      ProjectFile,
      PrefetchHooks Function({bool projectId})
    >;

class $GenozDatabaseManager {
  final _$GenozDatabase _db;
  $GenozDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$ProjectFilesTableTableManager get projectFiles =>
      $$ProjectFilesTableTableManager(_db, _db.projectFiles);
}
