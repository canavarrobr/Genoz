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
  static const VerificationMeta _lockedMeta = const VerificationMeta('locked');
  @override
  late final GeneratedColumn<bool> locked = GeneratedColumn<bool>(
    'locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
    locked,
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
    if (data.containsKey('locked')) {
      context.handle(
        _lockedMeta,
        locked.isAcceptableOrUnknown(data['locked']!, _lockedMeta),
      );
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
      locked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}locked'],
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

  /// Protegido com senha (Módulo 11): os dados estão só no cofre `cofres/<id>.genoz`.
  final bool locked;
  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.locked,
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
    map['locked'] = Variable<bool>(locked);
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
      locked: Value(locked),
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
      locked: serializer.fromJson<bool>(json['locked']),
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
      'locked': serializer.toJson<bool>(locked),
    };
  }

  Project copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? locked,
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    locked: locked ?? this.locked,
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
      locked: data.locked.present ? data.locked.value : this.locked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('locked: $locked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, createdAt, updatedAt, locked);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.locked == this.locked);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> locked;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.locked = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.locked = const Value.absent(),
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
    Expression<bool>? locked,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (locked != null) 'locked': locked,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? locked,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locked: locked ?? this.locked,
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
    if (locked.present) {
      map['locked'] = Variable<bool>(locked.value);
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
          ..write('locked: $locked, ')
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

class $AnalysesTable extends Analyses with TableInfo<$AnalysesTable, Analysis> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalysesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _fileAIdMeta = const VerificationMeta(
    'fileAId',
  );
  @override
  late final GeneratedColumn<String> fileAId = GeneratedColumn<String>(
    'file_a_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileBIdMeta = const VerificationMeta(
    'fileBId',
  );
  @override
  late final GeneratedColumn<String> fileBId = GeneratedColumn<String>(
    'file_b_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleAMeta = const VerificationMeta(
    'sampleA',
  );
  @override
  late final GeneratedColumn<String> sampleA = GeneratedColumn<String>(
    'sample_a',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sampleBMeta = const VerificationMeta(
    'sampleB',
  );
  @override
  late final GeneratedColumn<String> sampleB = GeneratedColumn<String>(
    'sample_b',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultDirMeta = const VerificationMeta(
    'resultDir',
  );
  @override
  late final GeneratedColumn<String> resultDir = GeneratedColumn<String>(
    'result_dir',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryJsonMeta = const VerificationMeta(
    'summaryJson',
  );
  @override
  late final GeneratedColumn<String> summaryJson = GeneratedColumn<String>(
    'summary_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentIdMeta = const VerificationMeta(
    'contentId',
  );
  @override
  late final GeneratedColumn<String> contentId = GeneratedColumn<String>(
    'content_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    fileAId,
    fileBId,
    sampleA,
    sampleB,
    optionsJson,
    resultDir,
    summaryJson,
    contentId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analyses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Analysis> instance, {
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
    if (data.containsKey('file_a_id')) {
      context.handle(
        _fileAIdMeta,
        fileAId.isAcceptableOrUnknown(data['file_a_id']!, _fileAIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileAIdMeta);
    }
    if (data.containsKey('file_b_id')) {
      context.handle(
        _fileBIdMeta,
        fileBId.isAcceptableOrUnknown(data['file_b_id']!, _fileBIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileBIdMeta);
    }
    if (data.containsKey('sample_a')) {
      context.handle(
        _sampleAMeta,
        sampleA.isAcceptableOrUnknown(data['sample_a']!, _sampleAMeta),
      );
    }
    if (data.containsKey('sample_b')) {
      context.handle(
        _sampleBMeta,
        sampleB.isAcceptableOrUnknown(data['sample_b']!, _sampleBMeta),
      );
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_optionsJsonMeta);
    }
    if (data.containsKey('result_dir')) {
      context.handle(
        _resultDirMeta,
        resultDir.isAcceptableOrUnknown(data['result_dir']!, _resultDirMeta),
      );
    } else if (isInserting) {
      context.missing(_resultDirMeta);
    }
    if (data.containsKey('summary_json')) {
      context.handle(
        _summaryJsonMeta,
        summaryJson.isAcceptableOrUnknown(
          data['summary_json']!,
          _summaryJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_summaryJsonMeta);
    }
    if (data.containsKey('content_id')) {
      context.handle(
        _contentIdMeta,
        contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Analysis map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Analysis(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      fileAId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_a_id'],
      )!,
      fileBId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_b_id'],
      )!,
      sampleA: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sample_a'],
      ),
      sampleB: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sample_b'],
      ),
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
      resultDir: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_dir'],
      )!,
      summaryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_json'],
      )!,
      contentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AnalysesTable createAlias(String alias) {
    return $AnalysesTable(attachedDatabase, alias);
  }
}

class Analysis extends DataClass implements Insertable<Analysis> {
  final String id;
  final String projectId;
  final String fileAId;
  final String fileBId;
  final String? sampleA;
  final String? sampleB;

  /// `CompareOptions` do núcleo, em JSON.
  final String optionsJson;

  /// Pasta RELATIVA com rows.bgz, rows.idx, summary.json, stats_*.json e manifest.json.
  final String resultDir;
  final String summaryJson;

  /// ID derivado do conteúdo (manifesto): a mesma análise tem o mesmo ID em qualquer aparelho.
  final String contentId;
  final DateTime createdAt;
  const Analysis({
    required this.id,
    required this.projectId,
    required this.fileAId,
    required this.fileBId,
    this.sampleA,
    this.sampleB,
    required this.optionsJson,
    required this.resultDir,
    required this.summaryJson,
    required this.contentId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['file_a_id'] = Variable<String>(fileAId);
    map['file_b_id'] = Variable<String>(fileBId);
    if (!nullToAbsent || sampleA != null) {
      map['sample_a'] = Variable<String>(sampleA);
    }
    if (!nullToAbsent || sampleB != null) {
      map['sample_b'] = Variable<String>(sampleB);
    }
    map['options_json'] = Variable<String>(optionsJson);
    map['result_dir'] = Variable<String>(resultDir);
    map['summary_json'] = Variable<String>(summaryJson);
    map['content_id'] = Variable<String>(contentId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnalysesCompanion toCompanion(bool nullToAbsent) {
    return AnalysesCompanion(
      id: Value(id),
      projectId: Value(projectId),
      fileAId: Value(fileAId),
      fileBId: Value(fileBId),
      sampleA: sampleA == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleA),
      sampleB: sampleB == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleB),
      optionsJson: Value(optionsJson),
      resultDir: Value(resultDir),
      summaryJson: Value(summaryJson),
      contentId: Value(contentId),
      createdAt: Value(createdAt),
    );
  }

  factory Analysis.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Analysis(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      fileAId: serializer.fromJson<String>(json['fileAId']),
      fileBId: serializer.fromJson<String>(json['fileBId']),
      sampleA: serializer.fromJson<String?>(json['sampleA']),
      sampleB: serializer.fromJson<String?>(json['sampleB']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      resultDir: serializer.fromJson<String>(json['resultDir']),
      summaryJson: serializer.fromJson<String>(json['summaryJson']),
      contentId: serializer.fromJson<String>(json['contentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'fileAId': serializer.toJson<String>(fileAId),
      'fileBId': serializer.toJson<String>(fileBId),
      'sampleA': serializer.toJson<String?>(sampleA),
      'sampleB': serializer.toJson<String?>(sampleB),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'resultDir': serializer.toJson<String>(resultDir),
      'summaryJson': serializer.toJson<String>(summaryJson),
      'contentId': serializer.toJson<String>(contentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Analysis copyWith({
    String? id,
    String? projectId,
    String? fileAId,
    String? fileBId,
    Value<String?> sampleA = const Value.absent(),
    Value<String?> sampleB = const Value.absent(),
    String? optionsJson,
    String? resultDir,
    String? summaryJson,
    String? contentId,
    DateTime? createdAt,
  }) => Analysis(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    fileAId: fileAId ?? this.fileAId,
    fileBId: fileBId ?? this.fileBId,
    sampleA: sampleA.present ? sampleA.value : this.sampleA,
    sampleB: sampleB.present ? sampleB.value : this.sampleB,
    optionsJson: optionsJson ?? this.optionsJson,
    resultDir: resultDir ?? this.resultDir,
    summaryJson: summaryJson ?? this.summaryJson,
    contentId: contentId ?? this.contentId,
    createdAt: createdAt ?? this.createdAt,
  );
  Analysis copyWithCompanion(AnalysesCompanion data) {
    return Analysis(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      fileAId: data.fileAId.present ? data.fileAId.value : this.fileAId,
      fileBId: data.fileBId.present ? data.fileBId.value : this.fileBId,
      sampleA: data.sampleA.present ? data.sampleA.value : this.sampleA,
      sampleB: data.sampleB.present ? data.sampleB.value : this.sampleB,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      resultDir: data.resultDir.present ? data.resultDir.value : this.resultDir,
      summaryJson: data.summaryJson.present
          ? data.summaryJson.value
          : this.summaryJson,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Analysis(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('fileAId: $fileAId, ')
          ..write('fileBId: $fileBId, ')
          ..write('sampleA: $sampleA, ')
          ..write('sampleB: $sampleB, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('resultDir: $resultDir, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('contentId: $contentId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    fileAId,
    fileBId,
    sampleA,
    sampleB,
    optionsJson,
    resultDir,
    summaryJson,
    contentId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Analysis &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.fileAId == this.fileAId &&
          other.fileBId == this.fileBId &&
          other.sampleA == this.sampleA &&
          other.sampleB == this.sampleB &&
          other.optionsJson == this.optionsJson &&
          other.resultDir == this.resultDir &&
          other.summaryJson == this.summaryJson &&
          other.contentId == this.contentId &&
          other.createdAt == this.createdAt);
}

class AnalysesCompanion extends UpdateCompanion<Analysis> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> fileAId;
  final Value<String> fileBId;
  final Value<String?> sampleA;
  final Value<String?> sampleB;
  final Value<String> optionsJson;
  final Value<String> resultDir;
  final Value<String> summaryJson;
  final Value<String> contentId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AnalysesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.fileAId = const Value.absent(),
    this.fileBId = const Value.absent(),
    this.sampleA = const Value.absent(),
    this.sampleB = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.resultDir = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.contentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalysesCompanion.insert({
    required String id,
    required String projectId,
    required String fileAId,
    required String fileBId,
    this.sampleA = const Value.absent(),
    this.sampleB = const Value.absent(),
    required String optionsJson,
    required String resultDir,
    required String summaryJson,
    required String contentId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       fileAId = Value(fileAId),
       fileBId = Value(fileBId),
       optionsJson = Value(optionsJson),
       resultDir = Value(resultDir),
       summaryJson = Value(summaryJson),
       contentId = Value(contentId),
       createdAt = Value(createdAt);
  static Insertable<Analysis> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? fileAId,
    Expression<String>? fileBId,
    Expression<String>? sampleA,
    Expression<String>? sampleB,
    Expression<String>? optionsJson,
    Expression<String>? resultDir,
    Expression<String>? summaryJson,
    Expression<String>? contentId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (fileAId != null) 'file_a_id': fileAId,
      if (fileBId != null) 'file_b_id': fileBId,
      if (sampleA != null) 'sample_a': sampleA,
      if (sampleB != null) 'sample_b': sampleB,
      if (optionsJson != null) 'options_json': optionsJson,
      if (resultDir != null) 'result_dir': resultDir,
      if (summaryJson != null) 'summary_json': summaryJson,
      if (contentId != null) 'content_id': contentId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalysesCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? fileAId,
    Value<String>? fileBId,
    Value<String?>? sampleA,
    Value<String?>? sampleB,
    Value<String>? optionsJson,
    Value<String>? resultDir,
    Value<String>? summaryJson,
    Value<String>? contentId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AnalysesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      fileAId: fileAId ?? this.fileAId,
      fileBId: fileBId ?? this.fileBId,
      sampleA: sampleA ?? this.sampleA,
      sampleB: sampleB ?? this.sampleB,
      optionsJson: optionsJson ?? this.optionsJson,
      resultDir: resultDir ?? this.resultDir,
      summaryJson: summaryJson ?? this.summaryJson,
      contentId: contentId ?? this.contentId,
      createdAt: createdAt ?? this.createdAt,
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
    if (fileAId.present) {
      map['file_a_id'] = Variable<String>(fileAId.value);
    }
    if (fileBId.present) {
      map['file_b_id'] = Variable<String>(fileBId.value);
    }
    if (sampleA.present) {
      map['sample_a'] = Variable<String>(sampleA.value);
    }
    if (sampleB.present) {
      map['sample_b'] = Variable<String>(sampleB.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (resultDir.present) {
      map['result_dir'] = Variable<String>(resultDir.value);
    }
    if (summaryJson.present) {
      map['summary_json'] = Variable<String>(summaryJson.value);
    }
    if (contentId.present) {
      map['content_id'] = Variable<String>(contentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalysesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('fileAId: $fileAId, ')
          ..write('fileBId: $fileBId, ')
          ..write('sampleA: $sampleA, ')
          ..write('sampleB: $sampleB, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('resultDir: $resultDir, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('contentId: $contentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedFiltersTable extends SavedFilters
    with TableInfo<$SavedFiltersTable, SavedFilter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedFiltersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filterJsonMeta = const VerificationMeta(
    'filterJson',
  );
  @override
  late final GeneratedColumn<String> filterJson = GeneratedColumn<String>(
    'filter_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    name,
    filterJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_filters';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedFilter> instance, {
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('filter_json')) {
      context.handle(
        _filterJsonMeta,
        filterJson.isAcceptableOrUnknown(data['filter_json']!, _filterJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_filterJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedFilter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedFilter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      filterJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavedFiltersTable createAlias(String alias) {
    return $SavedFiltersTable(attachedDatabase, alias);
  }
}

class SavedFilter extends DataClass implements Insertable<SavedFilter> {
  final String id;
  final String projectId;
  final String name;
  final String filterJson;
  final DateTime createdAt;
  const SavedFilter({
    required this.id,
    required this.projectId,
    required this.name,
    required this.filterJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['name'] = Variable<String>(name);
    map['filter_json'] = Variable<String>(filterJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SavedFiltersCompanion toCompanion(bool nullToAbsent) {
    return SavedFiltersCompanion(
      id: Value(id),
      projectId: Value(projectId),
      name: Value(name),
      filterJson: Value(filterJson),
      createdAt: Value(createdAt),
    );
  }

  factory SavedFilter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedFilter(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      filterJson: serializer.fromJson<String>(json['filterJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'name': serializer.toJson<String>(name),
      'filterJson': serializer.toJson<String>(filterJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SavedFilter copyWith({
    String? id,
    String? projectId,
    String? name,
    String? filterJson,
    DateTime? createdAt,
  }) => SavedFilter(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    filterJson: filterJson ?? this.filterJson,
    createdAt: createdAt ?? this.createdAt,
  );
  SavedFilter copyWithCompanion(SavedFiltersCompanion data) {
    return SavedFilter(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      filterJson: data.filterJson.present
          ? data.filterJson.value
          : this.filterJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedFilter(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('filterJson: $filterJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, name, filterJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedFilter &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.filterJson == this.filterJson &&
          other.createdAt == this.createdAt);
}

class SavedFiltersCompanion extends UpdateCompanion<SavedFilter> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> name;
  final Value<String> filterJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SavedFiltersCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.filterJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedFiltersCompanion.insert({
    required String id,
    required String projectId,
    required String name,
    required String filterJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       name = Value(name),
       filterJson = Value(filterJson),
       createdAt = Value(createdAt);
  static Insertable<SavedFilter> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? name,
    Expression<String>? filterJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (filterJson != null) 'filter_json': filterJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedFiltersCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? name,
    Value<String>? filterJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SavedFiltersCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      filterJson: filterJson ?? this.filterJson,
      createdAt: createdAt ?? this.createdAt,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (filterJson.present) {
      map['filter_json'] = Variable<String>(filterJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedFiltersCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('filterJson: $filterJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VariantNotesTable extends VariantNotes
    with TableInfo<$VariantNotesTable, VariantNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VariantNotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _variantKeyMeta = const VerificationMeta(
    'variantKey',
  );
  @override
  late final GeneratedColumn<String> variantKey = GeneratedColumn<String>(
    'variant_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    projectId,
    variantKey,
    note,
    tagsJson,
    favorite,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'variant_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<VariantNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('variant_key')) {
      context.handle(
        _variantKeyMeta,
        variantKey.isAcceptableOrUnknown(data['variant_key']!, _variantKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_variantKeyMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {projectId, variantKey};
  @override
  VariantNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VariantNote(
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      variantKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_key'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VariantNotesTable createAlias(String alias) {
    return $VariantNotesTable(attachedDatabase, alias);
  }
}

class VariantNote extends DataClass implements Insertable<VariantNote> {
  final String projectId;
  final String variantKey;
  final String note;

  /// Lista JSON de etiquetas.
  final String tagsJson;
  final bool favorite;
  final DateTime updatedAt;
  const VariantNote({
    required this.projectId,
    required this.variantKey,
    required this.note,
    required this.tagsJson,
    required this.favorite,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['project_id'] = Variable<String>(projectId);
    map['variant_key'] = Variable<String>(variantKey);
    map['note'] = Variable<String>(note);
    map['tags_json'] = Variable<String>(tagsJson);
    map['favorite'] = Variable<bool>(favorite);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VariantNotesCompanion toCompanion(bool nullToAbsent) {
    return VariantNotesCompanion(
      projectId: Value(projectId),
      variantKey: Value(variantKey),
      note: Value(note),
      tagsJson: Value(tagsJson),
      favorite: Value(favorite),
      updatedAt: Value(updatedAt),
    );
  }

  factory VariantNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VariantNote(
      projectId: serializer.fromJson<String>(json['projectId']),
      variantKey: serializer.fromJson<String>(json['variantKey']),
      note: serializer.fromJson<String>(json['note']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'projectId': serializer.toJson<String>(projectId),
      'variantKey': serializer.toJson<String>(variantKey),
      'note': serializer.toJson<String>(note),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'favorite': serializer.toJson<bool>(favorite),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VariantNote copyWith({
    String? projectId,
    String? variantKey,
    String? note,
    String? tagsJson,
    bool? favorite,
    DateTime? updatedAt,
  }) => VariantNote(
    projectId: projectId ?? this.projectId,
    variantKey: variantKey ?? this.variantKey,
    note: note ?? this.note,
    tagsJson: tagsJson ?? this.tagsJson,
    favorite: favorite ?? this.favorite,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VariantNote copyWithCompanion(VariantNotesCompanion data) {
    return VariantNote(
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      variantKey: data.variantKey.present
          ? data.variantKey.value
          : this.variantKey,
      note: data.note.present ? data.note.value : this.note,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VariantNote(')
          ..write('projectId: $projectId, ')
          ..write('variantKey: $variantKey, ')
          ..write('note: $note, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('favorite: $favorite, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(projectId, variantKey, note, tagsJson, favorite, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VariantNote &&
          other.projectId == this.projectId &&
          other.variantKey == this.variantKey &&
          other.note == this.note &&
          other.tagsJson == this.tagsJson &&
          other.favorite == this.favorite &&
          other.updatedAt == this.updatedAt);
}

class VariantNotesCompanion extends UpdateCompanion<VariantNote> {
  final Value<String> projectId;
  final Value<String> variantKey;
  final Value<String> note;
  final Value<String> tagsJson;
  final Value<bool> favorite;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VariantNotesCompanion({
    this.projectId = const Value.absent(),
    this.variantKey = const Value.absent(),
    this.note = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.favorite = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VariantNotesCompanion.insert({
    required String projectId,
    required String variantKey,
    this.note = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.favorite = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : projectId = Value(projectId),
       variantKey = Value(variantKey),
       updatedAt = Value(updatedAt);
  static Insertable<VariantNote> custom({
    Expression<String>? projectId,
    Expression<String>? variantKey,
    Expression<String>? note,
    Expression<String>? tagsJson,
    Expression<bool>? favorite,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (projectId != null) 'project_id': projectId,
      if (variantKey != null) 'variant_key': variantKey,
      if (note != null) 'note': note,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (favorite != null) 'favorite': favorite,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VariantNotesCompanion copyWith({
    Value<String>? projectId,
    Value<String>? variantKey,
    Value<String>? note,
    Value<String>? tagsJson,
    Value<bool>? favorite,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VariantNotesCompanion(
      projectId: projectId ?? this.projectId,
      variantKey: variantKey ?? this.variantKey,
      note: note ?? this.note,
      tagsJson: tagsJson ?? this.tagsJson,
      favorite: favorite ?? this.favorite,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (variantKey.present) {
      map['variant_key'] = Variable<String>(variantKey.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
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
    return (StringBuffer('VariantNotesCompanion(')
          ..write('projectId: $projectId, ')
          ..write('variantKey: $variantKey, ')
          ..write('note: $note, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('favorite: $favorite, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    kind,
    message,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }
}

class JournalEntry extends DataClass implements Insertable<JournalEntry> {
  final int id;
  final String projectId;

  /// `import`, `compare`, `export`, `filter`, `delete_file`, `delete_analysis`, `note`.
  final String kind;
  final String message;
  final DateTime createdAt;
  const JournalEntry({
    required this.id,
    required this.projectId,
    required this.kind,
    required this.message,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<String>(projectId);
    map['kind'] = Variable<String>(kind);
    map['message'] = Variable<String>(message);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      projectId: Value(projectId),
      kind: Value(kind),
      message: Value(message),
      createdAt: Value(createdAt),
    );
  }

  factory JournalEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntry(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      kind: serializer.fromJson<String>(json['kind']),
      message: serializer.fromJson<String>(json['message']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<String>(projectId),
      'kind': serializer.toJson<String>(kind),
      'message': serializer.toJson<String>(message),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  JournalEntry copyWith({
    int? id,
    String? projectId,
    String? kind,
    String? message,
    DateTime? createdAt,
  }) => JournalEntry(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    kind: kind ?? this.kind,
    message: message ?? this.message,
    createdAt: createdAt ?? this.createdAt,
  );
  JournalEntry copyWithCompanion(JournalEntriesCompanion data) {
    return JournalEntry(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      kind: data.kind.present ? data.kind.value : this.kind,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntry(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('kind: $kind, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, kind, message, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntry &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.kind == this.kind &&
          other.message == this.message &&
          other.createdAt == this.createdAt);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntry> {
  final Value<int> id;
  final Value<String> projectId;
  final Value<String> kind;
  final Value<String> message;
  final Value<DateTime> createdAt;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.kind = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String projectId,
    required String kind,
    required String message,
    required DateTime createdAt,
  }) : projectId = Value(projectId),
       kind = Value(kind),
       message = Value(message),
       createdAt = Value(createdAt);
  static Insertable<JournalEntry> custom({
    Expression<int>? id,
    Expression<String>? projectId,
    Expression<String>? kind,
    Expression<String>? message,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (kind != null) 'kind': kind,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? projectId,
    Value<String>? kind,
    Value<String>? message,
    Value<DateTime>? createdAt,
  }) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      kind: kind ?? this.kind,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('kind: $kind, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FamilyAnalysesTable extends FamilyAnalyses
    with TableInfo<$FamilyAnalysesTable, FamilyAnalysis> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyAnalysesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultDirMeta = const VerificationMeta(
    'resultDir',
  );
  @override
  late final GeneratedColumn<String> resultDir = GeneratedColumn<String>(
    'result_dir',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasTrioMeta = const VerificationMeta(
    'hasTrio',
  );
  @override
  late final GeneratedColumn<bool> hasTrio = GeneratedColumn<bool>(
    'has_trio',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_trio" IN (0, 1))',
    ),
  );
  static const VerificationMeta _contentIdMeta = const VerificationMeta(
    'contentId',
  );
  @override
  late final GeneratedColumn<String> contentId = GeneratedColumn<String>(
    'content_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    fileId,
    optionsJson,
    resultDir,
    sampleCount,
    hasTrio,
    contentId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_analyses';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyAnalysis> instance, {
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
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_optionsJsonMeta);
    }
    if (data.containsKey('result_dir')) {
      context.handle(
        _resultDirMeta,
        resultDir.isAcceptableOrUnknown(data['result_dir']!, _resultDirMeta),
      );
    } else if (isInserting) {
      context.missing(_resultDirMeta);
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sampleCountMeta);
    }
    if (data.containsKey('has_trio')) {
      context.handle(
        _hasTrioMeta,
        hasTrio.isAcceptableOrUnknown(data['has_trio']!, _hasTrioMeta),
      );
    } else if (isInserting) {
      context.missing(_hasTrioMeta);
    }
    if (data.containsKey('content_id')) {
      context.handle(
        _contentIdMeta,
        contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyAnalysis map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyAnalysis(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
      resultDir: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_dir'],
      )!,
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
      hasTrio: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_trio'],
      )!,
      contentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FamilyAnalysesTable createAlias(String alias) {
    return $FamilyAnalysesTable(attachedDatabase, alias);
  }
}

class FamilyAnalysis extends DataClass implements Insertable<FamilyAnalysis> {
  final String id;
  final String projectId;
  final String fileId;

  /// `FamilyOptions` do núcleo, em JSON.
  final String optionsJson;
  final String resultDir;
  final int sampleCount;
  final bool hasTrio;
  final String contentId;
  final DateTime createdAt;
  const FamilyAnalysis({
    required this.id,
    required this.projectId,
    required this.fileId,
    required this.optionsJson,
    required this.resultDir,
    required this.sampleCount,
    required this.hasTrio,
    required this.contentId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['file_id'] = Variable<String>(fileId);
    map['options_json'] = Variable<String>(optionsJson);
    map['result_dir'] = Variable<String>(resultDir);
    map['sample_count'] = Variable<int>(sampleCount);
    map['has_trio'] = Variable<bool>(hasTrio);
    map['content_id'] = Variable<String>(contentId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FamilyAnalysesCompanion toCompanion(bool nullToAbsent) {
    return FamilyAnalysesCompanion(
      id: Value(id),
      projectId: Value(projectId),
      fileId: Value(fileId),
      optionsJson: Value(optionsJson),
      resultDir: Value(resultDir),
      sampleCount: Value(sampleCount),
      hasTrio: Value(hasTrio),
      contentId: Value(contentId),
      createdAt: Value(createdAt),
    );
  }

  factory FamilyAnalysis.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyAnalysis(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      fileId: serializer.fromJson<String>(json['fileId']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      resultDir: serializer.fromJson<String>(json['resultDir']),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
      hasTrio: serializer.fromJson<bool>(json['hasTrio']),
      contentId: serializer.fromJson<String>(json['contentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'fileId': serializer.toJson<String>(fileId),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'resultDir': serializer.toJson<String>(resultDir),
      'sampleCount': serializer.toJson<int>(sampleCount),
      'hasTrio': serializer.toJson<bool>(hasTrio),
      'contentId': serializer.toJson<String>(contentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FamilyAnalysis copyWith({
    String? id,
    String? projectId,
    String? fileId,
    String? optionsJson,
    String? resultDir,
    int? sampleCount,
    bool? hasTrio,
    String? contentId,
    DateTime? createdAt,
  }) => FamilyAnalysis(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    fileId: fileId ?? this.fileId,
    optionsJson: optionsJson ?? this.optionsJson,
    resultDir: resultDir ?? this.resultDir,
    sampleCount: sampleCount ?? this.sampleCount,
    hasTrio: hasTrio ?? this.hasTrio,
    contentId: contentId ?? this.contentId,
    createdAt: createdAt ?? this.createdAt,
  );
  FamilyAnalysis copyWithCompanion(FamilyAnalysesCompanion data) {
    return FamilyAnalysis(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      resultDir: data.resultDir.present ? data.resultDir.value : this.resultDir,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
      hasTrio: data.hasTrio.present ? data.hasTrio.value : this.hasTrio,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyAnalysis(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('fileId: $fileId, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('resultDir: $resultDir, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('hasTrio: $hasTrio, ')
          ..write('contentId: $contentId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    fileId,
    optionsJson,
    resultDir,
    sampleCount,
    hasTrio,
    contentId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyAnalysis &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.fileId == this.fileId &&
          other.optionsJson == this.optionsJson &&
          other.resultDir == this.resultDir &&
          other.sampleCount == this.sampleCount &&
          other.hasTrio == this.hasTrio &&
          other.contentId == this.contentId &&
          other.createdAt == this.createdAt);
}

class FamilyAnalysesCompanion extends UpdateCompanion<FamilyAnalysis> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> fileId;
  final Value<String> optionsJson;
  final Value<String> resultDir;
  final Value<int> sampleCount;
  final Value<bool> hasTrio;
  final Value<String> contentId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FamilyAnalysesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.fileId = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.resultDir = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.hasTrio = const Value.absent(),
    this.contentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyAnalysesCompanion.insert({
    required String id,
    required String projectId,
    required String fileId,
    required String optionsJson,
    required String resultDir,
    required int sampleCount,
    required bool hasTrio,
    required String contentId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       fileId = Value(fileId),
       optionsJson = Value(optionsJson),
       resultDir = Value(resultDir),
       sampleCount = Value(sampleCount),
       hasTrio = Value(hasTrio),
       contentId = Value(contentId),
       createdAt = Value(createdAt);
  static Insertable<FamilyAnalysis> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? fileId,
    Expression<String>? optionsJson,
    Expression<String>? resultDir,
    Expression<int>? sampleCount,
    Expression<bool>? hasTrio,
    Expression<String>? contentId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (fileId != null) 'file_id': fileId,
      if (optionsJson != null) 'options_json': optionsJson,
      if (resultDir != null) 'result_dir': resultDir,
      if (sampleCount != null) 'sample_count': sampleCount,
      if (hasTrio != null) 'has_trio': hasTrio,
      if (contentId != null) 'content_id': contentId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyAnalysesCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? fileId,
    Value<String>? optionsJson,
    Value<String>? resultDir,
    Value<int>? sampleCount,
    Value<bool>? hasTrio,
    Value<String>? contentId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FamilyAnalysesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      fileId: fileId ?? this.fileId,
      optionsJson: optionsJson ?? this.optionsJson,
      resultDir: resultDir ?? this.resultDir,
      sampleCount: sampleCount ?? this.sampleCount,
      hasTrio: hasTrio ?? this.hasTrio,
      contentId: contentId ?? this.contentId,
      createdAt: createdAt ?? this.createdAt,
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
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (resultDir.present) {
      map['result_dir'] = Variable<String>(resultDir.value);
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
    }
    if (hasTrio.present) {
      map['has_trio'] = Variable<bool>(hasTrio.value);
    }
    if (contentId.present) {
      map['content_id'] = Variable<String>(contentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyAnalysesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('fileId: $fileId, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('resultDir: $resultDir, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('hasTrio: $hasTrio, ')
          ..write('contentId: $contentId, ')
          ..write('createdAt: $createdAt, ')
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
  late final $AnalysesTable analyses = $AnalysesTable(this);
  late final $SavedFiltersTable savedFilters = $SavedFiltersTable(this);
  late final $VariantNotesTable variantNotes = $VariantNotesTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $FamilyAnalysesTable familyAnalyses = $FamilyAnalysesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    projectFiles,
    analyses,
    savedFilters,
    variantNotes,
    journalEntries,
    familyAnalyses,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('project_files', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('analyses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('saved_filters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('variant_notes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('journal_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('family_analyses', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> locked,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> locked,
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

  static MultiTypedResultKey<$AnalysesTable, List<Analysis>> _analysesRefsTable(
    _$GenozDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.analyses,
    aliasName: 'projects__id__analyses__project_id',
  );

  $$AnalysesTableProcessedTableManager get analysesRefs {
    final manager = $$AnalysesTableTableManager(
      $_db,
      $_db.analyses,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_analysesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SavedFiltersTable, List<SavedFilter>>
  _savedFiltersRefsTable(_$GenozDatabase db) => MultiTypedResultKey.fromTable(
    db.savedFilters,
    aliasName: 'projects__id__saved_filters__project_id',
  );

  $$SavedFiltersTableProcessedTableManager get savedFiltersRefs {
    final manager = $$SavedFiltersTableTableManager(
      $_db,
      $_db.savedFilters,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_savedFiltersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VariantNotesTable, List<VariantNote>>
  _variantNotesRefsTable(_$GenozDatabase db) => MultiTypedResultKey.fromTable(
    db.variantNotes,
    aliasName: 'projects__id__variant_notes__project_id',
  );

  $$VariantNotesTableProcessedTableManager get variantNotesRefs {
    final manager = $$VariantNotesTableTableManager(
      $_db,
      $_db.variantNotes,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_variantNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JournalEntriesTable, List<JournalEntry>>
  _journalEntriesRefsTable(_$GenozDatabase db) => MultiTypedResultKey.fromTable(
    db.journalEntries,
    aliasName: 'projects__id__journal_entries__project_id',
  );

  $$JournalEntriesTableProcessedTableManager get journalEntriesRefs {
    final manager = $$JournalEntriesTableTableManager(
      $_db,
      $_db.journalEntries,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_journalEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FamilyAnalysesTable, List<FamilyAnalysis>>
  _familyAnalysesRefsTable(_$GenozDatabase db) => MultiTypedResultKey.fromTable(
    db.familyAnalyses,
    aliasName: 'projects__id__family_analyses__project_id',
  );

  $$FamilyAnalysesTableProcessedTableManager get familyAnalysesRefs {
    final manager = $$FamilyAnalysesTableTableManager(
      $_db,
      $_db.familyAnalyses,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_familyAnalysesRefsTable($_db));
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

  ColumnFilters<bool> get locked => $composableBuilder(
    column: $table.locked,
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

  Expression<bool> analysesRefs(
    Expression<bool> Function($$AnalysesTableFilterComposer f) f,
  ) {
    final $$AnalysesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.analyses,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnalysesTableFilterComposer(
            $db: $db,
            $table: $db.analyses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> savedFiltersRefs(
    Expression<bool> Function($$SavedFiltersTableFilterComposer f) f,
  ) {
    final $$SavedFiltersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedFilters,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedFiltersTableFilterComposer(
            $db: $db,
            $table: $db.savedFilters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> variantNotesRefs(
    Expression<bool> Function($$VariantNotesTableFilterComposer f) f,
  ) {
    final $$VariantNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.variantNotes,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VariantNotesTableFilterComposer(
            $db: $db,
            $table: $db.variantNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> journalEntriesRefs(
    Expression<bool> Function($$JournalEntriesTableFilterComposer f) f,
  ) {
    final $$JournalEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journalEntries,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JournalEntriesTableFilterComposer(
            $db: $db,
            $table: $db.journalEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> familyAnalysesRefs(
    Expression<bool> Function($$FamilyAnalysesTableFilterComposer f) f,
  ) {
    final $$FamilyAnalysesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familyAnalyses,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyAnalysesTableFilterComposer(
            $db: $db,
            $table: $db.familyAnalyses,
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

  ColumnOrderings<bool> get locked => $composableBuilder(
    column: $table.locked,
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

  GeneratedColumn<bool> get locked =>
      $composableBuilder(column: $table.locked, builder: (column) => column);

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

  Expression<T> analysesRefs<T extends Object>(
    Expression<T> Function($$AnalysesTableAnnotationComposer a) f,
  ) {
    final $$AnalysesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.analyses,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnalysesTableAnnotationComposer(
            $db: $db,
            $table: $db.analyses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> savedFiltersRefs<T extends Object>(
    Expression<T> Function($$SavedFiltersTableAnnotationComposer a) f,
  ) {
    final $$SavedFiltersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedFilters,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedFiltersTableAnnotationComposer(
            $db: $db,
            $table: $db.savedFilters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> variantNotesRefs<T extends Object>(
    Expression<T> Function($$VariantNotesTableAnnotationComposer a) f,
  ) {
    final $$VariantNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.variantNotes,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VariantNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.variantNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> journalEntriesRefs<T extends Object>(
    Expression<T> Function($$JournalEntriesTableAnnotationComposer a) f,
  ) {
    final $$JournalEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journalEntries,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JournalEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.journalEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> familyAnalysesRefs<T extends Object>(
    Expression<T> Function($$FamilyAnalysesTableAnnotationComposer a) f,
  ) {
    final $$FamilyAnalysesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.familyAnalyses,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyAnalysesTableAnnotationComposer(
            $db: $db,
            $table: $db.familyAnalyses,
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
          PrefetchHooks Function({
            bool projectFilesRefs,
            bool analysesRefs,
            bool savedFiltersRefs,
            bool variantNotesRefs,
            bool journalEntriesRefs,
            bool familyAnalysesRefs,
          })
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
                Value<bool> locked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                locked: locked,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> locked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                locked: locked,
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
          prefetchHooksCallback:
              ({
                projectFilesRefs = false,
                analysesRefs = false,
                savedFiltersRefs = false,
                variantNotesRefs = false,
                journalEntriesRefs = false,
                familyAnalysesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (projectFilesRefs) db.projectFiles,
                    if (analysesRefs) db.analyses,
                    if (savedFiltersRefs) db.savedFilters,
                    if (variantNotesRefs) db.variantNotes,
                    if (journalEntriesRefs) db.journalEntries,
                    if (familyAnalysesRefs) db.familyAnalyses,
                  ],
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
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).projectFilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (analysesRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          Analysis
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._analysesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).analysesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (savedFiltersRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          SavedFilter
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._savedFiltersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).savedFiltersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (variantNotesRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          VariantNote
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._variantNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).variantNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (journalEntriesRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          JournalEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._journalEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).journalEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (familyAnalysesRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          FamilyAnalysis
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._familyAnalysesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).familyAnalysesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
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
      PrefetchHooks Function({
        bool projectFilesRefs,
        bool analysesRefs,
        bool savedFiltersRefs,
        bool variantNotesRefs,
        bool journalEntriesRefs,
        bool familyAnalysesRefs,
      })
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
typedef $$AnalysesTableCreateCompanionBuilder = AnalysesCompanion Function({
  required String id,
  required String projectId,
  required String fileAId,
  required String fileBId,
  Value<String?> sampleA,
  Value<String?> sampleB,
  required String optionsJson,
  required String resultDir,
  required String summaryJson,
  required String contentId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$AnalysesTableUpdateCompanionBuilder = AnalysesCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> fileAId,
  Value<String> fileBId,
  Value<String?> sampleA,
  Value<String?> sampleB,
  Value<String> optionsJson,
  Value<String> resultDir,
  Value<String> summaryJson,
  Value<String> contentId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$AnalysesTableReferences
    extends BaseReferences<_$GenozDatabase, $AnalysesTable, Analysis> {
  $$AnalysesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$GenozDatabase db) =>
      db.projects.createAlias('analyses__project_id__projects__id');

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

class $$AnalysesTableFilterComposer
    extends Composer<_$GenozDatabase, $AnalysesTable> {
  $$AnalysesTableFilterComposer({
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

  ColumnFilters<String> get fileAId => $composableBuilder(
    column: $table.fileAId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileBId => $composableBuilder(
    column: $table.fileBId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sampleA => $composableBuilder(
    column: $table.sampleA,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sampleB => $composableBuilder(
    column: $table.sampleB,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultDir => $composableBuilder(
    column: $table.resultDir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$AnalysesTableOrderingComposer
    extends Composer<_$GenozDatabase, $AnalysesTable> {
  $$AnalysesTableOrderingComposer({
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

  ColumnOrderings<String> get fileAId => $composableBuilder(
    column: $table.fileAId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileBId => $composableBuilder(
    column: $table.fileBId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sampleA => $composableBuilder(
    column: $table.sampleA,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sampleB => $composableBuilder(
    column: $table.sampleB,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultDir => $composableBuilder(
    column: $table.resultDir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$AnalysesTableAnnotationComposer
    extends Composer<_$GenozDatabase, $AnalysesTable> {
  $$AnalysesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileAId =>
      $composableBuilder(column: $table.fileAId, builder: (column) => column);

  GeneratedColumn<String> get fileBId =>
      $composableBuilder(column: $table.fileBId, builder: (column) => column);

  GeneratedColumn<String> get sampleA =>
      $composableBuilder(column: $table.sampleA, builder: (column) => column);

  GeneratedColumn<String> get sampleB =>
      $composableBuilder(column: $table.sampleB, builder: (column) => column);

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultDir =>
      $composableBuilder(column: $table.resultDir, builder: (column) => column);

  GeneratedColumn<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentId =>
      $composableBuilder(column: $table.contentId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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

class $$AnalysesTableTableManager
    extends
        RootTableManager<
          _$GenozDatabase,
          $AnalysesTable,
          Analysis,
          $$AnalysesTableFilterComposer,
          $$AnalysesTableOrderingComposer,
          $$AnalysesTableAnnotationComposer,
          $$AnalysesTableCreateCompanionBuilder,
          $$AnalysesTableUpdateCompanionBuilder,
          (Analysis, $$AnalysesTableReferences),
          Analysis,
          PrefetchHooks Function({bool projectId})
        > {
  $$AnalysesTableTableManager(_$GenozDatabase db, $AnalysesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalysesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalysesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnalysesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> fileAId = const Value.absent(),
                Value<String> fileBId = const Value.absent(),
                Value<String?> sampleA = const Value.absent(),
                Value<String?> sampleB = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<String> resultDir = const Value.absent(),
                Value<String> summaryJson = const Value.absent(),
                Value<String> contentId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnalysesCompanion(
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
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String fileAId,
                required String fileBId,
                Value<String?> sampleA = const Value.absent(),
                Value<String?> sampleB = const Value.absent(),
                required String optionsJson,
                required String resultDir,
                required String summaryJson,
                required String contentId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AnalysesCompanion.insert(
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
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AnalysesTable, Analysis>(table),
                  $$AnalysesTableReferences(db, table, e),
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
                        referencedTable: $$AnalysesTableReferences
                            ._projectIdTable(db),
                        referencedColumn: $$AnalysesTableReferences
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

typedef $$AnalysesTableProcessedTableManager =
    ProcessedTableManager<
      _$GenozDatabase,
      $AnalysesTable,
      Analysis,
      $$AnalysesTableFilterComposer,
      $$AnalysesTableOrderingComposer,
      $$AnalysesTableAnnotationComposer,
      $$AnalysesTableCreateCompanionBuilder,
      $$AnalysesTableUpdateCompanionBuilder,
      (Analysis, $$AnalysesTableReferences),
      Analysis,
      PrefetchHooks Function({bool projectId})
    >;
typedef $$SavedFiltersTableCreateCompanionBuilder =
    SavedFiltersCompanion Function({
      required String id,
      required String projectId,
      required String name,
      required String filterJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SavedFiltersTableUpdateCompanionBuilder =
    SavedFiltersCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> name,
      Value<String> filterJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$SavedFiltersTableReferences
    extends BaseReferences<_$GenozDatabase, $SavedFiltersTable, SavedFilter> {
  $$SavedFiltersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$GenozDatabase db) =>
      db.projects.createAlias('saved_filters__project_id__projects__id');

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

class $$SavedFiltersTableFilterComposer
    extends Composer<_$GenozDatabase, $SavedFiltersTable> {
  $$SavedFiltersTableFilterComposer({
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

  ColumnFilters<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$SavedFiltersTableOrderingComposer
    extends Composer<_$GenozDatabase, $SavedFiltersTable> {
  $$SavedFiltersTableOrderingComposer({
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

  ColumnOrderings<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$SavedFiltersTableAnnotationComposer
    extends Composer<_$GenozDatabase, $SavedFiltersTable> {
  $$SavedFiltersTableAnnotationComposer({
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

  GeneratedColumn<String> get filterJson => $composableBuilder(
    column: $table.filterJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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

class $$SavedFiltersTableTableManager
    extends
        RootTableManager<
          _$GenozDatabase,
          $SavedFiltersTable,
          SavedFilter,
          $$SavedFiltersTableFilterComposer,
          $$SavedFiltersTableOrderingComposer,
          $$SavedFiltersTableAnnotationComposer,
          $$SavedFiltersTableCreateCompanionBuilder,
          $$SavedFiltersTableUpdateCompanionBuilder,
          (SavedFilter, $$SavedFiltersTableReferences),
          SavedFilter,
          PrefetchHooks Function({bool projectId})
        > {
  $$SavedFiltersTableTableManager(_$GenozDatabase db, $SavedFiltersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedFiltersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedFiltersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedFiltersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> filterJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedFiltersCompanion(
                id: id,
                projectId: projectId,
                name: name,
                filterJson: filterJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String name,
                required String filterJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedFiltersCompanion.insert(
                id: id,
                projectId: projectId,
                name: name,
                filterJson: filterJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedFiltersTable, SavedFilter>(table),
                  $$SavedFiltersTableReferences(db, table, e),
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
                        referencedTable: $$SavedFiltersTableReferences
                            ._projectIdTable(db),
                        referencedColumn: $$SavedFiltersTableReferences
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

typedef $$SavedFiltersTableProcessedTableManager =
    ProcessedTableManager<
      _$GenozDatabase,
      $SavedFiltersTable,
      SavedFilter,
      $$SavedFiltersTableFilterComposer,
      $$SavedFiltersTableOrderingComposer,
      $$SavedFiltersTableAnnotationComposer,
      $$SavedFiltersTableCreateCompanionBuilder,
      $$SavedFiltersTableUpdateCompanionBuilder,
      (SavedFilter, $$SavedFiltersTableReferences),
      SavedFilter,
      PrefetchHooks Function({bool projectId})
    >;
typedef $$VariantNotesTableCreateCompanionBuilder =
    VariantNotesCompanion Function({
      required String projectId,
      required String variantKey,
      Value<String> note,
      Value<String> tagsJson,
      Value<bool> favorite,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$VariantNotesTableUpdateCompanionBuilder =
    VariantNotesCompanion Function({
      Value<String> projectId,
      Value<String> variantKey,
      Value<String> note,
      Value<String> tagsJson,
      Value<bool> favorite,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$VariantNotesTableReferences
    extends BaseReferences<_$GenozDatabase, $VariantNotesTable, VariantNote> {
  $$VariantNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$GenozDatabase db) =>
      db.projects.createAlias('variant_notes__project_id__projects__id');

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

class $$VariantNotesTableFilterComposer
    extends Composer<_$GenozDatabase, $VariantNotesTable> {
  $$VariantNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get variantKey => $composableBuilder(
    column: $table.variantKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

class $$VariantNotesTableOrderingComposer
    extends Composer<_$GenozDatabase, $VariantNotesTable> {
  $$VariantNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get variantKey => $composableBuilder(
    column: $table.variantKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

class $$VariantNotesTableAnnotationComposer
    extends Composer<_$GenozDatabase, $VariantNotesTable> {
  $$VariantNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get variantKey => $composableBuilder(
    column: $table.variantKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

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

class $$VariantNotesTableTableManager
    extends
        RootTableManager<
          _$GenozDatabase,
          $VariantNotesTable,
          VariantNote,
          $$VariantNotesTableFilterComposer,
          $$VariantNotesTableOrderingComposer,
          $$VariantNotesTableAnnotationComposer,
          $$VariantNotesTableCreateCompanionBuilder,
          $$VariantNotesTableUpdateCompanionBuilder,
          (VariantNote, $$VariantNotesTableReferences),
          VariantNote,
          PrefetchHooks Function({bool projectId})
        > {
  $$VariantNotesTableTableManager(_$GenozDatabase db, $VariantNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VariantNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VariantNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VariantNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> projectId = const Value.absent(),
                Value<String> variantKey = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VariantNotesCompanion(
                projectId: projectId,
                variantKey: variantKey,
                note: note,
                tagsJson: tagsJson,
                favorite: favorite,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String projectId,
                required String variantKey,
                Value<String> note = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VariantNotesCompanion.insert(
                projectId: projectId,
                variantKey: variantKey,
                note: note,
                tagsJson: tagsJson,
                favorite: favorite,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VariantNotesTable, VariantNote>(table),
                  $$VariantNotesTableReferences(db, table, e),
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
                        referencedTable: $$VariantNotesTableReferences
                            ._projectIdTable(db),
                        referencedColumn: $$VariantNotesTableReferences
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

typedef $$VariantNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$GenozDatabase,
      $VariantNotesTable,
      VariantNote,
      $$VariantNotesTableFilterComposer,
      $$VariantNotesTableOrderingComposer,
      $$VariantNotesTableAnnotationComposer,
      $$VariantNotesTableCreateCompanionBuilder,
      $$VariantNotesTableUpdateCompanionBuilder,
      (VariantNote, $$VariantNotesTableReferences),
      VariantNote,
      PrefetchHooks Function({bool projectId})
    >;
typedef $$JournalEntriesTableCreateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      required String projectId,
      required String kind,
      required String message,
      required DateTime createdAt,
    });
typedef $$JournalEntriesTableUpdateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      Value<String> projectId,
      Value<String> kind,
      Value<String> message,
      Value<DateTime> createdAt,
    });

final class $$JournalEntriesTableReferences
    extends
        BaseReferences<_$GenozDatabase, $JournalEntriesTable, JournalEntry> {
  $$JournalEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProjectsTable _projectIdTable(_$GenozDatabase db) =>
      db.projects.createAlias('journal_entries__project_id__projects__id');

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

class $$JournalEntriesTableFilterComposer
    extends Composer<_$GenozDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$GenozDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$GenozDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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

class $$JournalEntriesTableTableManager
    extends
        RootTableManager<
          _$GenozDatabase,
          $JournalEntriesTable,
          JournalEntry,
          $$JournalEntriesTableFilterComposer,
          $$JournalEntriesTableOrderingComposer,
          $$JournalEntriesTableAnnotationComposer,
          $$JournalEntriesTableCreateCompanionBuilder,
          $$JournalEntriesTableUpdateCompanionBuilder,
          (JournalEntry, $$JournalEntriesTableReferences),
          JournalEntry,
          PrefetchHooks Function({bool projectId})
        > {
  $$JournalEntriesTableTableManager(
    _$GenozDatabase db,
    $JournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => JournalEntriesCompanion(
                id: id,
                projectId: projectId,
                kind: kind,
                message: message,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String projectId,
                required String kind,
                required String message,
                required DateTime createdAt,
              }) => JournalEntriesCompanion.insert(
                id: id,
                projectId: projectId,
                kind: kind,
                message: message,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JournalEntriesTable, JournalEntry>(table),
                  $$JournalEntriesTableReferences(db, table, e),
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
                        referencedTable: $$JournalEntriesTableReferences
                            ._projectIdTable(db),
                        referencedColumn: $$JournalEntriesTableReferences
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

typedef $$JournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$GenozDatabase,
      $JournalEntriesTable,
      JournalEntry,
      $$JournalEntriesTableFilterComposer,
      $$JournalEntriesTableOrderingComposer,
      $$JournalEntriesTableAnnotationComposer,
      $$JournalEntriesTableCreateCompanionBuilder,
      $$JournalEntriesTableUpdateCompanionBuilder,
      (JournalEntry, $$JournalEntriesTableReferences),
      JournalEntry,
      PrefetchHooks Function({bool projectId})
    >;
typedef $$FamilyAnalysesTableCreateCompanionBuilder =
    FamilyAnalysesCompanion Function({
      required String id,
      required String projectId,
      required String fileId,
      required String optionsJson,
      required String resultDir,
      required int sampleCount,
      required bool hasTrio,
      required String contentId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$FamilyAnalysesTableUpdateCompanionBuilder =
    FamilyAnalysesCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> fileId,
      Value<String> optionsJson,
      Value<String> resultDir,
      Value<int> sampleCount,
      Value<bool> hasTrio,
      Value<String> contentId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$FamilyAnalysesTableReferences
    extends
        BaseReferences<_$GenozDatabase, $FamilyAnalysesTable, FamilyAnalysis> {
  $$FamilyAnalysesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProjectsTable _projectIdTable(_$GenozDatabase db) =>
      db.projects.createAlias('family_analyses__project_id__projects__id');

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

class $$FamilyAnalysesTableFilterComposer
    extends Composer<_$GenozDatabase, $FamilyAnalysesTable> {
  $$FamilyAnalysesTableFilterComposer({
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

  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultDir => $composableBuilder(
    column: $table.resultDir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasTrio => $composableBuilder(
    column: $table.hasTrio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$FamilyAnalysesTableOrderingComposer
    extends Composer<_$GenozDatabase, $FamilyAnalysesTable> {
  $$FamilyAnalysesTableOrderingComposer({
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

  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultDir => $composableBuilder(
    column: $table.resultDir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasTrio => $composableBuilder(
    column: $table.hasTrio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$FamilyAnalysesTableAnnotationComposer
    extends Composer<_$GenozDatabase, $FamilyAnalysesTable> {
  $$FamilyAnalysesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultDir =>
      $composableBuilder(column: $table.resultDir, builder: (column) => column);

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasTrio =>
      $composableBuilder(column: $table.hasTrio, builder: (column) => column);

  GeneratedColumn<String> get contentId =>
      $composableBuilder(column: $table.contentId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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

class $$FamilyAnalysesTableTableManager
    extends
        RootTableManager<
          _$GenozDatabase,
          $FamilyAnalysesTable,
          FamilyAnalysis,
          $$FamilyAnalysesTableFilterComposer,
          $$FamilyAnalysesTableOrderingComposer,
          $$FamilyAnalysesTableAnnotationComposer,
          $$FamilyAnalysesTableCreateCompanionBuilder,
          $$FamilyAnalysesTableUpdateCompanionBuilder,
          (FamilyAnalysis, $$FamilyAnalysesTableReferences),
          FamilyAnalysis,
          PrefetchHooks Function({bool projectId})
        > {
  $$FamilyAnalysesTableTableManager(
    _$GenozDatabase db,
    $FamilyAnalysesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyAnalysesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyAnalysesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyAnalysesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<String> resultDir = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<bool> hasTrio = const Value.absent(),
                Value<String> contentId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyAnalysesCompanion(
                id: id,
                projectId: projectId,
                fileId: fileId,
                optionsJson: optionsJson,
                resultDir: resultDir,
                sampleCount: sampleCount,
                hasTrio: hasTrio,
                contentId: contentId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String fileId,
                required String optionsJson,
                required String resultDir,
                required int sampleCount,
                required bool hasTrio,
                required String contentId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FamilyAnalysesCompanion.insert(
                id: id,
                projectId: projectId,
                fileId: fileId,
                optionsJson: optionsJson,
                resultDir: resultDir,
                sampleCount: sampleCount,
                hasTrio: hasTrio,
                contentId: contentId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FamilyAnalysesTable, FamilyAnalysis>(table),
                  $$FamilyAnalysesTableReferences(db, table, e),
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
                        referencedTable: $$FamilyAnalysesTableReferences
                            ._projectIdTable(db),
                        referencedColumn: $$FamilyAnalysesTableReferences
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

typedef $$FamilyAnalysesTableProcessedTableManager =
    ProcessedTableManager<
      _$GenozDatabase,
      $FamilyAnalysesTable,
      FamilyAnalysis,
      $$FamilyAnalysesTableFilterComposer,
      $$FamilyAnalysesTableOrderingComposer,
      $$FamilyAnalysesTableAnnotationComposer,
      $$FamilyAnalysesTableCreateCompanionBuilder,
      $$FamilyAnalysesTableUpdateCompanionBuilder,
      (FamilyAnalysis, $$FamilyAnalysesTableReferences),
      FamilyAnalysis,
      PrefetchHooks Function({bool projectId})
    >;

class $GenozDatabaseManager {
  final _$GenozDatabase _db;
  $GenozDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$ProjectFilesTableTableManager get projectFiles =>
      $$ProjectFilesTableTableManager(_db, _db.projectFiles);
  $$AnalysesTableTableManager get analyses =>
      $$AnalysesTableTableManager(_db, _db.analyses);
  $$SavedFiltersTableTableManager get savedFilters =>
      $$SavedFiltersTableTableManager(_db, _db.savedFilters);
  $$VariantNotesTableTableManager get variantNotes =>
      $$VariantNotesTableTableManager(_db, _db.variantNotes);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$FamilyAnalysesTableTableManager get familyAnalyses =>
      $$FamilyAnalysesTableTableManager(_db, _db.familyAnalyses);
}
