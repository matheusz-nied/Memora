// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DecksTableTable extends DecksTable
    with TableInfo<$DecksTableTable, LocalDeck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
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
  static const VerificationMeta _agentNameMeta = const VerificationMeta(
    'agentName',
  );
  @override
  late final GeneratedColumn<String> agentName = GeneratedColumn<String>(
    'agent_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Tutor'),
  );
  static const VerificationMeta _agentPromptMeta = const VerificationMeta(
    'agentPrompt',
  );
  @override
  late final GeneratedColumn<String> agentPrompt = GeneratedColumn<String>(
    'agent_prompt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _agentTemplateMeta = const VerificationMeta(
    'agentTemplate',
  );
  @override
  late final GeneratedColumn<String> agentTemplate = GeneratedColumn<String>(
    'agent_template',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('general'),
  );
  static const VerificationMeta _agentLanguageMeta = const VerificationMeta(
    'agentLanguage',
  );
  @override
  late final GeneratedColumn<String> agentLanguage = GeneratedColumn<String>(
    'agent_language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('português'),
  );
  static const VerificationMeta _agentLevelMeta = const VerificationMeta(
    'agentLevel',
  );
  @override
  late final GeneratedColumn<String> agentLevel = GeneratedColumn<String>(
    'agent_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('intermediário'),
  );
  static const VerificationMeta _syncPendingMeta = const VerificationMeta(
    'syncPending',
  );
  @override
  late final GeneratedColumn<bool> syncPending = GeneratedColumn<bool>(
    'sync_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    description,
    agentName,
    agentPrompt,
    agentTemplate,
    agentLanguage,
    agentLevel,
    syncPending,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDeck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
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
    if (data.containsKey('agent_name')) {
      context.handle(
        _agentNameMeta,
        agentName.isAcceptableOrUnknown(data['agent_name']!, _agentNameMeta),
      );
    }
    if (data.containsKey('agent_prompt')) {
      context.handle(
        _agentPromptMeta,
        agentPrompt.isAcceptableOrUnknown(
          data['agent_prompt']!,
          _agentPromptMeta,
        ),
      );
    }
    if (data.containsKey('agent_template')) {
      context.handle(
        _agentTemplateMeta,
        agentTemplate.isAcceptableOrUnknown(
          data['agent_template']!,
          _agentTemplateMeta,
        ),
      );
    }
    if (data.containsKey('agent_language')) {
      context.handle(
        _agentLanguageMeta,
        agentLanguage.isAcceptableOrUnknown(
          data['agent_language']!,
          _agentLanguageMeta,
        ),
      );
    }
    if (data.containsKey('agent_level')) {
      context.handle(
        _agentLevelMeta,
        agentLevel.isAcceptableOrUnknown(data['agent_level']!, _agentLevelMeta),
      );
    }
    if (data.containsKey('sync_pending')) {
      context.handle(
        _syncPendingMeta,
        syncPending.isAcceptableOrUnknown(
          data['sync_pending']!,
          _syncPendingMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
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
  LocalDeck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDeck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      agentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_name'],
      )!,
      agentPrompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_prompt'],
      ),
      agentTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_template'],
      )!,
      agentLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_language'],
      )!,
      agentLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_level'],
      )!,
      syncPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_pending'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DecksTableTable createAlias(String alias) {
    return $DecksTableTable(attachedDatabase, alias);
  }
}

class LocalDeck extends DataClass implements Insertable<LocalDeck> {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String agentName;
  final String? agentPrompt;
  final String agentTemplate;
  final String agentLanguage;
  final String agentLevel;
  final bool syncPending;
  final int? deletedAt;
  final int createdAt;
  final int updatedAt;
  const LocalDeck({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.agentName,
    this.agentPrompt,
    required this.agentTemplate,
    required this.agentLanguage,
    required this.agentLevel,
    required this.syncPending,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['agent_name'] = Variable<String>(agentName);
    if (!nullToAbsent || agentPrompt != null) {
      map['agent_prompt'] = Variable<String>(agentPrompt);
    }
    map['agent_template'] = Variable<String>(agentTemplate);
    map['agent_language'] = Variable<String>(agentLanguage);
    map['agent_level'] = Variable<String>(agentLevel);
    map['sync_pending'] = Variable<bool>(syncPending);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DecksTableCompanion toCompanion(bool nullToAbsent) {
    return DecksTableCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      agentName: Value(agentName),
      agentPrompt: agentPrompt == null && nullToAbsent
          ? const Value.absent()
          : Value(agentPrompt),
      agentTemplate: Value(agentTemplate),
      agentLanguage: Value(agentLanguage),
      agentLevel: Value(agentLevel),
      syncPending: Value(syncPending),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalDeck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDeck(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      agentName: serializer.fromJson<String>(json['agentName']),
      agentPrompt: serializer.fromJson<String?>(json['agentPrompt']),
      agentTemplate: serializer.fromJson<String>(json['agentTemplate']),
      agentLanguage: serializer.fromJson<String>(json['agentLanguage']),
      agentLevel: serializer.fromJson<String>(json['agentLevel']),
      syncPending: serializer.fromJson<bool>(json['syncPending']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'agentName': serializer.toJson<String>(agentName),
      'agentPrompt': serializer.toJson<String?>(agentPrompt),
      'agentTemplate': serializer.toJson<String>(agentTemplate),
      'agentLanguage': serializer.toJson<String>(agentLanguage),
      'agentLevel': serializer.toJson<String>(agentLevel),
      'syncPending': serializer.toJson<bool>(syncPending),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LocalDeck copyWith({
    String? id,
    String? userId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? agentName,
    Value<String?> agentPrompt = const Value.absent(),
    String? agentTemplate,
    String? agentLanguage,
    String? agentLevel,
    bool? syncPending,
    Value<int?> deletedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => LocalDeck(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    agentName: agentName ?? this.agentName,
    agentPrompt: agentPrompt.present ? agentPrompt.value : this.agentPrompt,
    agentTemplate: agentTemplate ?? this.agentTemplate,
    agentLanguage: agentLanguage ?? this.agentLanguage,
    agentLevel: agentLevel ?? this.agentLevel,
    syncPending: syncPending ?? this.syncPending,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalDeck copyWithCompanion(DecksTableCompanion data) {
    return LocalDeck(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      agentName: data.agentName.present ? data.agentName.value : this.agentName,
      agentPrompt: data.agentPrompt.present
          ? data.agentPrompt.value
          : this.agentPrompt,
      agentTemplate: data.agentTemplate.present
          ? data.agentTemplate.value
          : this.agentTemplate,
      agentLanguage: data.agentLanguage.present
          ? data.agentLanguage.value
          : this.agentLanguage,
      agentLevel: data.agentLevel.present
          ? data.agentLevel.value
          : this.agentLevel,
      syncPending: data.syncPending.present
          ? data.syncPending.value
          : this.syncPending,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDeck(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('agentName: $agentName, ')
          ..write('agentPrompt: $agentPrompt, ')
          ..write('agentTemplate: $agentTemplate, ')
          ..write('agentLanguage: $agentLanguage, ')
          ..write('agentLevel: $agentLevel, ')
          ..write('syncPending: $syncPending, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    description,
    agentName,
    agentPrompt,
    agentTemplate,
    agentLanguage,
    agentLevel,
    syncPending,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDeck &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.description == this.description &&
          other.agentName == this.agentName &&
          other.agentPrompt == this.agentPrompt &&
          other.agentTemplate == this.agentTemplate &&
          other.agentLanguage == this.agentLanguage &&
          other.agentLevel == this.agentLevel &&
          other.syncPending == this.syncPending &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DecksTableCompanion extends UpdateCompanion<LocalDeck> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> agentName;
  final Value<String?> agentPrompt;
  final Value<String> agentTemplate;
  final Value<String> agentLanguage;
  final Value<String> agentLevel;
  final Value<bool> syncPending;
  final Value<int?> deletedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DecksTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.agentName = const Value.absent(),
    this.agentPrompt = const Value.absent(),
    this.agentTemplate = const Value.absent(),
    this.agentLanguage = const Value.absent(),
    this.agentLevel = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DecksTableCompanion.insert({
    required String id,
    required String userId,
    required String title,
    this.description = const Value.absent(),
    this.agentName = const Value.absent(),
    this.agentPrompt = const Value.absent(),
    this.agentTemplate = const Value.absent(),
    this.agentLanguage = const Value.absent(),
    this.agentLevel = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalDeck> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? agentName,
    Expression<String>? agentPrompt,
    Expression<String>? agentTemplate,
    Expression<String>? agentLanguage,
    Expression<String>? agentLevel,
    Expression<bool>? syncPending,
    Expression<int>? deletedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (agentName != null) 'agent_name': agentName,
      if (agentPrompt != null) 'agent_prompt': agentPrompt,
      if (agentTemplate != null) 'agent_template': agentTemplate,
      if (agentLanguage != null) 'agent_language': agentLanguage,
      if (agentLevel != null) 'agent_level': agentLevel,
      if (syncPending != null) 'sync_pending': syncPending,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DecksTableCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? agentName,
    Value<String?>? agentPrompt,
    Value<String>? agentTemplate,
    Value<String>? agentLanguage,
    Value<String>? agentLevel,
    Value<bool>? syncPending,
    Value<int?>? deletedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DecksTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      agentName: agentName ?? this.agentName,
      agentPrompt: agentPrompt ?? this.agentPrompt,
      agentTemplate: agentTemplate ?? this.agentTemplate,
      agentLanguage: agentLanguage ?? this.agentLanguage,
      agentLevel: agentLevel ?? this.agentLevel,
      syncPending: syncPending ?? this.syncPending,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (agentName.present) {
      map['agent_name'] = Variable<String>(agentName.value);
    }
    if (agentPrompt.present) {
      map['agent_prompt'] = Variable<String>(agentPrompt.value);
    }
    if (agentTemplate.present) {
      map['agent_template'] = Variable<String>(agentTemplate.value);
    }
    if (agentLanguage.present) {
      map['agent_language'] = Variable<String>(agentLanguage.value);
    }
    if (agentLevel.present) {
      map['agent_level'] = Variable<String>(agentLevel.value);
    }
    if (syncPending.present) {
      map['sync_pending'] = Variable<bool>(syncPending.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DecksTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('agentName: $agentName, ')
          ..write('agentPrompt: $agentPrompt, ')
          ..write('agentTemplate: $agentTemplate, ')
          ..write('agentLanguage: $agentLanguage, ')
          ..write('agentLevel: $agentLevel, ')
          ..write('syncPending: $syncPending, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardsTableTable extends CardsTable
    with TableInfo<$CardsTableTable, LocalCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frontMeta = const VerificationMeta('front');
  @override
  late final GeneratedColumn<String> front = GeneratedColumn<String>(
    'front',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backMeta = const VerificationMeta('back');
  @override
  late final GeneratedColumn<String> back = GeneratedColumn<String>(
    'back',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<int> dueDate = GeneratedColumn<int>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncPendingMeta = const VerificationMeta(
    'syncPending',
  );
  @override
  late final GeneratedColumn<bool> syncPending = GeneratedColumn<bool>(
    'sync_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _insightMeta = const VerificationMeta(
    'insight',
  );
  @override
  late final GeneratedColumn<String> insight = GeneratedColumn<String>(
    'insight',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    front,
    back,
    easeFactor,
    intervalDays,
    dueDate,
    syncPending,
    insight,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('front')) {
      context.handle(
        _frontMeta,
        front.isAcceptableOrUnknown(data['front']!, _frontMeta),
      );
    } else if (isInserting) {
      context.missing(_frontMeta);
    }
    if (data.containsKey('back')) {
      context.handle(
        _backMeta,
        back.isAcceptableOrUnknown(data['back']!, _backMeta),
      );
    } else if (isInserting) {
      context.missing(_backMeta);
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('sync_pending')) {
      context.handle(
        _syncPendingMeta,
        syncPending.isAcceptableOrUnknown(
          data['sync_pending']!,
          _syncPendingMeta,
        ),
      );
    }
    if (data.containsKey('insight')) {
      context.handle(
        _insightMeta,
        insight.isAcceptableOrUnknown(data['insight']!, _insightMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
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
  LocalCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      front: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front'],
      )!,
      back: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_date'],
      )!,
      syncPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_pending'],
      )!,
      insight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}insight'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CardsTableTable createAlias(String alias) {
    return $CardsTableTable(attachedDatabase, alias);
  }
}

class LocalCard extends DataClass implements Insertable<LocalCard> {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final double easeFactor;
  final int intervalDays;
  final int dueDate;
  final bool syncPending;
  final String? insight;
  final int? deletedAt;
  final int createdAt;
  final int updatedAt;
  const LocalCard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.easeFactor,
    required this.intervalDays,
    required this.dueDate,
    required this.syncPending,
    this.insight,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['front'] = Variable<String>(front);
    map['back'] = Variable<String>(back);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['due_date'] = Variable<int>(dueDate);
    map['sync_pending'] = Variable<bool>(syncPending);
    if (!nullToAbsent || insight != null) {
      map['insight'] = Variable<String>(insight);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CardsTableCompanion toCompanion(bool nullToAbsent) {
    return CardsTableCompanion(
      id: Value(id),
      deckId: Value(deckId),
      front: Value(front),
      back: Value(back),
      easeFactor: Value(easeFactor),
      intervalDays: Value(intervalDays),
      dueDate: Value(dueDate),
      syncPending: Value(syncPending),
      insight: insight == null && nullToAbsent
          ? const Value.absent()
          : Value(insight),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCard(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      front: serializer.fromJson<String>(json['front']),
      back: serializer.fromJson<String>(json['back']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      dueDate: serializer.fromJson<int>(json['dueDate']),
      syncPending: serializer.fromJson<bool>(json['syncPending']),
      insight: serializer.fromJson<String?>(json['insight']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'front': serializer.toJson<String>(front),
      'back': serializer.toJson<String>(back),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'dueDate': serializer.toJson<int>(dueDate),
      'syncPending': serializer.toJson<bool>(syncPending),
      'insight': serializer.toJson<String?>(insight),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LocalCard copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    double? easeFactor,
    int? intervalDays,
    int? dueDate,
    bool? syncPending,
    Value<String?> insight = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => LocalCard(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    front: front ?? this.front,
    back: back ?? this.back,
    easeFactor: easeFactor ?? this.easeFactor,
    intervalDays: intervalDays ?? this.intervalDays,
    dueDate: dueDate ?? this.dueDate,
    syncPending: syncPending ?? this.syncPending,
    insight: insight.present ? insight.value : this.insight,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalCard copyWithCompanion(CardsTableCompanion data) {
    return LocalCard(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      syncPending: data.syncPending.present
          ? data.syncPending.value
          : this.syncPending,
      insight: data.insight.present ? data.insight.value : this.insight,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCard(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('dueDate: $dueDate, ')
          ..write('syncPending: $syncPending, ')
          ..write('insight: $insight, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deckId,
    front,
    back,
    easeFactor,
    intervalDays,
    dueDate,
    syncPending,
    insight,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCard &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.front == this.front &&
          other.back == this.back &&
          other.easeFactor == this.easeFactor &&
          other.intervalDays == this.intervalDays &&
          other.dueDate == this.dueDate &&
          other.syncPending == this.syncPending &&
          other.insight == this.insight &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CardsTableCompanion extends UpdateCompanion<LocalCard> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> front;
  final Value<String> back;
  final Value<double> easeFactor;
  final Value<int> intervalDays;
  final Value<int> dueDate;
  final Value<bool> syncPending;
  final Value<String?> insight;
  final Value<int?> deletedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CardsTableCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.syncPending = const Value.absent(),
    this.insight = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsTableCompanion.insert({
    required String id,
    required String deckId,
    required String front,
    required String back,
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    required int dueDate,
    this.syncPending = const Value.absent(),
    this.insight = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deckId = Value(deckId),
       front = Value(front),
       back = Value(back),
       dueDate = Value(dueDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalCard> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? front,
    Expression<String>? back,
    Expression<double>? easeFactor,
    Expression<int>? intervalDays,
    Expression<int>? dueDate,
    Expression<bool>? syncPending,
    Expression<String>? insight,
    Expression<int>? deletedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (dueDate != null) 'due_date': dueDate,
      if (syncPending != null) 'sync_pending': syncPending,
      if (insight != null) 'insight': insight,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? deckId,
    Value<String>? front,
    Value<String>? back,
    Value<double>? easeFactor,
    Value<int>? intervalDays,
    Value<int>? dueDate,
    Value<bool>? syncPending,
    Value<String?>? insight,
    Value<int?>? deletedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return CardsTableCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      dueDate: dueDate ?? this.dueDate,
      syncPending: syncPending ?? this.syncPending,
      insight: insight ?? this.insight,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (front.present) {
      map['front'] = Variable<String>(front.value);
    }
    if (back.present) {
      map['back'] = Variable<String>(back.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<int>(dueDate.value);
    }
    if (syncPending.present) {
      map['sync_pending'] = Variable<bool>(syncPending.value);
    }
    if (insight.present) {
      map['insight'] = Variable<String>(insight.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsTableCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('dueDate: $dueDate, ')
          ..write('syncPending: $syncPending, ')
          ..write('insight: $insight, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DecksTableTable decksTable = $DecksTableTable(this);
  late final $CardsTableTable cardsTable = $CardsTableTable(this);
  late final DecksDao decksDao = DecksDao(this as AppDatabase);
  late final CardsDao cardsDao = CardsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [decksTable, cardsTable];
}

typedef $$DecksTableTableCreateCompanionBuilder =
    DecksTableCompanion Function({
      required String id,
      required String userId,
      required String title,
      Value<String?> description,
      Value<String> agentName,
      Value<String?> agentPrompt,
      Value<String> agentTemplate,
      Value<String> agentLanguage,
      Value<String> agentLevel,
      Value<bool> syncPending,
      Value<int?> deletedAt,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$DecksTableTableUpdateCompanionBuilder =
    DecksTableCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> title,
      Value<String?> description,
      Value<String> agentName,
      Value<String?> agentPrompt,
      Value<String> agentTemplate,
      Value<String> agentLanguage,
      Value<String> agentLevel,
      Value<bool> syncPending,
      Value<int?> deletedAt,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$DecksTableTableFilterComposer
    extends Composer<_$AppDatabase, $DecksTableTable> {
  $$DecksTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentName => $composableBuilder(
    column: $table.agentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentPrompt => $composableBuilder(
    column: $table.agentPrompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentTemplate => $composableBuilder(
    column: $table.agentTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentLanguage => $composableBuilder(
    column: $table.agentLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentLevel => $composableBuilder(
    column: $table.agentLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DecksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DecksTableTable> {
  $$DecksTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentName => $composableBuilder(
    column: $table.agentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentPrompt => $composableBuilder(
    column: $table.agentPrompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentTemplate => $composableBuilder(
    column: $table.agentTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentLanguage => $composableBuilder(
    column: $table.agentLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentLevel => $composableBuilder(
    column: $table.agentLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DecksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DecksTableTable> {
  $$DecksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get agentName =>
      $composableBuilder(column: $table.agentName, builder: (column) => column);

  GeneratedColumn<String> get agentPrompt => $composableBuilder(
    column: $table.agentPrompt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get agentTemplate => $composableBuilder(
    column: $table.agentTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get agentLanguage => $composableBuilder(
    column: $table.agentLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get agentLevel => $composableBuilder(
    column: $table.agentLevel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DecksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DecksTableTable,
          LocalDeck,
          $$DecksTableTableFilterComposer,
          $$DecksTableTableOrderingComposer,
          $$DecksTableTableAnnotationComposer,
          $$DecksTableTableCreateCompanionBuilder,
          $$DecksTableTableUpdateCompanionBuilder,
          (
            LocalDeck,
            BaseReferences<_$AppDatabase, $DecksTableTable, LocalDeck>,
          ),
          LocalDeck,
          PrefetchHooks Function()
        > {
  $$DecksTableTableTableManager(_$AppDatabase db, $DecksTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> agentName = const Value.absent(),
                Value<String?> agentPrompt = const Value.absent(),
                Value<String> agentTemplate = const Value.absent(),
                Value<String> agentLanguage = const Value.absent(),
                Value<String> agentLevel = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DecksTableCompanion(
                id: id,
                userId: userId,
                title: title,
                description: description,
                agentName: agentName,
                agentPrompt: agentPrompt,
                agentTemplate: agentTemplate,
                agentLanguage: agentLanguage,
                agentLevel: agentLevel,
                syncPending: syncPending,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> agentName = const Value.absent(),
                Value<String?> agentPrompt = const Value.absent(),
                Value<String> agentTemplate = const Value.absent(),
                Value<String> agentLanguage = const Value.absent(),
                Value<String> agentLevel = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DecksTableCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                description: description,
                agentName: agentName,
                agentPrompt: agentPrompt,
                agentTemplate: agentTemplate,
                agentLanguage: agentLanguage,
                agentLevel: agentLevel,
                syncPending: syncPending,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DecksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DecksTableTable,
      LocalDeck,
      $$DecksTableTableFilterComposer,
      $$DecksTableTableOrderingComposer,
      $$DecksTableTableAnnotationComposer,
      $$DecksTableTableCreateCompanionBuilder,
      $$DecksTableTableUpdateCompanionBuilder,
      (LocalDeck, BaseReferences<_$AppDatabase, $DecksTableTable, LocalDeck>),
      LocalDeck,
      PrefetchHooks Function()
    >;
typedef $$CardsTableTableCreateCompanionBuilder =
    CardsTableCompanion Function({
      required String id,
      required String deckId,
      required String front,
      required String back,
      Value<double> easeFactor,
      Value<int> intervalDays,
      required int dueDate,
      Value<bool> syncPending,
      Value<String?> insight,
      Value<int?> deletedAt,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$CardsTableTableUpdateCompanionBuilder =
    CardsTableCompanion Function({
      Value<String> id,
      Value<String> deckId,
      Value<String> front,
      Value<String> back,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> dueDate,
      Value<bool> syncPending,
      Value<String?> insight,
      Value<int?> deletedAt,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$CardsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CardsTableTable> {
  $$CardsTableTableFilterComposer({
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

  ColumnFilters<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get insight => $composableBuilder(
    column: $table.insight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CardsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTableTable> {
  $$CardsTableTableOrderingComposer({
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

  ColumnOrderings<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get insight => $composableBuilder(
    column: $table.insight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTableTable> {
  $$CardsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deckId =>
      $composableBuilder(column: $table.deckId, builder: (column) => column);

  GeneratedColumn<String> get front =>
      $composableBuilder(column: $table.front, builder: (column) => column);

  GeneratedColumn<String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get syncPending => $composableBuilder(
    column: $table.syncPending,
    builder: (column) => column,
  );

  GeneratedColumn<String> get insight =>
      $composableBuilder(column: $table.insight, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CardsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardsTableTable,
          LocalCard,
          $$CardsTableTableFilterComposer,
          $$CardsTableTableOrderingComposer,
          $$CardsTableTableAnnotationComposer,
          $$CardsTableTableCreateCompanionBuilder,
          $$CardsTableTableUpdateCompanionBuilder,
          (
            LocalCard,
            BaseReferences<_$AppDatabase, $CardsTableTable, LocalCard>,
          ),
          LocalCard,
          PrefetchHooks Function()
        > {
  $$CardsTableTableTableManager(_$AppDatabase db, $CardsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> front = const Value.absent(),
                Value<String> back = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> dueDate = const Value.absent(),
                Value<bool> syncPending = const Value.absent(),
                Value<String?> insight = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsTableCompanion(
                id: id,
                deckId: deckId,
                front: front,
                back: back,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                dueDate: dueDate,
                syncPending: syncPending,
                insight: insight,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deckId,
                required String front,
                required String back,
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                required int dueDate,
                Value<bool> syncPending = const Value.absent(),
                Value<String?> insight = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CardsTableCompanion.insert(
                id: id,
                deckId: deckId,
                front: front,
                back: back,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                dueDate: dueDate,
                syncPending: syncPending,
                insight: insight,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CardsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardsTableTable,
      LocalCard,
      $$CardsTableTableFilterComposer,
      $$CardsTableTableOrderingComposer,
      $$CardsTableTableAnnotationComposer,
      $$CardsTableTableCreateCompanionBuilder,
      $$CardsTableTableUpdateCompanionBuilder,
      (LocalCard, BaseReferences<_$AppDatabase, $CardsTableTable, LocalCard>),
      LocalCard,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DecksTableTableTableManager get decksTable =>
      $$DecksTableTableTableManager(_db, _db.decksTable);
  $$CardsTableTableTableManager get cardsTable =>
      $$CardsTableTableTableManager(_db, _db.cardsTable);
}
