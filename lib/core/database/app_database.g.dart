// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalNotesTable extends LocalNotes
    with TableInfo<$LocalNotesTable, LocalNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 0, maxTextLength: 300),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _importanceMeta =
      const VerificationMeta('importance');
  @override
  late final GeneratedColumn<int> importance = GeneratedColumn<int>(
      'importance', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _revisionMeta =
      const VerificationMeta('revision');
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
      'revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
      'position', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        title,
        content,
        subject,
        tags,
        importance,
        isFavorite,
        isArchived,
        createdAt,
        updatedAt,
        isDeleted,
        isSynced,
        revision,
        position,
        folderId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_notes';
  @override
  VerificationContext validateIntegrity(Insertable<LocalNote> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('importance')) {
      context.handle(
          _importanceMeta,
          importance.isAcceptableOrUnknown(
              data['importance']!, _importanceMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('revision')) {
      context.handle(_revisionMeta,
          revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalNote(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      importance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}importance'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      revision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}revision'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}position']),
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_id']),
    );
  }

  @override
  $LocalNotesTable createAlias(String alias) {
    return $LocalNotesTable(attachedDatabase, alias);
  }
}

class LocalNote extends DataClass implements Insertable<LocalNote> {
  /// UUID généré côté client : une fiche créée hors ligne a déjà son identité
  /// définitive, ce qui évite tout remapping à la synchronisation.
  final String id;
  final String userId;
  final String title;
  final String content;

  /// Matière / sujet, pour le filtre « par sujet » du CdC.
  final String? subject;

  /// Tags sérialisés en JSON. Le nombre de tags par fiche est petit ; une table
  /// de jointure coûterait plus qu'elle ne rapporte à cette échelle.
  final String tags;
  final int importance;
  final bool isFavorite;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Marque de suppression logique : une fiche supprimée hors ligne doit
  /// pouvoir être propagée au serveur, donc elle ne peut pas disparaître
  /// localement avant d'avoir été synchronisée.
  final bool isDeleted;

  /// `false` tant que la version locale n'a pas été poussée vers Supabase.
  final bool isSynced;

  /// Compteur des écritures sur les blocs de la fiche, **local uniquement**
  /// (jamais envoyé à Supabase ni attendu au pull).
  ///
  /// Incrémenté par les triggers de `note_triggers.drift` à chaque insertion,
  /// modification ou suppression de bloc : aucun chemin d'écriture ne peut
  /// l'oublier. La liste des fiches ne recharge que les blocs des fiches dont
  /// le compteur a bougé. Une date ne suffirait pas : Drift la tronque à la
  /// seconde, et la sauvegarde automatique peut écrire deux fois dans la même.
  final int revision;

  /// Clé d'ordre manuel (cf. `FractionalKey`), synchronisée. `null` tant que
  /// la fiche n'a jamais été placée à la main : elle garde alors l'ordre
  /// « récentes ». Collation BINARY de SQLite : même ordre que Dart et que
  /// `collate "C"` côté Postgres.
  final String? position;

  /// Dossier de l'explorateur (v13). `null` : à la racine.
  final String? folderId;
  const LocalNote(
      {required this.id,
      required this.userId,
      required this.title,
      required this.content,
      this.subject,
      required this.tags,
      required this.importance,
      required this.isFavorite,
      required this.isArchived,
      required this.createdAt,
      required this.updatedAt,
      required this.isDeleted,
      required this.isSynced,
      required this.revision,
      this.position,
      this.folderId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    map['tags'] = Variable<String>(tags);
    map['importance'] = Variable<int>(importance);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_synced'] = Variable<bool>(isSynced);
    map['revision'] = Variable<int>(revision);
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<String>(position);
    }
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    return map;
  }

  LocalNotesCompanion toCompanion(bool nullToAbsent) {
    return LocalNotesCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      content: Value(content),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      tags: Value(tags),
      importance: Value(importance),
      isFavorite: Value(isFavorite),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      isSynced: Value(isSynced),
      revision: Value(revision),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
    );
  }

  factory LocalNote.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalNote(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      subject: serializer.fromJson<String?>(json['subject']),
      tags: serializer.fromJson<String>(json['tags']),
      importance: serializer.fromJson<int>(json['importance']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      revision: serializer.fromJson<int>(json['revision']),
      position: serializer.fromJson<String?>(json['position']),
      folderId: serializer.fromJson<String?>(json['folderId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'subject': serializer.toJson<String?>(subject),
      'tags': serializer.toJson<String>(tags),
      'importance': serializer.toJson<int>(importance),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isSynced': serializer.toJson<bool>(isSynced),
      'revision': serializer.toJson<int>(revision),
      'position': serializer.toJson<String?>(position),
      'folderId': serializer.toJson<String?>(folderId),
    };
  }

  LocalNote copyWith(
          {String? id,
          String? userId,
          String? title,
          String? content,
          Value<String?> subject = const Value.absent(),
          String? tags,
          int? importance,
          bool? isFavorite,
          bool? isArchived,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? isDeleted,
          bool? isSynced,
          int? revision,
          Value<String?> position = const Value.absent(),
          Value<String?> folderId = const Value.absent()}) =>
      LocalNote(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        content: content ?? this.content,
        subject: subject.present ? subject.value : this.subject,
        tags: tags ?? this.tags,
        importance: importance ?? this.importance,
        isFavorite: isFavorite ?? this.isFavorite,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        isSynced: isSynced ?? this.isSynced,
        revision: revision ?? this.revision,
        position: position.present ? position.value : this.position,
        folderId: folderId.present ? folderId.value : this.folderId,
      );
  LocalNote copyWithCompanion(LocalNotesCompanion data) {
    return LocalNote(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      subject: data.subject.present ? data.subject.value : this.subject,
      tags: data.tags.present ? data.tags.value : this.tags,
      importance:
          data.importance.present ? data.importance.value : this.importance,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      revision: data.revision.present ? data.revision.value : this.revision,
      position: data.position.present ? data.position.value : this.position,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalNote(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('subject: $subject, ')
          ..write('tags: $tags, ')
          ..write('importance: $importance, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('revision: $revision, ')
          ..write('position: $position, ')
          ..write('folderId: $folderId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      title,
      content,
      subject,
      tags,
      importance,
      isFavorite,
      isArchived,
      createdAt,
      updatedAt,
      isDeleted,
      isSynced,
      revision,
      position,
      folderId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalNote &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.content == this.content &&
          other.subject == this.subject &&
          other.tags == this.tags &&
          other.importance == this.importance &&
          other.isFavorite == this.isFavorite &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.isSynced == this.isSynced &&
          other.revision == this.revision &&
          other.position == this.position &&
          other.folderId == this.folderId);
}

class LocalNotesCompanion extends UpdateCompanion<LocalNote> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String> content;
  final Value<String?> subject;
  final Value<String> tags;
  final Value<int> importance;
  final Value<bool> isFavorite;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<bool> isSynced;
  final Value<int> revision;
  final Value<String?> position;
  final Value<String?> folderId;
  final Value<int> rowid;
  const LocalNotesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.subject = const Value.absent(),
    this.tags = const Value.absent(),
    this.importance = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.revision = const Value.absent(),
    this.position = const Value.absent(),
    this.folderId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalNotesCompanion.insert({
    required String id,
    required String userId,
    required String title,
    this.content = const Value.absent(),
    this.subject = const Value.absent(),
    this.tags = const Value.absent(),
    this.importance = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.revision = const Value.absent(),
    this.position = const Value.absent(),
    this.folderId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalNote> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? subject,
    Expression<String>? tags,
    Expression<int>? importance,
    Expression<bool>? isFavorite,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<bool>? isSynced,
    Expression<int>? revision,
    Expression<String>? position,
    Expression<String>? folderId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (subject != null) 'subject': subject,
      if (tags != null) 'tags': tags,
      if (importance != null) 'importance': importance,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (revision != null) 'revision': revision,
      if (position != null) 'position': position,
      if (folderId != null) 'folder_id': folderId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalNotesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? title,
      Value<String>? content,
      Value<String?>? subject,
      Value<String>? tags,
      Value<int>? importance,
      Value<bool>? isFavorite,
      Value<bool>? isArchived,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isDeleted,
      Value<bool>? isSynced,
      Value<int>? revision,
      Value<String?>? position,
      Value<String?>? folderId,
      Value<int>? rowid}) {
    return LocalNotesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      subject: subject ?? this.subject,
      tags: tags ?? this.tags,
      importance: importance ?? this.importance,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
      revision: revision ?? this.revision,
      position: position ?? this.position,
      folderId: folderId ?? this.folderId,
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
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (importance.present) {
      map['importance'] = Variable<int>(importance.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('subject: $subject, ')
          ..write('tags: $tags, ')
          ..write('importance: $importance, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('revision: $revision, ')
          ..write('position: $position, ')
          ..write('folderId: $folderId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalNoteBlocksTable extends LocalNoteBlocks
    with TableInfo<$LocalNoteBlocksTable, LocalNoteBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNoteBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_notes (id) ON DELETE CASCADE'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isCheckedMeta =
      const VerificationMeta('isChecked');
  @override
  late final GeneratedColumn<bool> isChecked = GeneratedColumn<bool>(
      'is_checked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_checked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, noteId, type, content, isChecked, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_note_blocks';
  @override
  VerificationContext validateIntegrity(Insertable<LocalNoteBlock> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('is_checked')) {
      context.handle(_isCheckedMeta,
          isChecked.isAcceptableOrUnknown(data['is_checked']!, _isCheckedMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalNoteBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalNoteBlock(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      isChecked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_checked'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $LocalNoteBlocksTable createAlias(String alias) {
    return $LocalNoteBlocksTable(attachedDatabase, alias);
  }
}

class LocalNoteBlock extends DataClass implements Insertable<LocalNoteBlock> {
  final String id;

  /// `onDelete: cascade` est indispensable : sans lui, Drift génère une
  /// référence sans action et la suppression d'une fiche laisse ses blocs
  /// orphelins en base.
  final String noteId;

  /// `paragraph` | `heading` | `bulleted` | `todo` | `quote` | `code` |
  /// `image` | `link` | `divider`
  final String type;
  final String content;

  /// `true` pour un bloc `todo` coché.
  final bool isChecked;
  final int position;
  const LocalNoteBlock(
      {required this.id,
      required this.noteId,
      required this.type,
      required this.content,
      required this.isChecked,
      required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['type'] = Variable<String>(type);
    map['content'] = Variable<String>(content);
    map['is_checked'] = Variable<bool>(isChecked);
    map['position'] = Variable<int>(position);
    return map;
  }

  LocalNoteBlocksCompanion toCompanion(bool nullToAbsent) {
    return LocalNoteBlocksCompanion(
      id: Value(id),
      noteId: Value(noteId),
      type: Value(type),
      content: Value(content),
      isChecked: Value(isChecked),
      position: Value(position),
    );
  }

  factory LocalNoteBlock.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalNoteBlock(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['noteId']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String>(json['content']),
      isChecked: serializer.fromJson<bool>(json['isChecked']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<String>(noteId),
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String>(content),
      'isChecked': serializer.toJson<bool>(isChecked),
      'position': serializer.toJson<int>(position),
    };
  }

  LocalNoteBlock copyWith(
          {String? id,
          String? noteId,
          String? type,
          String? content,
          bool? isChecked,
          int? position}) =>
      LocalNoteBlock(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        type: type ?? this.type,
        content: content ?? this.content,
        isChecked: isChecked ?? this.isChecked,
        position: position ?? this.position,
      );
  LocalNoteBlock copyWithCompanion(LocalNoteBlocksCompanion data) {
    return LocalNoteBlock(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      isChecked: data.isChecked.present ? data.isChecked.value : this.isChecked,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalNoteBlock(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('isChecked: $isChecked, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, noteId, type, content, isChecked, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalNoteBlock &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.type == this.type &&
          other.content == this.content &&
          other.isChecked == this.isChecked &&
          other.position == this.position);
}

class LocalNoteBlocksCompanion extends UpdateCompanion<LocalNoteBlock> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<String> type;
  final Value<String> content;
  final Value<bool> isChecked;
  final Value<int> position;
  final Value<int> rowid;
  const LocalNoteBlocksCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalNoteBlocksCompanion.insert({
    required String id,
    required String noteId,
    required String type,
    this.content = const Value.absent(),
    this.isChecked = const Value.absent(),
    required int position,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        noteId = Value(noteId),
        type = Value(type),
        position = Value(position);
  static Insertable<LocalNoteBlock> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<String>? type,
    Expression<String>? content,
    Expression<bool>? isChecked,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (isChecked != null) 'is_checked': isChecked,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalNoteBlocksCompanion copyWith(
      {Value<String>? id,
      Value<String>? noteId,
      Value<String>? type,
      Value<String>? content,
      Value<bool>? isChecked,
      Value<int>? position,
      Value<int>? rowid}) {
    return LocalNoteBlocksCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      type: type ?? this.type,
      content: content ?? this.content,
      isChecked: isChecked ?? this.isChecked,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isChecked.present) {
      map['is_checked'] = Variable<bool>(isChecked.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNoteBlocksCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('isChecked: $isChecked, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalNoteLinksTable extends LocalNoteLinks
    with TableInfo<$LocalNoteLinksTable, LocalNoteLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNoteLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_notes (id) ON DELETE CASCADE'));
  static const VerificationMeta _targetIdMeta =
      const VerificationMeta('targetId');
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
      'target_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_notes (id) ON DELETE CASCADE'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('related'));
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        sourceId,
        targetId,
        type,
        label,
        createdAt,
        isDeleted,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_note_links';
  @override
  VerificationContext validateIntegrity(Insertable<LocalNoteLink> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(_targetIdMeta,
          targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta));
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {sourceId, targetId, type},
      ];
  @override
  LocalNoteLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalNoteLink(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      targetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalNoteLinksTable createAlias(String alias) {
    return $LocalNoteLinksTable(attachedDatabase, alias);
  }
}

class LocalNoteLink extends DataClass implements Insertable<LocalNoteLink> {
  final String id;
  final String userId;
  final String sourceId;
  final String targetId;

  /// `related` | `seen` | `to_review` | `prerequisite`
  final String type;
  final String? label;
  final DateTime createdAt;
  final bool isDeleted;
  final bool isSynced;
  const LocalNoteLink(
      {required this.id,
      required this.userId,
      required this.sourceId,
      required this.targetId,
      required this.type,
      this.label,
      required this.createdAt,
      required this.isDeleted,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['source_id'] = Variable<String>(sourceId);
    map['target_id'] = Variable<String>(targetId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalNoteLinksCompanion toCompanion(bool nullToAbsent) {
    return LocalNoteLinksCompanion(
      id: Value(id),
      userId: Value(userId),
      sourceId: Value(sourceId),
      targetId: Value(targetId),
      type: Value(type),
      label:
          label == null && nullToAbsent ? const Value.absent() : Value(label),
      createdAt: Value(createdAt),
      isDeleted: Value(isDeleted),
      isSynced: Value(isSynced),
    );
  }

  factory LocalNoteLink.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalNoteLink(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      targetId: serializer.fromJson<String>(json['targetId']),
      type: serializer.fromJson<String>(json['type']),
      label: serializer.fromJson<String?>(json['label']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'sourceId': serializer.toJson<String>(sourceId),
      'targetId': serializer.toJson<String>(targetId),
      'type': serializer.toJson<String>(type),
      'label': serializer.toJson<String?>(label),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalNoteLink copyWith(
          {String? id,
          String? userId,
          String? sourceId,
          String? targetId,
          String? type,
          Value<String?> label = const Value.absent(),
          DateTime? createdAt,
          bool? isDeleted,
          bool? isSynced}) =>
      LocalNoteLink(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        sourceId: sourceId ?? this.sourceId,
        targetId: targetId ?? this.targetId,
        type: type ?? this.type,
        label: label.present ? label.value : this.label,
        createdAt: createdAt ?? this.createdAt,
        isDeleted: isDeleted ?? this.isDeleted,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalNoteLink copyWithCompanion(LocalNoteLinksCompanion data) {
    return LocalNoteLink(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      type: data.type.present ? data.type.value : this.type,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalNoteLink(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('sourceId: $sourceId, ')
          ..write('targetId: $targetId, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, sourceId, targetId, type, label,
      createdAt, isDeleted, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalNoteLink &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.sourceId == this.sourceId &&
          other.targetId == this.targetId &&
          other.type == this.type &&
          other.label == this.label &&
          other.createdAt == this.createdAt &&
          other.isDeleted == this.isDeleted &&
          other.isSynced == this.isSynced);
}

class LocalNoteLinksCompanion extends UpdateCompanion<LocalNoteLink> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> sourceId;
  final Value<String> targetId;
  final Value<String> type;
  final Value<String?> label;
  final Value<DateTime> createdAt;
  final Value<bool> isDeleted;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalNoteLinksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.targetId = const Value.absent(),
    this.type = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalNoteLinksCompanion.insert({
    required String id,
    required String userId,
    required String sourceId,
    required String targetId,
    this.type = const Value.absent(),
    this.label = const Value.absent(),
    required DateTime createdAt,
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        sourceId = Value(sourceId),
        targetId = Value(targetId),
        createdAt = Value(createdAt);
  static Insertable<LocalNoteLink> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? sourceId,
    Expression<String>? targetId,
    Expression<String>? type,
    Expression<String>? label,
    Expression<DateTime>? createdAt,
    Expression<bool>? isDeleted,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (sourceId != null) 'source_id': sourceId,
      if (targetId != null) 'target_id': targetId,
      if (type != null) 'type': type,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalNoteLinksCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? sourceId,
      Value<String>? targetId,
      Value<String>? type,
      Value<String?>? label,
      Value<DateTime>? createdAt,
      Value<bool>? isDeleted,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalNoteLinksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
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
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNoteLinksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('sourceId: $sourceId, ')
          ..write('targetId: $targetId, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalFlashcardsTable extends LocalFlashcards
    with TableInfo<$LocalFlashcardsTable, LocalFlashcard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFlashcardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_notes (id) ON DELETE SET NULL'));
  static const VerificationMeta _frontMeta = const VerificationMeta('front');
  @override
  late final GeneratedColumn<String> front = GeneratedColumn<String>(
      'front', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _backMeta = const VerificationMeta('back');
  @override
  late final GeneratedColumn<String> back = GeneratedColumn<String>(
      'back', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deckMeta = const VerificationMeta('deck');
  @override
  late final GeneratedColumn<String> deck = GeneratedColumn<String>(
      'deck', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
      'step', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _easeFactorMeta =
      const VerificationMeta('easeFactor');
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
      'ease_factor', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(2.5));
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
      'due_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastReviewedAtMeta =
      const VerificationMeta('lastReviewedAt');
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>('last_reviewed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _repetitionsMeta =
      const VerificationMeta('repetitions');
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
      'repetitions', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
      'lapses', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        noteId,
        front,
        back,
        deck,
        step,
        easeFactor,
        dueAt,
        lastReviewedAt,
        repetitions,
        lapses,
        createdAt,
        isDeleted,
        isSynced,
        folderId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_flashcards';
  @override
  VerificationContext validateIntegrity(Insertable<LocalFlashcard> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    }
    if (data.containsKey('front')) {
      context.handle(
          _frontMeta, front.isAcceptableOrUnknown(data['front']!, _frontMeta));
    } else if (isInserting) {
      context.missing(_frontMeta);
    }
    if (data.containsKey('back')) {
      context.handle(
          _backMeta, back.isAcceptableOrUnknown(data['back']!, _backMeta));
    } else if (isInserting) {
      context.missing(_backMeta);
    }
    if (data.containsKey('deck')) {
      context.handle(
          _deckMeta, deck.isAcceptableOrUnknown(data['deck']!, _deckMeta));
    }
    if (data.containsKey('step')) {
      context.handle(
          _stepMeta, step.isAcceptableOrUnknown(data['step']!, _stepMeta));
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
          _easeFactorMeta,
          easeFactor.isAcceptableOrUnknown(
              data['ease_factor']!, _easeFactorMeta));
    }
    if (data.containsKey('due_at')) {
      context.handle(
          _dueAtMeta, dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta));
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
          _lastReviewedAtMeta,
          lastReviewedAt.isAcceptableOrUnknown(
              data['last_reviewed_at']!, _lastReviewedAtMeta));
    }
    if (data.containsKey('repetitions')) {
      context.handle(
          _repetitionsMeta,
          repetitions.isAcceptableOrUnknown(
              data['repetitions']!, _repetitionsMeta));
    }
    if (data.containsKey('lapses')) {
      context.handle(_lapsesMeta,
          lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalFlashcard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFlashcard(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id']),
      front: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}front'])!,
      back: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}back'])!,
      deck: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}deck']),
      step: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}step'])!,
      easeFactor: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ease_factor'])!,
      dueAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_at'])!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_reviewed_at']),
      repetitions: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}repetitions'])!,
      lapses: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lapses'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_id']),
    );
  }

  @override
  $LocalFlashcardsTable createAlias(String alias) {
    return $LocalFlashcardsTable(attachedDatabase, alias);
  }
}

class LocalFlashcard extends DataClass implements Insertable<LocalFlashcard> {
  final String id;
  final String userId;

  /// Fiche d'origine. `setNull` et non `cascade` : supprimer une fiche ne doit
  /// pas détruire les cartes déjà mémorisées, ni l'historique de révision.
  final String? noteId;
  final String front;
  final String back;
  final String? deck;

  /// Rang atteint dans l'échelle des J (J+1, J+3, J+7…).
  final int step;
  final double easeFactor;
  final DateTime dueAt;
  final DateTime? lastReviewedAt;
  final int repetitions;
  final int lapses;
  final DateTime createdAt;
  final bool isDeleted;
  final bool isSynced;

  /// Dossier de l'explorateur (v13). `null` : à la racine.
  final String? folderId;
  const LocalFlashcard(
      {required this.id,
      required this.userId,
      this.noteId,
      required this.front,
      required this.back,
      this.deck,
      required this.step,
      required this.easeFactor,
      required this.dueAt,
      this.lastReviewedAt,
      required this.repetitions,
      required this.lapses,
      required this.createdAt,
      required this.isDeleted,
      required this.isSynced,
      this.folderId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<String>(noteId);
    }
    map['front'] = Variable<String>(front);
    map['back'] = Variable<String>(back);
    if (!nullToAbsent || deck != null) {
      map['deck'] = Variable<String>(deck);
    }
    map['step'] = Variable<int>(step);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['due_at'] = Variable<DateTime>(dueAt);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    map['repetitions'] = Variable<int>(repetitions);
    map['lapses'] = Variable<int>(lapses);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    return map;
  }

  LocalFlashcardsCompanion toCompanion(bool nullToAbsent) {
    return LocalFlashcardsCompanion(
      id: Value(id),
      userId: Value(userId),
      noteId:
          noteId == null && nullToAbsent ? const Value.absent() : Value(noteId),
      front: Value(front),
      back: Value(back),
      deck: deck == null && nullToAbsent ? const Value.absent() : Value(deck),
      step: Value(step),
      easeFactor: Value(easeFactor),
      dueAt: Value(dueAt),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      repetitions: Value(repetitions),
      lapses: Value(lapses),
      createdAt: Value(createdAt),
      isDeleted: Value(isDeleted),
      isSynced: Value(isSynced),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
    );
  }

  factory LocalFlashcard.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFlashcard(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      noteId: serializer.fromJson<String?>(json['noteId']),
      front: serializer.fromJson<String>(json['front']),
      back: serializer.fromJson<String>(json['back']),
      deck: serializer.fromJson<String?>(json['deck']),
      step: serializer.fromJson<int>(json['step']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      lapses: serializer.fromJson<int>(json['lapses']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      folderId: serializer.fromJson<String?>(json['folderId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'noteId': serializer.toJson<String?>(noteId),
      'front': serializer.toJson<String>(front),
      'back': serializer.toJson<String>(back),
      'deck': serializer.toJson<String?>(deck),
      'step': serializer.toJson<int>(step),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'repetitions': serializer.toJson<int>(repetitions),
      'lapses': serializer.toJson<int>(lapses),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isSynced': serializer.toJson<bool>(isSynced),
      'folderId': serializer.toJson<String?>(folderId),
    };
  }

  LocalFlashcard copyWith(
          {String? id,
          String? userId,
          Value<String?> noteId = const Value.absent(),
          String? front,
          String? back,
          Value<String?> deck = const Value.absent(),
          int? step,
          double? easeFactor,
          DateTime? dueAt,
          Value<DateTime?> lastReviewedAt = const Value.absent(),
          int? repetitions,
          int? lapses,
          DateTime? createdAt,
          bool? isDeleted,
          bool? isSynced,
          Value<String?> folderId = const Value.absent()}) =>
      LocalFlashcard(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        noteId: noteId.present ? noteId.value : this.noteId,
        front: front ?? this.front,
        back: back ?? this.back,
        deck: deck.present ? deck.value : this.deck,
        step: step ?? this.step,
        easeFactor: easeFactor ?? this.easeFactor,
        dueAt: dueAt ?? this.dueAt,
        lastReviewedAt:
            lastReviewedAt.present ? lastReviewedAt.value : this.lastReviewedAt,
        repetitions: repetitions ?? this.repetitions,
        lapses: lapses ?? this.lapses,
        createdAt: createdAt ?? this.createdAt,
        isDeleted: isDeleted ?? this.isDeleted,
        isSynced: isSynced ?? this.isSynced,
        folderId: folderId.present ? folderId.value : this.folderId,
      );
  LocalFlashcard copyWithCompanion(LocalFlashcardsCompanion data) {
    return LocalFlashcard(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
      deck: data.deck.present ? data.deck.value : this.deck,
      step: data.step.present ? data.step.value : this.step,
      easeFactor:
          data.easeFactor.present ? data.easeFactor.value : this.easeFactor,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      repetitions:
          data.repetitions.present ? data.repetitions.value : this.repetitions,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFlashcard(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('noteId: $noteId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('deck: $deck, ')
          ..write('step: $step, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('folderId: $folderId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      noteId,
      front,
      back,
      deck,
      step,
      easeFactor,
      dueAt,
      lastReviewedAt,
      repetitions,
      lapses,
      createdAt,
      isDeleted,
      isSynced,
      folderId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFlashcard &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.noteId == this.noteId &&
          other.front == this.front &&
          other.back == this.back &&
          other.deck == this.deck &&
          other.step == this.step &&
          other.easeFactor == this.easeFactor &&
          other.dueAt == this.dueAt &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.repetitions == this.repetitions &&
          other.lapses == this.lapses &&
          other.createdAt == this.createdAt &&
          other.isDeleted == this.isDeleted &&
          other.isSynced == this.isSynced &&
          other.folderId == this.folderId);
}

class LocalFlashcardsCompanion extends UpdateCompanion<LocalFlashcard> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> noteId;
  final Value<String> front;
  final Value<String> back;
  final Value<String?> deck;
  final Value<int> step;
  final Value<double> easeFactor;
  final Value<DateTime> dueAt;
  final Value<DateTime?> lastReviewedAt;
  final Value<int> repetitions;
  final Value<int> lapses;
  final Value<DateTime> createdAt;
  final Value<bool> isDeleted;
  final Value<bool> isSynced;
  final Value<String?> folderId;
  final Value<int> rowid;
  const LocalFlashcardsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.noteId = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.deck = const Value.absent(),
    this.step = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.folderId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalFlashcardsCompanion.insert({
    required String id,
    required String userId,
    this.noteId = const Value.absent(),
    required String front,
    required String back,
    this.deck = const Value.absent(),
    this.step = const Value.absent(),
    this.easeFactor = const Value.absent(),
    required DateTime dueAt,
    this.lastReviewedAt = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    required DateTime createdAt,
    this.isDeleted = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.folderId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        front = Value(front),
        back = Value(back),
        dueAt = Value(dueAt),
        createdAt = Value(createdAt);
  static Insertable<LocalFlashcard> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? noteId,
    Expression<String>? front,
    Expression<String>? back,
    Expression<String>? deck,
    Expression<int>? step,
    Expression<double>? easeFactor,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? lastReviewedAt,
    Expression<int>? repetitions,
    Expression<int>? lapses,
    Expression<DateTime>? createdAt,
    Expression<bool>? isDeleted,
    Expression<bool>? isSynced,
    Expression<String>? folderId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (noteId != null) 'note_id': noteId,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
      if (deck != null) 'deck': deck,
      if (step != null) 'step': step,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (dueAt != null) 'due_at': dueAt,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (repetitions != null) 'repetitions': repetitions,
      if (lapses != null) 'lapses': lapses,
      if (createdAt != null) 'created_at': createdAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isSynced != null) 'is_synced': isSynced,
      if (folderId != null) 'folder_id': folderId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalFlashcardsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? noteId,
      Value<String>? front,
      Value<String>? back,
      Value<String?>? deck,
      Value<int>? step,
      Value<double>? easeFactor,
      Value<DateTime>? dueAt,
      Value<DateTime?>? lastReviewedAt,
      Value<int>? repetitions,
      Value<int>? lapses,
      Value<DateTime>? createdAt,
      Value<bool>? isDeleted,
      Value<bool>? isSynced,
      Value<String?>? folderId,
      Value<int>? rowid}) {
    return LocalFlashcardsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      noteId: noteId ?? this.noteId,
      front: front ?? this.front,
      back: back ?? this.back,
      deck: deck ?? this.deck,
      step: step ?? this.step,
      easeFactor: easeFactor ?? this.easeFactor,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
      folderId: folderId ?? this.folderId,
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
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (front.present) {
      map['front'] = Variable<String>(front.value);
    }
    if (back.present) {
      map['back'] = Variable<String>(back.value);
    }
    if (deck.present) {
      map['deck'] = Variable<String>(deck.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFlashcardsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('noteId: $noteId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('deck: $deck, ')
          ..write('step: $step, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isSynced: $isSynced, ')
          ..write('folderId: $folderId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalReviewLogsTable extends LocalReviewLogs
    with TableInfo<$LocalReviewLogsTable, LocalReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
      'card_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_flashcards (id) ON DELETE CASCADE'));
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
      'grade', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _intervalDaysMeta =
      const VerificationMeta('intervalDays');
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
      'interval_days', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reviewedAtMeta =
      const VerificationMeta('reviewedAt');
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
      'reviewed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, cardId, grade, intervalDays, reviewedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_review_logs';
  @override
  VerificationContext validateIntegrity(Insertable<LocalReviewLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
          _gradeMeta, grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta));
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('interval_days')) {
      context.handle(
          _intervalDaysMeta,
          intervalDays.isAcceptableOrUnknown(
              data['interval_days']!, _intervalDaysMeta));
    } else if (isInserting) {
      context.missing(_intervalDaysMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
          _reviewedAtMeta,
          reviewedAt.isAcceptableOrUnknown(
              data['reviewed_at']!, _reviewedAtMeta));
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalReviewLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_id'])!,
      grade: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}grade'])!,
      intervalDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interval_days'])!,
      reviewedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}reviewed_at'])!,
    );
  }

  @override
  $LocalReviewLogsTable createAlias(String alias) {
    return $LocalReviewLogsTable(attachedDatabase, alias);
  }
}

class LocalReviewLog extends DataClass implements Insertable<LocalReviewLog> {
  final String id;
  final String userId;
  final String cardId;

  /// `again` | `hard` | `good` | `easy`
  final String grade;
  final int intervalDays;
  final DateTime reviewedAt;
  const LocalReviewLog(
      {required this.id,
      required this.userId,
      required this.cardId,
      required this.grade,
      required this.intervalDays,
      required this.reviewedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['card_id'] = Variable<String>(cardId);
    map['grade'] = Variable<String>(grade);
    map['interval_days'] = Variable<int>(intervalDays);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    return map;
  }

  LocalReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return LocalReviewLogsCompanion(
      id: Value(id),
      userId: Value(userId),
      cardId: Value(cardId),
      grade: Value(grade),
      intervalDays: Value(intervalDays),
      reviewedAt: Value(reviewedAt),
    );
  }

  factory LocalReviewLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalReviewLog(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      cardId: serializer.fromJson<String>(json['cardId']),
      grade: serializer.fromJson<String>(json['grade']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'cardId': serializer.toJson<String>(cardId),
      'grade': serializer.toJson<String>(grade),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
    };
  }

  LocalReviewLog copyWith(
          {String? id,
          String? userId,
          String? cardId,
          String? grade,
          int? intervalDays,
          DateTime? reviewedAt}) =>
      LocalReviewLog(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        cardId: cardId ?? this.cardId,
        grade: grade ?? this.grade,
        intervalDays: intervalDays ?? this.intervalDays,
        reviewedAt: reviewedAt ?? this.reviewedAt,
      );
  LocalReviewLog copyWithCompanion(LocalReviewLogsCompanion data) {
    return LocalReviewLog(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      grade: data.grade.present ? data.grade.value : this.grade,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      reviewedAt:
          data.reviewedAt.present ? data.reviewedAt.value : this.reviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalReviewLog(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('cardId: $cardId, ')
          ..write('grade: $grade, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('reviewedAt: $reviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, cardId, grade, intervalDays, reviewedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalReviewLog &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.cardId == this.cardId &&
          other.grade == this.grade &&
          other.intervalDays == this.intervalDays &&
          other.reviewedAt == this.reviewedAt);
}

class LocalReviewLogsCompanion extends UpdateCompanion<LocalReviewLog> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> cardId;
  final Value<String> grade;
  final Value<int> intervalDays;
  final Value<DateTime> reviewedAt;
  final Value<int> rowid;
  const LocalReviewLogsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.grade = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalReviewLogsCompanion.insert({
    required String id,
    required String userId,
    required String cardId,
    required String grade,
    required int intervalDays,
    required DateTime reviewedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        cardId = Value(cardId),
        grade = Value(grade),
        intervalDays = Value(intervalDays),
        reviewedAt = Value(reviewedAt);
  static Insertable<LocalReviewLog> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? cardId,
    Expression<String>? grade,
    Expression<int>? intervalDays,
    Expression<DateTime>? reviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (cardId != null) 'card_id': cardId,
      if (grade != null) 'grade': grade,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalReviewLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? cardId,
      Value<String>? grade,
      Value<int>? intervalDays,
      Value<DateTime>? reviewedAt,
      Value<int>? rowid}) {
    return LocalReviewLogsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardId: cardId ?? this.cardId,
      grade: grade ?? this.grade,
      intervalDays: intervalDays ?? this.intervalDays,
      reviewedAt: reviewedAt ?? this.reviewedAt,
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
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('cardId: $cardId, ')
          ..write('grade: $grade, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSq3rSessionsTable extends LocalSq3rSessions
    with TableInfo<$LocalSq3rSessionsTable, LocalSq3rSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSq3rSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_notes (id) ON DELETE CASCADE'));
  static const VerificationMeta _currentStepMeta =
      const VerificationMeta('currentStep');
  @override
  late final GeneratedColumn<int> currentStep = GeneratedColumn<int>(
      'current_step', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _surveyNotesMeta =
      const VerificationMeta('surveyNotes');
  @override
  late final GeneratedColumn<String> surveyNotes = GeneratedColumn<String>(
      'survey_notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _questionsMeta =
      const VerificationMeta('questions');
  @override
  late final GeneratedColumn<String> questions = GeneratedColumn<String>(
      'questions', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _reciteNotesMeta =
      const VerificationMeta('reciteNotes');
  @override
  late final GeneratedColumn<String> reciteNotes = GeneratedColumn<String>(
      'recite_notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _reviewNotesMeta =
      const VerificationMeta('reviewNotes');
  @override
  late final GeneratedColumn<String> reviewNotes = GeneratedColumn<String>(
      'review_notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        noteId,
        currentStep,
        surveyNotes,
        questions,
        reciteNotes,
        reviewNotes,
        createdAt,
        updatedAt,
        completedAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sq3r_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSq3rSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('current_step')) {
      context.handle(
          _currentStepMeta,
          currentStep.isAcceptableOrUnknown(
              data['current_step']!, _currentStepMeta));
    }
    if (data.containsKey('survey_notes')) {
      context.handle(
          _surveyNotesMeta,
          surveyNotes.isAcceptableOrUnknown(
              data['survey_notes']!, _surveyNotesMeta));
    }
    if (data.containsKey('questions')) {
      context.handle(_questionsMeta,
          questions.isAcceptableOrUnknown(data['questions']!, _questionsMeta));
    }
    if (data.containsKey('recite_notes')) {
      context.handle(
          _reciteNotesMeta,
          reciteNotes.isAcceptableOrUnknown(
              data['recite_notes']!, _reciteNotesMeta));
    }
    if (data.containsKey('review_notes')) {
      context.handle(
          _reviewNotesMeta,
          reviewNotes.isAcceptableOrUnknown(
              data['review_notes']!, _reviewNotesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {noteId},
      ];
  @override
  LocalSq3rSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSq3rSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      currentStep: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_step'])!,
      surveyNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}survey_notes'])!,
      questions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}questions'])!,
      reciteNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recite_notes'])!,
      reviewNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}review_notes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalSq3rSessionsTable createAlias(String alias) {
    return $LocalSq3rSessionsTable(attachedDatabase, alias);
  }
}

class LocalSq3rSession extends DataClass
    implements Insertable<LocalSq3rSession> {
  final String id;
  final String userId;
  final String noteId;

  /// 0 = Survey, 1 = Question, 2 = Read, 3 = Recite, 4 = Review.
  final int currentStep;
  final String surveyNotes;

  /// Questions posées avant lecture, sérialisées en JSON.
  final String questions;
  final String reciteNotes;
  final String reviewNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool isSynced;
  const LocalSq3rSession(
      {required this.id,
      required this.userId,
      required this.noteId,
      required this.currentStep,
      required this.surveyNotes,
      required this.questions,
      required this.reciteNotes,
      required this.reviewNotes,
      required this.createdAt,
      required this.updatedAt,
      this.completedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['note_id'] = Variable<String>(noteId);
    map['current_step'] = Variable<int>(currentStep);
    map['survey_notes'] = Variable<String>(surveyNotes);
    map['questions'] = Variable<String>(questions);
    map['recite_notes'] = Variable<String>(reciteNotes);
    map['review_notes'] = Variable<String>(reviewNotes);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalSq3rSessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalSq3rSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      noteId: Value(noteId),
      currentStep: Value(currentStep),
      surveyNotes: Value(surveyNotes),
      questions: Value(questions),
      reciteNotes: Value(reciteNotes),
      reviewNotes: Value(reviewNotes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalSq3rSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSq3rSession(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      noteId: serializer.fromJson<String>(json['noteId']),
      currentStep: serializer.fromJson<int>(json['currentStep']),
      surveyNotes: serializer.fromJson<String>(json['surveyNotes']),
      questions: serializer.fromJson<String>(json['questions']),
      reciteNotes: serializer.fromJson<String>(json['reciteNotes']),
      reviewNotes: serializer.fromJson<String>(json['reviewNotes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'noteId': serializer.toJson<String>(noteId),
      'currentStep': serializer.toJson<int>(currentStep),
      'surveyNotes': serializer.toJson<String>(surveyNotes),
      'questions': serializer.toJson<String>(questions),
      'reciteNotes': serializer.toJson<String>(reciteNotes),
      'reviewNotes': serializer.toJson<String>(reviewNotes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalSq3rSession copyWith(
          {String? id,
          String? userId,
          String? noteId,
          int? currentStep,
          String? surveyNotes,
          String? questions,
          String? reciteNotes,
          String? reviewNotes,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> completedAt = const Value.absent(),
          bool? isSynced}) =>
      LocalSq3rSession(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        noteId: noteId ?? this.noteId,
        currentStep: currentStep ?? this.currentStep,
        surveyNotes: surveyNotes ?? this.surveyNotes,
        questions: questions ?? this.questions,
        reciteNotes: reciteNotes ?? this.reciteNotes,
        reviewNotes: reviewNotes ?? this.reviewNotes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalSq3rSession copyWithCompanion(LocalSq3rSessionsCompanion data) {
    return LocalSq3rSession(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      currentStep:
          data.currentStep.present ? data.currentStep.value : this.currentStep,
      surveyNotes:
          data.surveyNotes.present ? data.surveyNotes.value : this.surveyNotes,
      questions: data.questions.present ? data.questions.value : this.questions,
      reciteNotes:
          data.reciteNotes.present ? data.reciteNotes.value : this.reciteNotes,
      reviewNotes:
          data.reviewNotes.present ? data.reviewNotes.value : this.reviewNotes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSq3rSession(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('noteId: $noteId, ')
          ..write('currentStep: $currentStep, ')
          ..write('surveyNotes: $surveyNotes, ')
          ..write('questions: $questions, ')
          ..write('reciteNotes: $reciteNotes, ')
          ..write('reviewNotes: $reviewNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      noteId,
      currentStep,
      surveyNotes,
      questions,
      reciteNotes,
      reviewNotes,
      createdAt,
      updatedAt,
      completedAt,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSq3rSession &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.noteId == this.noteId &&
          other.currentStep == this.currentStep &&
          other.surveyNotes == this.surveyNotes &&
          other.questions == this.questions &&
          other.reciteNotes == this.reciteNotes &&
          other.reviewNotes == this.reviewNotes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt &&
          other.isSynced == this.isSynced);
}

class LocalSq3rSessionsCompanion extends UpdateCompanion<LocalSq3rSession> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> noteId;
  final Value<int> currentStep;
  final Value<String> surveyNotes;
  final Value<String> questions;
  final Value<String> reciteNotes;
  final Value<String> reviewNotes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> completedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalSq3rSessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.noteId = const Value.absent(),
    this.currentStep = const Value.absent(),
    this.surveyNotes = const Value.absent(),
    this.questions = const Value.absent(),
    this.reciteNotes = const Value.absent(),
    this.reviewNotes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSq3rSessionsCompanion.insert({
    required String id,
    required String userId,
    required String noteId,
    this.currentStep = const Value.absent(),
    this.surveyNotes = const Value.absent(),
    this.questions = const Value.absent(),
    this.reciteNotes = const Value.absent(),
    this.reviewNotes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.completedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        noteId = Value(noteId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalSq3rSession> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? noteId,
    Expression<int>? currentStep,
    Expression<String>? surveyNotes,
    Expression<String>? questions,
    Expression<String>? reciteNotes,
    Expression<String>? reviewNotes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? completedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (noteId != null) 'note_id': noteId,
      if (currentStep != null) 'current_step': currentStep,
      if (surveyNotes != null) 'survey_notes': surveyNotes,
      if (questions != null) 'questions': questions,
      if (reciteNotes != null) 'recite_notes': reciteNotes,
      if (reviewNotes != null) 'review_notes': reviewNotes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSq3rSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? noteId,
      Value<int>? currentStep,
      Value<String>? surveyNotes,
      Value<String>? questions,
      Value<String>? reciteNotes,
      Value<String>? reviewNotes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? completedAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalSq3rSessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      noteId: noteId ?? this.noteId,
      currentStep: currentStep ?? this.currentStep,
      surveyNotes: surveyNotes ?? this.surveyNotes,
      questions: questions ?? this.questions,
      reciteNotes: reciteNotes ?? this.reciteNotes,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (currentStep.present) {
      map['current_step'] = Variable<int>(currentStep.value);
    }
    if (surveyNotes.present) {
      map['survey_notes'] = Variable<String>(surveyNotes.value);
    }
    if (questions.present) {
      map['questions'] = Variable<String>(questions.value);
    }
    if (reciteNotes.present) {
      map['recite_notes'] = Variable<String>(reciteNotes.value);
    }
    if (reviewNotes.present) {
      map['review_notes'] = Variable<String>(reviewNotes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSq3rSessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('noteId: $noteId, ')
          ..write('currentStep: $currentStep, ')
          ..write('surveyNotes: $surveyNotes, ')
          ..write('questions: $questions, ')
          ..write('reciteNotes: $reciteNotes, ')
          ..write('reviewNotes: $reviewNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalExplanationsTable extends LocalExplanations
    with TableInfo<$LocalExplanationsTable, LocalExplanation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalExplanationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_notes (id) ON DELETE CASCADE'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<int> confidence = GeneratedColumn<int>(
      'confidence', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, noteId, content, confidence, createdAt, isSynced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_explanations';
  @override
  VerificationContext validateIntegrity(Insertable<LocalExplanation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalExplanation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalExplanation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}confidence'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalExplanationsTable createAlias(String alias) {
    return $LocalExplanationsTable(attachedDatabase, alias);
  }
}

class LocalExplanation extends DataClass
    implements Insertable<LocalExplanation> {
  final String id;
  final String userId;
  final String noteId;
  final String content;

  /// Confiance ressentie, de 1 à 5 : l'auto-évaluation fait partie de la
  /// démarche métacognitive.
  final int confidence;
  final DateTime createdAt;
  final bool isSynced;
  const LocalExplanation(
      {required this.id,
      required this.userId,
      required this.noteId,
      required this.content,
      required this.confidence,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['note_id'] = Variable<String>(noteId);
    map['content'] = Variable<String>(content);
    map['confidence'] = Variable<int>(confidence);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalExplanationsCompanion toCompanion(bool nullToAbsent) {
    return LocalExplanationsCompanion(
      id: Value(id),
      userId: Value(userId),
      noteId: Value(noteId),
      content: Value(content),
      confidence: Value(confidence),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalExplanation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalExplanation(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      noteId: serializer.fromJson<String>(json['noteId']),
      content: serializer.fromJson<String>(json['content']),
      confidence: serializer.fromJson<int>(json['confidence']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'noteId': serializer.toJson<String>(noteId),
      'content': serializer.toJson<String>(content),
      'confidence': serializer.toJson<int>(confidence),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalExplanation copyWith(
          {String? id,
          String? userId,
          String? noteId,
          String? content,
          int? confidence,
          DateTime? createdAt,
          bool? isSynced}) =>
      LocalExplanation(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        noteId: noteId ?? this.noteId,
        content: content ?? this.content,
        confidence: confidence ?? this.confidence,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalExplanation copyWithCompanion(LocalExplanationsCompanion data) {
    return LocalExplanation(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      content: data.content.present ? data.content.value : this.content,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalExplanation(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('noteId: $noteId, ')
          ..write('content: $content, ')
          ..write('confidence: $confidence, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, noteId, content, confidence, createdAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalExplanation &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.noteId == this.noteId &&
          other.content == this.content &&
          other.confidence == this.confidence &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalExplanationsCompanion extends UpdateCompanion<LocalExplanation> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> noteId;
  final Value<String> content;
  final Value<int> confidence;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalExplanationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.noteId = const Value.absent(),
    this.content = const Value.absent(),
    this.confidence = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalExplanationsCompanion.insert({
    required String id,
    required String userId,
    required String noteId,
    required String content,
    this.confidence = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        noteId = Value(noteId),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<LocalExplanation> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? noteId,
    Expression<String>? content,
    Expression<int>? confidence,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (noteId != null) 'note_id': noteId,
      if (content != null) 'content': content,
      if (confidence != null) 'confidence': confidence,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalExplanationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? noteId,
      Value<String>? content,
      Value<int>? confidence,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalExplanationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      noteId: noteId ?? this.noteId,
      content: content ?? this.content,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<int>(confidence.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalExplanationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('noteId: $noteId, ')
          ..write('content: $content, ')
          ..write('confidence: $confidence, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalJournalEntriesTable extends LocalJournalEntries
    with TableInfo<$LocalJournalEntriesTable, LocalJournalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalJournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_notes (id) ON DELETE SET NULL'));
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
      'mood', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _energyMeta = const VerificationMeta('energy');
  @override
  late final GeneratedColumn<int> energy = GeneratedColumn<int>(
      'energy', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<int> rpe = GeneratedColumn<int>(
      'rpe', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _whatLearnedMeta =
      const VerificationMeta('whatLearned');
  @override
  late final GeneratedColumn<String> whatLearned = GeneratedColumn<String>(
      'what_learned', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _whatWorkedMeta =
      const VerificationMeta('whatWorked');
  @override
  late final GeneratedColumn<String> whatWorked = GeneratedColumn<String>(
      'what_worked', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _whatBlockedMeta =
      const VerificationMeta('whatBlocked');
  @override
  late final GeneratedColumn<String> whatBlocked = GeneratedColumn<String>(
      'what_blocked', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _nextStepMeta =
      const VerificationMeta('nextStep');
  @override
  late final GeneratedColumn<String> nextStep = GeneratedColumn<String>(
      'next_step', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        noteId,
        mood,
        energy,
        rpe,
        whatLearned,
        whatWorked,
        whatBlocked,
        nextStep,
        createdAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_journal_entries';
  @override
  VerificationContext validateIntegrity(Insertable<LocalJournalEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    }
    if (data.containsKey('mood')) {
      context.handle(
          _moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    }
    if (data.containsKey('energy')) {
      context.handle(_energyMeta,
          energy.isAcceptableOrUnknown(data['energy']!, _energyMeta));
    }
    if (data.containsKey('rpe')) {
      context.handle(
          _rpeMeta, rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta));
    }
    if (data.containsKey('what_learned')) {
      context.handle(
          _whatLearnedMeta,
          whatLearned.isAcceptableOrUnknown(
              data['what_learned']!, _whatLearnedMeta));
    }
    if (data.containsKey('what_worked')) {
      context.handle(
          _whatWorkedMeta,
          whatWorked.isAcceptableOrUnknown(
              data['what_worked']!, _whatWorkedMeta));
    }
    if (data.containsKey('what_blocked')) {
      context.handle(
          _whatBlockedMeta,
          whatBlocked.isAcceptableOrUnknown(
              data['what_blocked']!, _whatBlockedMeta));
    }
    if (data.containsKey('next_step')) {
      context.handle(_nextStepMeta,
          nextStep.isAcceptableOrUnknown(data['next_step']!, _nextStepMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalJournalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalJournalEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id']),
      mood: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mood'])!,
      energy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}energy'])!,
      rpe: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rpe'])!,
      whatLearned: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}what_learned'])!,
      whatWorked: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}what_worked'])!,
      whatBlocked: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}what_blocked'])!,
      nextStep: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}next_step'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalJournalEntriesTable createAlias(String alias) {
    return $LocalJournalEntriesTable(attachedDatabase, alias);
  }
}

class LocalJournalEntry extends DataClass
    implements Insertable<LocalJournalEntry> {
  final String id;
  final String userId;

  /// Fiche ou notion travaillée, si la session en visait une.
  final String? noteId;

  /// Humeur ressentie, de 1 (très bas) à 5 (très bien).
  final int mood;

  /// Énergie disponible, de 1 à 5.
  final int energy;

  /// RPE — perception de l'effort, de 1 à 10. Exigence explicite du CdC :
  /// « tracker le RPE ⇒ perception de la difficulté ».
  final int rpe;
  final String whatLearned;
  final String whatWorked;
  final String whatBlocked;
  final String nextStep;
  final DateTime createdAt;
  final bool isSynced;
  const LocalJournalEntry(
      {required this.id,
      required this.userId,
      this.noteId,
      required this.mood,
      required this.energy,
      required this.rpe,
      required this.whatLearned,
      required this.whatWorked,
      required this.whatBlocked,
      required this.nextStep,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<String>(noteId);
    }
    map['mood'] = Variable<int>(mood);
    map['energy'] = Variable<int>(energy);
    map['rpe'] = Variable<int>(rpe);
    map['what_learned'] = Variable<String>(whatLearned);
    map['what_worked'] = Variable<String>(whatWorked);
    map['what_blocked'] = Variable<String>(whatBlocked);
    map['next_step'] = Variable<String>(nextStep);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalJournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return LocalJournalEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      noteId:
          noteId == null && nullToAbsent ? const Value.absent() : Value(noteId),
      mood: Value(mood),
      energy: Value(energy),
      rpe: Value(rpe),
      whatLearned: Value(whatLearned),
      whatWorked: Value(whatWorked),
      whatBlocked: Value(whatBlocked),
      nextStep: Value(nextStep),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalJournalEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalJournalEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      noteId: serializer.fromJson<String?>(json['noteId']),
      mood: serializer.fromJson<int>(json['mood']),
      energy: serializer.fromJson<int>(json['energy']),
      rpe: serializer.fromJson<int>(json['rpe']),
      whatLearned: serializer.fromJson<String>(json['whatLearned']),
      whatWorked: serializer.fromJson<String>(json['whatWorked']),
      whatBlocked: serializer.fromJson<String>(json['whatBlocked']),
      nextStep: serializer.fromJson<String>(json['nextStep']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'noteId': serializer.toJson<String?>(noteId),
      'mood': serializer.toJson<int>(mood),
      'energy': serializer.toJson<int>(energy),
      'rpe': serializer.toJson<int>(rpe),
      'whatLearned': serializer.toJson<String>(whatLearned),
      'whatWorked': serializer.toJson<String>(whatWorked),
      'whatBlocked': serializer.toJson<String>(whatBlocked),
      'nextStep': serializer.toJson<String>(nextStep),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalJournalEntry copyWith(
          {String? id,
          String? userId,
          Value<String?> noteId = const Value.absent(),
          int? mood,
          int? energy,
          int? rpe,
          String? whatLearned,
          String? whatWorked,
          String? whatBlocked,
          String? nextStep,
          DateTime? createdAt,
          bool? isSynced}) =>
      LocalJournalEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        noteId: noteId.present ? noteId.value : this.noteId,
        mood: mood ?? this.mood,
        energy: energy ?? this.energy,
        rpe: rpe ?? this.rpe,
        whatLearned: whatLearned ?? this.whatLearned,
        whatWorked: whatWorked ?? this.whatWorked,
        whatBlocked: whatBlocked ?? this.whatBlocked,
        nextStep: nextStep ?? this.nextStep,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalJournalEntry copyWithCompanion(LocalJournalEntriesCompanion data) {
    return LocalJournalEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      mood: data.mood.present ? data.mood.value : this.mood,
      energy: data.energy.present ? data.energy.value : this.energy,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      whatLearned:
          data.whatLearned.present ? data.whatLearned.value : this.whatLearned,
      whatWorked:
          data.whatWorked.present ? data.whatWorked.value : this.whatWorked,
      whatBlocked:
          data.whatBlocked.present ? data.whatBlocked.value : this.whatBlocked,
      nextStep: data.nextStep.present ? data.nextStep.value : this.nextStep,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalJournalEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('noteId: $noteId, ')
          ..write('mood: $mood, ')
          ..write('energy: $energy, ')
          ..write('rpe: $rpe, ')
          ..write('whatLearned: $whatLearned, ')
          ..write('whatWorked: $whatWorked, ')
          ..write('whatBlocked: $whatBlocked, ')
          ..write('nextStep: $nextStep, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, noteId, mood, energy, rpe,
      whatLearned, whatWorked, whatBlocked, nextStep, createdAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalJournalEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.noteId == this.noteId &&
          other.mood == this.mood &&
          other.energy == this.energy &&
          other.rpe == this.rpe &&
          other.whatLearned == this.whatLearned &&
          other.whatWorked == this.whatWorked &&
          other.whatBlocked == this.whatBlocked &&
          other.nextStep == this.nextStep &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalJournalEntriesCompanion extends UpdateCompanion<LocalJournalEntry> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> noteId;
  final Value<int> mood;
  final Value<int> energy;
  final Value<int> rpe;
  final Value<String> whatLearned;
  final Value<String> whatWorked;
  final Value<String> whatBlocked;
  final Value<String> nextStep;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalJournalEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.noteId = const Value.absent(),
    this.mood = const Value.absent(),
    this.energy = const Value.absent(),
    this.rpe = const Value.absent(),
    this.whatLearned = const Value.absent(),
    this.whatWorked = const Value.absent(),
    this.whatBlocked = const Value.absent(),
    this.nextStep = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalJournalEntriesCompanion.insert({
    required String id,
    required String userId,
    this.noteId = const Value.absent(),
    this.mood = const Value.absent(),
    this.energy = const Value.absent(),
    this.rpe = const Value.absent(),
    this.whatLearned = const Value.absent(),
    this.whatWorked = const Value.absent(),
    this.whatBlocked = const Value.absent(),
    this.nextStep = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        createdAt = Value(createdAt);
  static Insertable<LocalJournalEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? noteId,
    Expression<int>? mood,
    Expression<int>? energy,
    Expression<int>? rpe,
    Expression<String>? whatLearned,
    Expression<String>? whatWorked,
    Expression<String>? whatBlocked,
    Expression<String>? nextStep,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (noteId != null) 'note_id': noteId,
      if (mood != null) 'mood': mood,
      if (energy != null) 'energy': energy,
      if (rpe != null) 'rpe': rpe,
      if (whatLearned != null) 'what_learned': whatLearned,
      if (whatWorked != null) 'what_worked': whatWorked,
      if (whatBlocked != null) 'what_blocked': whatBlocked,
      if (nextStep != null) 'next_step': nextStep,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalJournalEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? noteId,
      Value<int>? mood,
      Value<int>? energy,
      Value<int>? rpe,
      Value<String>? whatLearned,
      Value<String>? whatWorked,
      Value<String>? whatBlocked,
      Value<String>? nextStep,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalJournalEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      noteId: noteId ?? this.noteId,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      rpe: rpe ?? this.rpe,
      whatLearned: whatLearned ?? this.whatLearned,
      whatWorked: whatWorked ?? this.whatWorked,
      whatBlocked: whatBlocked ?? this.whatBlocked,
      nextStep: nextStep ?? this.nextStep,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (energy.present) {
      map['energy'] = Variable<int>(energy.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<int>(rpe.value);
    }
    if (whatLearned.present) {
      map['what_learned'] = Variable<String>(whatLearned.value);
    }
    if (whatWorked.present) {
      map['what_worked'] = Variable<String>(whatWorked.value);
    }
    if (whatBlocked.present) {
      map['what_blocked'] = Variable<String>(whatBlocked.value);
    }
    if (nextStep.present) {
      map['next_step'] = Variable<String>(nextStep.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalJournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('noteId: $noteId, ')
          ..write('mood: $mood, ')
          ..write('energy: $energy, ')
          ..write('rpe: $rpe, ')
          ..write('whatLearned: $whatLearned, ')
          ..write('whatWorked: $whatWorked, ')
          ..write('whatBlocked: $whatBlocked, ')
          ..write('nextStep: $nextStep, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalReframesTable extends LocalReframes
    with TableInfo<$LocalReframesTable, LocalReframe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalReframesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _limitingThoughtMeta =
      const VerificationMeta('limitingThought');
  @override
  late final GeneratedColumn<String> limitingThought = GeneratedColumn<String>(
      'limiting_thought', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _distortionMeta =
      const VerificationMeta('distortion');
  @override
  late final GeneratedColumn<String> distortion = GeneratedColumn<String>(
      'distortion', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _evidenceAgainstMeta =
      const VerificationMeta('evidenceAgainst');
  @override
  late final GeneratedColumn<String> evidenceAgainst = GeneratedColumn<String>(
      'evidence_against', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _reframedThoughtMeta =
      const VerificationMeta('reframedThought');
  @override
  late final GeneratedColumn<String> reframedThought = GeneratedColumn<String>(
      'reframed_thought', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _growthGoalMeta =
      const VerificationMeta('growthGoal');
  @override
  late final GeneratedColumn<String> growthGoal = GeneratedColumn<String>(
      'growth_goal', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        limitingThought,
        distortion,
        evidenceAgainst,
        reframedThought,
        growthGoal,
        createdAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_reframes';
  @override
  VerificationContext validateIntegrity(Insertable<LocalReframe> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('limiting_thought')) {
      context.handle(
          _limitingThoughtMeta,
          limitingThought.isAcceptableOrUnknown(
              data['limiting_thought']!, _limitingThoughtMeta));
    } else if (isInserting) {
      context.missing(_limitingThoughtMeta);
    }
    if (data.containsKey('distortion')) {
      context.handle(
          _distortionMeta,
          distortion.isAcceptableOrUnknown(
              data['distortion']!, _distortionMeta));
    }
    if (data.containsKey('evidence_against')) {
      context.handle(
          _evidenceAgainstMeta,
          evidenceAgainst.isAcceptableOrUnknown(
              data['evidence_against']!, _evidenceAgainstMeta));
    }
    if (data.containsKey('reframed_thought')) {
      context.handle(
          _reframedThoughtMeta,
          reframedThought.isAcceptableOrUnknown(
              data['reframed_thought']!, _reframedThoughtMeta));
    }
    if (data.containsKey('growth_goal')) {
      context.handle(
          _growthGoalMeta,
          growthGoal.isAcceptableOrUnknown(
              data['growth_goal']!, _growthGoalMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalReframe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalReframe(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      limitingThought: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}limiting_thought'])!,
      distortion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}distortion']),
      evidenceAgainst: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}evidence_against'])!,
      reframedThought: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reframed_thought'])!,
      growthGoal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}growth_goal'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalReframesTable createAlias(String alias) {
    return $LocalReframesTable(attachedDatabase, alias);
  }
}

class LocalReframe extends DataClass implements Insertable<LocalReframe> {
  final String id;
  final String userId;
  final String limitingThought;

  /// Distorsion repérée : `all_or_nothing`, `overgeneralisation`…
  final String? distortion;
  final String evidenceAgainst;
  final String reframedThought;
  final String growthGoal;
  final DateTime createdAt;
  final bool isSynced;
  const LocalReframe(
      {required this.id,
      required this.userId,
      required this.limitingThought,
      this.distortion,
      required this.evidenceAgainst,
      required this.reframedThought,
      required this.growthGoal,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['limiting_thought'] = Variable<String>(limitingThought);
    if (!nullToAbsent || distortion != null) {
      map['distortion'] = Variable<String>(distortion);
    }
    map['evidence_against'] = Variable<String>(evidenceAgainst);
    map['reframed_thought'] = Variable<String>(reframedThought);
    map['growth_goal'] = Variable<String>(growthGoal);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalReframesCompanion toCompanion(bool nullToAbsent) {
    return LocalReframesCompanion(
      id: Value(id),
      userId: Value(userId),
      limitingThought: Value(limitingThought),
      distortion: distortion == null && nullToAbsent
          ? const Value.absent()
          : Value(distortion),
      evidenceAgainst: Value(evidenceAgainst),
      reframedThought: Value(reframedThought),
      growthGoal: Value(growthGoal),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalReframe.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalReframe(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      limitingThought: serializer.fromJson<String>(json['limitingThought']),
      distortion: serializer.fromJson<String?>(json['distortion']),
      evidenceAgainst: serializer.fromJson<String>(json['evidenceAgainst']),
      reframedThought: serializer.fromJson<String>(json['reframedThought']),
      growthGoal: serializer.fromJson<String>(json['growthGoal']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'limitingThought': serializer.toJson<String>(limitingThought),
      'distortion': serializer.toJson<String?>(distortion),
      'evidenceAgainst': serializer.toJson<String>(evidenceAgainst),
      'reframedThought': serializer.toJson<String>(reframedThought),
      'growthGoal': serializer.toJson<String>(growthGoal),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalReframe copyWith(
          {String? id,
          String? userId,
          String? limitingThought,
          Value<String?> distortion = const Value.absent(),
          String? evidenceAgainst,
          String? reframedThought,
          String? growthGoal,
          DateTime? createdAt,
          bool? isSynced}) =>
      LocalReframe(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        limitingThought: limitingThought ?? this.limitingThought,
        distortion: distortion.present ? distortion.value : this.distortion,
        evidenceAgainst: evidenceAgainst ?? this.evidenceAgainst,
        reframedThought: reframedThought ?? this.reframedThought,
        growthGoal: growthGoal ?? this.growthGoal,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalReframe copyWithCompanion(LocalReframesCompanion data) {
    return LocalReframe(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      limitingThought: data.limitingThought.present
          ? data.limitingThought.value
          : this.limitingThought,
      distortion:
          data.distortion.present ? data.distortion.value : this.distortion,
      evidenceAgainst: data.evidenceAgainst.present
          ? data.evidenceAgainst.value
          : this.evidenceAgainst,
      reframedThought: data.reframedThought.present
          ? data.reframedThought.value
          : this.reframedThought,
      growthGoal:
          data.growthGoal.present ? data.growthGoal.value : this.growthGoal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalReframe(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('limitingThought: $limitingThought, ')
          ..write('distortion: $distortion, ')
          ..write('evidenceAgainst: $evidenceAgainst, ')
          ..write('reframedThought: $reframedThought, ')
          ..write('growthGoal: $growthGoal, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, limitingThought, distortion,
      evidenceAgainst, reframedThought, growthGoal, createdAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalReframe &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.limitingThought == this.limitingThought &&
          other.distortion == this.distortion &&
          other.evidenceAgainst == this.evidenceAgainst &&
          other.reframedThought == this.reframedThought &&
          other.growthGoal == this.growthGoal &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalReframesCompanion extends UpdateCompanion<LocalReframe> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> limitingThought;
  final Value<String?> distortion;
  final Value<String> evidenceAgainst;
  final Value<String> reframedThought;
  final Value<String> growthGoal;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalReframesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.limitingThought = const Value.absent(),
    this.distortion = const Value.absent(),
    this.evidenceAgainst = const Value.absent(),
    this.reframedThought = const Value.absent(),
    this.growthGoal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalReframesCompanion.insert({
    required String id,
    required String userId,
    required String limitingThought,
    this.distortion = const Value.absent(),
    this.evidenceAgainst = const Value.absent(),
    this.reframedThought = const Value.absent(),
    this.growthGoal = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        limitingThought = Value(limitingThought),
        createdAt = Value(createdAt);
  static Insertable<LocalReframe> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? limitingThought,
    Expression<String>? distortion,
    Expression<String>? evidenceAgainst,
    Expression<String>? reframedThought,
    Expression<String>? growthGoal,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (limitingThought != null) 'limiting_thought': limitingThought,
      if (distortion != null) 'distortion': distortion,
      if (evidenceAgainst != null) 'evidence_against': evidenceAgainst,
      if (reframedThought != null) 'reframed_thought': reframedThought,
      if (growthGoal != null) 'growth_goal': growthGoal,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalReframesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? limitingThought,
      Value<String?>? distortion,
      Value<String>? evidenceAgainst,
      Value<String>? reframedThought,
      Value<String>? growthGoal,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalReframesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      limitingThought: limitingThought ?? this.limitingThought,
      distortion: distortion ?? this.distortion,
      evidenceAgainst: evidenceAgainst ?? this.evidenceAgainst,
      reframedThought: reframedThought ?? this.reframedThought,
      growthGoal: growthGoal ?? this.growthGoal,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (limitingThought.present) {
      map['limiting_thought'] = Variable<String>(limitingThought.value);
    }
    if (distortion.present) {
      map['distortion'] = Variable<String>(distortion.value);
    }
    if (evidenceAgainst.present) {
      map['evidence_against'] = Variable<String>(evidenceAgainst.value);
    }
    if (reframedThought.present) {
      map['reframed_thought'] = Variable<String>(reframedThought.value);
    }
    if (growthGoal.present) {
      map['growth_goal'] = Variable<String>(growthGoal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalReframesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('limitingThought: $limitingThought, ')
          ..write('distortion: $distortion, ')
          ..write('evidenceAgainst: $evidenceAgainst, ')
          ..write('reframedThought: $reframedThought, ')
          ..write('growthGoal: $growthGoal, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalWhyChainsTable extends LocalWhyChains
    with TableInfo<$LocalWhyChainsTable, LocalWhyChain> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalWhyChainsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _problemMeta =
      const VerificationMeta('problem');
  @override
  late final GeneratedColumn<String> problem = GeneratedColumn<String>(
      'problem', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answersMeta =
      const VerificationMeta('answers');
  @override
  late final GeneratedColumn<String> answers = GeneratedColumn<String>(
      'answers', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _rootCauseMeta =
      const VerificationMeta('rootCause');
  @override
  late final GeneratedColumn<String> rootCause = GeneratedColumn<String>(
      'root_cause', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _blockerTypeMeta =
      const VerificationMeta('blockerType');
  @override
  late final GeneratedColumn<String> blockerType = GeneratedColumn<String>(
      'blocker_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actionPlanMeta =
      const VerificationMeta('actionPlan');
  @override
  late final GeneratedColumn<String> actionPlan = GeneratedColumn<String>(
      'action_plan', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        problem,
        answers,
        rootCause,
        blockerType,
        actionPlan,
        createdAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_why_chains';
  @override
  VerificationContext validateIntegrity(Insertable<LocalWhyChain> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('problem')) {
      context.handle(_problemMeta,
          problem.isAcceptableOrUnknown(data['problem']!, _problemMeta));
    } else if (isInserting) {
      context.missing(_problemMeta);
    }
    if (data.containsKey('answers')) {
      context.handle(_answersMeta,
          answers.isAcceptableOrUnknown(data['answers']!, _answersMeta));
    }
    if (data.containsKey('root_cause')) {
      context.handle(_rootCauseMeta,
          rootCause.isAcceptableOrUnknown(data['root_cause']!, _rootCauseMeta));
    }
    if (data.containsKey('blocker_type')) {
      context.handle(
          _blockerTypeMeta,
          blockerType.isAcceptableOrUnknown(
              data['blocker_type']!, _blockerTypeMeta));
    }
    if (data.containsKey('action_plan')) {
      context.handle(
          _actionPlanMeta,
          actionPlan.isAcceptableOrUnknown(
              data['action_plan']!, _actionPlanMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalWhyChain map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalWhyChain(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      problem: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}problem'])!,
      answers: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answers'])!,
      rootCause: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}root_cause'])!,
      blockerType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}blocker_type']),
      actionPlan: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action_plan'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalWhyChainsTable createAlias(String alias) {
    return $LocalWhyChainsTable(attachedDatabase, alias);
  }
}

class LocalWhyChain extends DataClass implements Insertable<LocalWhyChain> {
  final String id;
  final String userId;
  final String problem;

  /// Les réponses successives, sérialisées en JSON (jusqu'à 5).
  final String answers;
  final String rootCause;

  /// `cognitive` | `emotional` | `sensory` | `environmental`
  final String? blockerType;
  final String actionPlan;
  final DateTime createdAt;
  final bool isSynced;
  const LocalWhyChain(
      {required this.id,
      required this.userId,
      required this.problem,
      required this.answers,
      required this.rootCause,
      this.blockerType,
      required this.actionPlan,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['problem'] = Variable<String>(problem);
    map['answers'] = Variable<String>(answers);
    map['root_cause'] = Variable<String>(rootCause);
    if (!nullToAbsent || blockerType != null) {
      map['blocker_type'] = Variable<String>(blockerType);
    }
    map['action_plan'] = Variable<String>(actionPlan);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalWhyChainsCompanion toCompanion(bool nullToAbsent) {
    return LocalWhyChainsCompanion(
      id: Value(id),
      userId: Value(userId),
      problem: Value(problem),
      answers: Value(answers),
      rootCause: Value(rootCause),
      blockerType: blockerType == null && nullToAbsent
          ? const Value.absent()
          : Value(blockerType),
      actionPlan: Value(actionPlan),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalWhyChain.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalWhyChain(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      problem: serializer.fromJson<String>(json['problem']),
      answers: serializer.fromJson<String>(json['answers']),
      rootCause: serializer.fromJson<String>(json['rootCause']),
      blockerType: serializer.fromJson<String?>(json['blockerType']),
      actionPlan: serializer.fromJson<String>(json['actionPlan']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'problem': serializer.toJson<String>(problem),
      'answers': serializer.toJson<String>(answers),
      'rootCause': serializer.toJson<String>(rootCause),
      'blockerType': serializer.toJson<String?>(blockerType),
      'actionPlan': serializer.toJson<String>(actionPlan),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalWhyChain copyWith(
          {String? id,
          String? userId,
          String? problem,
          String? answers,
          String? rootCause,
          Value<String?> blockerType = const Value.absent(),
          String? actionPlan,
          DateTime? createdAt,
          bool? isSynced}) =>
      LocalWhyChain(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        problem: problem ?? this.problem,
        answers: answers ?? this.answers,
        rootCause: rootCause ?? this.rootCause,
        blockerType: blockerType.present ? blockerType.value : this.blockerType,
        actionPlan: actionPlan ?? this.actionPlan,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalWhyChain copyWithCompanion(LocalWhyChainsCompanion data) {
    return LocalWhyChain(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      problem: data.problem.present ? data.problem.value : this.problem,
      answers: data.answers.present ? data.answers.value : this.answers,
      rootCause: data.rootCause.present ? data.rootCause.value : this.rootCause,
      blockerType:
          data.blockerType.present ? data.blockerType.value : this.blockerType,
      actionPlan:
          data.actionPlan.present ? data.actionPlan.value : this.actionPlan,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalWhyChain(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('problem: $problem, ')
          ..write('answers: $answers, ')
          ..write('rootCause: $rootCause, ')
          ..write('blockerType: $blockerType, ')
          ..write('actionPlan: $actionPlan, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, problem, answers, rootCause,
      blockerType, actionPlan, createdAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalWhyChain &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.problem == this.problem &&
          other.answers == this.answers &&
          other.rootCause == this.rootCause &&
          other.blockerType == this.blockerType &&
          other.actionPlan == this.actionPlan &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalWhyChainsCompanion extends UpdateCompanion<LocalWhyChain> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> problem;
  final Value<String> answers;
  final Value<String> rootCause;
  final Value<String?> blockerType;
  final Value<String> actionPlan;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalWhyChainsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.problem = const Value.absent(),
    this.answers = const Value.absent(),
    this.rootCause = const Value.absent(),
    this.blockerType = const Value.absent(),
    this.actionPlan = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalWhyChainsCompanion.insert({
    required String id,
    required String userId,
    required String problem,
    this.answers = const Value.absent(),
    this.rootCause = const Value.absent(),
    this.blockerType = const Value.absent(),
    this.actionPlan = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        problem = Value(problem),
        createdAt = Value(createdAt);
  static Insertable<LocalWhyChain> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? problem,
    Expression<String>? answers,
    Expression<String>? rootCause,
    Expression<String>? blockerType,
    Expression<String>? actionPlan,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (problem != null) 'problem': problem,
      if (answers != null) 'answers': answers,
      if (rootCause != null) 'root_cause': rootCause,
      if (blockerType != null) 'blocker_type': blockerType,
      if (actionPlan != null) 'action_plan': actionPlan,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalWhyChainsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? problem,
      Value<String>? answers,
      Value<String>? rootCause,
      Value<String?>? blockerType,
      Value<String>? actionPlan,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalWhyChainsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      problem: problem ?? this.problem,
      answers: answers ?? this.answers,
      rootCause: rootCause ?? this.rootCause,
      blockerType: blockerType ?? this.blockerType,
      actionPlan: actionPlan ?? this.actionPlan,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (problem.present) {
      map['problem'] = Variable<String>(problem.value);
    }
    if (answers.present) {
      map['answers'] = Variable<String>(answers.value);
    }
    if (rootCause.present) {
      map['root_cause'] = Variable<String>(rootCause.value);
    }
    if (blockerType.present) {
      map['blocker_type'] = Variable<String>(blockerType.value);
    }
    if (actionPlan.present) {
      map['action_plan'] = Variable<String>(actionPlan.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalWhyChainsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('problem: $problem, ')
          ..write('answers: $answers, ')
          ..write('rootCause: $rootCause, ')
          ..write('blockerType: $blockerType, ')
          ..write('actionPlan: $actionPlan, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalErrorLogsTable extends LocalErrorLogs
    with TableInfo<$LocalErrorLogsTable, LocalErrorLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalErrorLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_notes (id) ON DELETE SET NULL'));
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _errorTypeMeta =
      const VerificationMeta('errorType');
  @override
  late final GeneratedColumn<String> errorType = GeneratedColumn<String>(
      'error_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _correctionMeta =
      const VerificationMeta('correction');
  @override
  late final GeneratedColumn<String> correction = GeneratedColumn<String>(
      'correction', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        noteId,
        subject,
        description,
        errorType,
        correction,
        createdAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_error_logs';
  @override
  VerificationContext validateIntegrity(Insertable<LocalErrorLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('error_type')) {
      context.handle(_errorTypeMeta,
          errorType.isAcceptableOrUnknown(data['error_type']!, _errorTypeMeta));
    } else if (isInserting) {
      context.missing(_errorTypeMeta);
    }
    if (data.containsKey('correction')) {
      context.handle(
          _correctionMeta,
          correction.isAcceptableOrUnknown(
              data['correction']!, _correctionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalErrorLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalErrorLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id']),
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      errorType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_type'])!,
      correction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}correction'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalErrorLogsTable createAlias(String alias) {
    return $LocalErrorLogsTable(attachedDatabase, alias);
  }
}

class LocalErrorLog extends DataClass implements Insertable<LocalErrorLog> {
  final String id;
  final String userId;
  final String? noteId;
  final String? subject;
  final String description;

  /// `inattention` | `comprehension` | `method` | `memorisation` | `instructions`
  final String errorType;
  final String correction;
  final DateTime createdAt;
  final bool isSynced;
  const LocalErrorLog(
      {required this.id,
      required this.userId,
      this.noteId,
      this.subject,
      required this.description,
      required this.errorType,
      required this.correction,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<String>(noteId);
    }
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    map['description'] = Variable<String>(description);
    map['error_type'] = Variable<String>(errorType);
    map['correction'] = Variable<String>(correction);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalErrorLogsCompanion toCompanion(bool nullToAbsent) {
    return LocalErrorLogsCompanion(
      id: Value(id),
      userId: Value(userId),
      noteId:
          noteId == null && nullToAbsent ? const Value.absent() : Value(noteId),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      description: Value(description),
      errorType: Value(errorType),
      correction: Value(correction),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalErrorLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalErrorLog(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      noteId: serializer.fromJson<String?>(json['noteId']),
      subject: serializer.fromJson<String?>(json['subject']),
      description: serializer.fromJson<String>(json['description']),
      errorType: serializer.fromJson<String>(json['errorType']),
      correction: serializer.fromJson<String>(json['correction']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'noteId': serializer.toJson<String?>(noteId),
      'subject': serializer.toJson<String?>(subject),
      'description': serializer.toJson<String>(description),
      'errorType': serializer.toJson<String>(errorType),
      'correction': serializer.toJson<String>(correction),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalErrorLog copyWith(
          {String? id,
          String? userId,
          Value<String?> noteId = const Value.absent(),
          Value<String?> subject = const Value.absent(),
          String? description,
          String? errorType,
          String? correction,
          DateTime? createdAt,
          bool? isSynced}) =>
      LocalErrorLog(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        noteId: noteId.present ? noteId.value : this.noteId,
        subject: subject.present ? subject.value : this.subject,
        description: description ?? this.description,
        errorType: errorType ?? this.errorType,
        correction: correction ?? this.correction,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalErrorLog copyWithCompanion(LocalErrorLogsCompanion data) {
    return LocalErrorLog(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      subject: data.subject.present ? data.subject.value : this.subject,
      description:
          data.description.present ? data.description.value : this.description,
      errorType: data.errorType.present ? data.errorType.value : this.errorType,
      correction:
          data.correction.present ? data.correction.value : this.correction,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalErrorLog(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('noteId: $noteId, ')
          ..write('subject: $subject, ')
          ..write('description: $description, ')
          ..write('errorType: $errorType, ')
          ..write('correction: $correction, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, noteId, subject, description,
      errorType, correction, createdAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalErrorLog &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.noteId == this.noteId &&
          other.subject == this.subject &&
          other.description == this.description &&
          other.errorType == this.errorType &&
          other.correction == this.correction &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalErrorLogsCompanion extends UpdateCompanion<LocalErrorLog> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> noteId;
  final Value<String?> subject;
  final Value<String> description;
  final Value<String> errorType;
  final Value<String> correction;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalErrorLogsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.noteId = const Value.absent(),
    this.subject = const Value.absent(),
    this.description = const Value.absent(),
    this.errorType = const Value.absent(),
    this.correction = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalErrorLogsCompanion.insert({
    required String id,
    required String userId,
    this.noteId = const Value.absent(),
    this.subject = const Value.absent(),
    required String description,
    required String errorType,
    this.correction = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        description = Value(description),
        errorType = Value(errorType),
        createdAt = Value(createdAt);
  static Insertable<LocalErrorLog> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? noteId,
    Expression<String>? subject,
    Expression<String>? description,
    Expression<String>? errorType,
    Expression<String>? correction,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (noteId != null) 'note_id': noteId,
      if (subject != null) 'subject': subject,
      if (description != null) 'description': description,
      if (errorType != null) 'error_type': errorType,
      if (correction != null) 'correction': correction,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalErrorLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? noteId,
      Value<String?>? subject,
      Value<String>? description,
      Value<String>? errorType,
      Value<String>? correction,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalErrorLogsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      noteId: noteId ?? this.noteId,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      errorType: errorType ?? this.errorType,
      correction: correction ?? this.correction,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (errorType.present) {
      map['error_type'] = Variable<String>(errorType.value);
    }
    if (correction.present) {
      map['correction'] = Variable<String>(correction.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalErrorLogsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('noteId: $noteId, ')
          ..write('subject: $subject, ')
          ..write('description: $description, ')
          ..write('errorType: $errorType, ')
          ..write('correction: $correction, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalLearningProfilesTable extends LocalLearningProfiles
    with TableInfo<$LocalLearningProfilesTable, LocalLearningProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalLearningProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answersMeta =
      const VerificationMeta('answers');
  @override
  late final GeneratedColumn<String> answers = GeneratedColumn<String>(
      'answers', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _processingStyleMeta =
      const VerificationMeta('processingStyle');
  @override
  late final GeneratedColumn<String> processingStyle = GeneratedColumn<String>(
      'processing_style', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _preferredChannelMeta =
      const VerificationMeta('preferredChannel');
  @override
  late final GeneratedColumn<String> preferredChannel = GeneratedColumn<String>(
      'preferred_channel', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        answers,
        processingStyle,
        preferredChannel,
        completedAt,
        updatedAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_learning_profiles';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalLearningProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('answers')) {
      context.handle(_answersMeta,
          answers.isAcceptableOrUnknown(data['answers']!, _answersMeta));
    }
    if (data.containsKey('processing_style')) {
      context.handle(
          _processingStyleMeta,
          processingStyle.isAcceptableOrUnknown(
              data['processing_style']!, _processingStyleMeta));
    }
    if (data.containsKey('preferred_channel')) {
      context.handle(
          _preferredChannelMeta,
          preferredChannel.isAcceptableOrUnknown(
              data['preferred_channel']!, _preferredChannelMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalLearningProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalLearningProfile(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      answers: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answers'])!,
      processingStyle: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}processing_style']),
      preferredChannel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}preferred_channel']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalLearningProfilesTable createAlias(String alias) {
    return $LocalLearningProfilesTable(attachedDatabase, alias);
  }
}

class LocalLearningProfile extends DataClass
    implements Insertable<LocalLearningProfile> {
  final String userId;

  /// Réponses brutes au questionnaire, sérialisées en JSON.
  final String answers;

  /// `global` | `sequential`
  final String? processingStyle;

  /// `visual` | `auditory` | `kinesthetic` | `reading`
  final String? preferredChannel;
  final DateTime? completedAt;
  final DateTime updatedAt;
  final bool isSynced;
  const LocalLearningProfile(
      {required this.userId,
      required this.answers,
      this.processingStyle,
      this.preferredChannel,
      this.completedAt,
      required this.updatedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['answers'] = Variable<String>(answers);
    if (!nullToAbsent || processingStyle != null) {
      map['processing_style'] = Variable<String>(processingStyle);
    }
    if (!nullToAbsent || preferredChannel != null) {
      map['preferred_channel'] = Variable<String>(preferredChannel);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalLearningProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalLearningProfilesCompanion(
      userId: Value(userId),
      answers: Value(answers),
      processingStyle: processingStyle == null && nullToAbsent
          ? const Value.absent()
          : Value(processingStyle),
      preferredChannel: preferredChannel == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredChannel),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      updatedAt: Value(updatedAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalLearningProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalLearningProfile(
      userId: serializer.fromJson<String>(json['userId']),
      answers: serializer.fromJson<String>(json['answers']),
      processingStyle: serializer.fromJson<String?>(json['processingStyle']),
      preferredChannel: serializer.fromJson<String?>(json['preferredChannel']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'answers': serializer.toJson<String>(answers),
      'processingStyle': serializer.toJson<String?>(processingStyle),
      'preferredChannel': serializer.toJson<String?>(preferredChannel),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalLearningProfile copyWith(
          {String? userId,
          String? answers,
          Value<String?> processingStyle = const Value.absent(),
          Value<String?> preferredChannel = const Value.absent(),
          Value<DateTime?> completedAt = const Value.absent(),
          DateTime? updatedAt,
          bool? isSynced}) =>
      LocalLearningProfile(
        userId: userId ?? this.userId,
        answers: answers ?? this.answers,
        processingStyle: processingStyle.present
            ? processingStyle.value
            : this.processingStyle,
        preferredChannel: preferredChannel.present
            ? preferredChannel.value
            : this.preferredChannel,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalLearningProfile copyWithCompanion(LocalLearningProfilesCompanion data) {
    return LocalLearningProfile(
      userId: data.userId.present ? data.userId.value : this.userId,
      answers: data.answers.present ? data.answers.value : this.answers,
      processingStyle: data.processingStyle.present
          ? data.processingStyle.value
          : this.processingStyle,
      preferredChannel: data.preferredChannel.present
          ? data.preferredChannel.value
          : this.preferredChannel,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalLearningProfile(')
          ..write('userId: $userId, ')
          ..write('answers: $answers, ')
          ..write('processingStyle: $processingStyle, ')
          ..write('preferredChannel: $preferredChannel, ')
          ..write('completedAt: $completedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, answers, processingStyle,
      preferredChannel, completedAt, updatedAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalLearningProfile &&
          other.userId == this.userId &&
          other.answers == this.answers &&
          other.processingStyle == this.processingStyle &&
          other.preferredChannel == this.preferredChannel &&
          other.completedAt == this.completedAt &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced);
}

class LocalLearningProfilesCompanion
    extends UpdateCompanion<LocalLearningProfile> {
  final Value<String> userId;
  final Value<String> answers;
  final Value<String?> processingStyle;
  final Value<String?> preferredChannel;
  final Value<DateTime?> completedAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalLearningProfilesCompanion({
    this.userId = const Value.absent(),
    this.answers = const Value.absent(),
    this.processingStyle = const Value.absent(),
    this.preferredChannel = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalLearningProfilesCompanion.insert({
    required String userId,
    this.answers = const Value.absent(),
    this.processingStyle = const Value.absent(),
    this.preferredChannel = const Value.absent(),
    this.completedAt = const Value.absent(),
    required DateTime updatedAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        updatedAt = Value(updatedAt);
  static Insertable<LocalLearningProfile> custom({
    Expression<String>? userId,
    Expression<String>? answers,
    Expression<String>? processingStyle,
    Expression<String>? preferredChannel,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (answers != null) 'answers': answers,
      if (processingStyle != null) 'processing_style': processingStyle,
      if (preferredChannel != null) 'preferred_channel': preferredChannel,
      if (completedAt != null) 'completed_at': completedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalLearningProfilesCompanion copyWith(
      {Value<String>? userId,
      Value<String>? answers,
      Value<String?>? processingStyle,
      Value<String?>? preferredChannel,
      Value<DateTime?>? completedAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalLearningProfilesCompanion(
      userId: userId ?? this.userId,
      answers: answers ?? this.answers,
      processingStyle: processingStyle ?? this.processingStyle,
      preferredChannel: preferredChannel ?? this.preferredChannel,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (answers.present) {
      map['answers'] = Variable<String>(answers.value);
    }
    if (processingStyle.present) {
      map['processing_style'] = Variable<String>(processingStyle.value);
    }
    if (preferredChannel.present) {
      map['preferred_channel'] = Variable<String>(preferredChannel.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalLearningProfilesCompanion(')
          ..write('userId: $userId, ')
          ..write('answers: $answers, ')
          ..write('processingStyle: $processingStyle, ')
          ..write('preferredChannel: $preferredChannel, ')
          ..write('completedAt: $completedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStudyGoalsTable extends LocalStudyGoals
    with TableInfo<$LocalStudyGoalsTable, LocalStudyGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStudyGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metricLabelMeta =
      const VerificationMeta('metricLabel');
  @override
  late final GeneratedColumn<String> metricLabel = GeneratedColumn<String>(
      'metric_label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _targetValueMeta =
      const VerificationMeta('targetValue');
  @override
  late final GeneratedColumn<double> targetValue = GeneratedColumn<double>(
      'target_value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentValueMeta =
      const VerificationMeta('currentValue');
  @override
  late final GeneratedColumn<double> currentValue = GeneratedColumn<double>(
      'current_value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _achievablePlanMeta =
      const VerificationMeta('achievablePlan');
  @override
  late final GeneratedColumn<String> achievablePlan = GeneratedColumn<String>(
      'achievable_plan', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _relevanceMeta =
      const VerificationMeta('relevance');
  @override
  late final GeneratedColumn<String> relevance = GeneratedColumn<String>(
      'relevance', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _deadlineMeta =
      const VerificationMeta('deadline');
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
      'deadline', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        title,
        subject,
        metricLabel,
        targetValue,
        currentValue,
        achievablePlan,
        relevance,
        deadline,
        createdAt,
        completedAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_study_goals';
  @override
  VerificationContext validateIntegrity(Insertable<LocalStudyGoal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('metric_label')) {
      context.handle(
          _metricLabelMeta,
          metricLabel.isAcceptableOrUnknown(
              data['metric_label']!, _metricLabelMeta));
    }
    if (data.containsKey('target_value')) {
      context.handle(
          _targetValueMeta,
          targetValue.isAcceptableOrUnknown(
              data['target_value']!, _targetValueMeta));
    }
    if (data.containsKey('current_value')) {
      context.handle(
          _currentValueMeta,
          currentValue.isAcceptableOrUnknown(
              data['current_value']!, _currentValueMeta));
    }
    if (data.containsKey('achievable_plan')) {
      context.handle(
          _achievablePlanMeta,
          achievablePlan.isAcceptableOrUnknown(
              data['achievable_plan']!, _achievablePlanMeta));
    }
    if (data.containsKey('relevance')) {
      context.handle(_relevanceMeta,
          relevance.isAcceptableOrUnknown(data['relevance']!, _relevanceMeta));
    }
    if (data.containsKey('deadline')) {
      context.handle(_deadlineMeta,
          deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStudyGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStudyGoal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject']),
      metricLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metric_label'])!,
      targetValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_value'])!,
      currentValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}current_value'])!,
      achievablePlan: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}achievable_plan'])!,
      relevance: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relevance'])!,
      deadline: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deadline']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalStudyGoalsTable createAlias(String alias) {
    return $LocalStudyGoalsTable(attachedDatabase, alias);
  }
}

class LocalStudyGoal extends DataClass implements Insertable<LocalStudyGoal> {
  final String id;
  final String userId;

  /// S — l'objectif énoncé précisément.
  final String title;
  final String? subject;

  /// M — nom de l'unité mesurée (« chapitres », « exercices »), et cibles.
  final String metricLabel;
  final double targetValue;
  final double currentValue;

  /// A — ce qui rend l'objectif atteignable (moyens, disponibilité).
  final String achievablePlan;

  /// R — pourquoi il compte. Répond au « générateur de pourquoi » du CdC.
  final String relevance;

  /// T — l'échéance.
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isSynced;
  const LocalStudyGoal(
      {required this.id,
      required this.userId,
      required this.title,
      this.subject,
      required this.metricLabel,
      required this.targetValue,
      required this.currentValue,
      required this.achievablePlan,
      required this.relevance,
      this.deadline,
      required this.createdAt,
      this.completedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    map['metric_label'] = Variable<String>(metricLabel);
    map['target_value'] = Variable<double>(targetValue);
    map['current_value'] = Variable<double>(currentValue);
    map['achievable_plan'] = Variable<String>(achievablePlan);
    map['relevance'] = Variable<String>(relevance);
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalStudyGoalsCompanion toCompanion(bool nullToAbsent) {
    return LocalStudyGoalsCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      metricLabel: Value(metricLabel),
      targetValue: Value(targetValue),
      currentValue: Value(currentValue),
      achievablePlan: Value(achievablePlan),
      relevance: Value(relevance),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalStudyGoal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStudyGoal(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      subject: serializer.fromJson<String?>(json['subject']),
      metricLabel: serializer.fromJson<String>(json['metricLabel']),
      targetValue: serializer.fromJson<double>(json['targetValue']),
      currentValue: serializer.fromJson<double>(json['currentValue']),
      achievablePlan: serializer.fromJson<String>(json['achievablePlan']),
      relevance: serializer.fromJson<String>(json['relevance']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'subject': serializer.toJson<String?>(subject),
      'metricLabel': serializer.toJson<String>(metricLabel),
      'targetValue': serializer.toJson<double>(targetValue),
      'currentValue': serializer.toJson<double>(currentValue),
      'achievablePlan': serializer.toJson<String>(achievablePlan),
      'relevance': serializer.toJson<String>(relevance),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalStudyGoal copyWith(
          {String? id,
          String? userId,
          String? title,
          Value<String?> subject = const Value.absent(),
          String? metricLabel,
          double? targetValue,
          double? currentValue,
          String? achievablePlan,
          String? relevance,
          Value<DateTime?> deadline = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> completedAt = const Value.absent(),
          bool? isSynced}) =>
      LocalStudyGoal(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        subject: subject.present ? subject.value : this.subject,
        metricLabel: metricLabel ?? this.metricLabel,
        targetValue: targetValue ?? this.targetValue,
        currentValue: currentValue ?? this.currentValue,
        achievablePlan: achievablePlan ?? this.achievablePlan,
        relevance: relevance ?? this.relevance,
        deadline: deadline.present ? deadline.value : this.deadline,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalStudyGoal copyWithCompanion(LocalStudyGoalsCompanion data) {
    return LocalStudyGoal(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      subject: data.subject.present ? data.subject.value : this.subject,
      metricLabel:
          data.metricLabel.present ? data.metricLabel.value : this.metricLabel,
      targetValue:
          data.targetValue.present ? data.targetValue.value : this.targetValue,
      currentValue: data.currentValue.present
          ? data.currentValue.value
          : this.currentValue,
      achievablePlan: data.achievablePlan.present
          ? data.achievablePlan.value
          : this.achievablePlan,
      relevance: data.relevance.present ? data.relevance.value : this.relevance,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStudyGoal(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('metricLabel: $metricLabel, ')
          ..write('targetValue: $targetValue, ')
          ..write('currentValue: $currentValue, ')
          ..write('achievablePlan: $achievablePlan, ')
          ..write('relevance: $relevance, ')
          ..write('deadline: $deadline, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      title,
      subject,
      metricLabel,
      targetValue,
      currentValue,
      achievablePlan,
      relevance,
      deadline,
      createdAt,
      completedAt,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStudyGoal &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.subject == this.subject &&
          other.metricLabel == this.metricLabel &&
          other.targetValue == this.targetValue &&
          other.currentValue == this.currentValue &&
          other.achievablePlan == this.achievablePlan &&
          other.relevance == this.relevance &&
          other.deadline == this.deadline &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.isSynced == this.isSynced);
}

class LocalStudyGoalsCompanion extends UpdateCompanion<LocalStudyGoal> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String?> subject;
  final Value<String> metricLabel;
  final Value<double> targetValue;
  final Value<double> currentValue;
  final Value<String> achievablePlan;
  final Value<String> relevance;
  final Value<DateTime?> deadline;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalStudyGoalsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.subject = const Value.absent(),
    this.metricLabel = const Value.absent(),
    this.targetValue = const Value.absent(),
    this.currentValue = const Value.absent(),
    this.achievablePlan = const Value.absent(),
    this.relevance = const Value.absent(),
    this.deadline = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStudyGoalsCompanion.insert({
    required String id,
    required String userId,
    required String title,
    this.subject = const Value.absent(),
    this.metricLabel = const Value.absent(),
    this.targetValue = const Value.absent(),
    this.currentValue = const Value.absent(),
    this.achievablePlan = const Value.absent(),
    this.relevance = const Value.absent(),
    this.deadline = const Value.absent(),
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        createdAt = Value(createdAt);
  static Insertable<LocalStudyGoal> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? subject,
    Expression<String>? metricLabel,
    Expression<double>? targetValue,
    Expression<double>? currentValue,
    Expression<String>? achievablePlan,
    Expression<String>? relevance,
    Expression<DateTime>? deadline,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (subject != null) 'subject': subject,
      if (metricLabel != null) 'metric_label': metricLabel,
      if (targetValue != null) 'target_value': targetValue,
      if (currentValue != null) 'current_value': currentValue,
      if (achievablePlan != null) 'achievable_plan': achievablePlan,
      if (relevance != null) 'relevance': relevance,
      if (deadline != null) 'deadline': deadline,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStudyGoalsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? title,
      Value<String?>? subject,
      Value<String>? metricLabel,
      Value<double>? targetValue,
      Value<double>? currentValue,
      Value<String>? achievablePlan,
      Value<String>? relevance,
      Value<DateTime?>? deadline,
      Value<DateTime>? createdAt,
      Value<DateTime?>? completedAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalStudyGoalsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      metricLabel: metricLabel ?? this.metricLabel,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      achievablePlan: achievablePlan ?? this.achievablePlan,
      relevance: relevance ?? this.relevance,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (metricLabel.present) {
      map['metric_label'] = Variable<String>(metricLabel.value);
    }
    if (targetValue.present) {
      map['target_value'] = Variable<double>(targetValue.value);
    }
    if (currentValue.present) {
      map['current_value'] = Variable<double>(currentValue.value);
    }
    if (achievablePlan.present) {
      map['achievable_plan'] = Variable<String>(achievablePlan.value);
    }
    if (relevance.present) {
      map['relevance'] = Variable<String>(relevance.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStudyGoalsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('metricLabel: $metricLabel, ')
          ..write('targetValue: $targetValue, ')
          ..write('currentValue: $currentValue, ')
          ..write('achievablePlan: $achievablePlan, ')
          ..write('relevance: $relevance, ')
          ..write('deadline: $deadline, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPlanItemsTable extends LocalPlanItems
    with TableInfo<$LocalPlanItemsTable, LocalPlanItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlanItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
      'goal_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_study_goals (id) ON DELETE SET NULL'));
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
      'task_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
      'progress', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isMilestoneMeta =
      const VerificationMeta('isMilestone');
  @override
  late final GeneratedColumn<bool> isMilestone = GeneratedColumn<bool>(
      'is_milestone', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_milestone" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dependsOnIdMeta =
      const VerificationMeta('dependsOnId');
  @override
  late final GeneratedColumn<String> dependsOnId = GeneratedColumn<String>(
      'depends_on_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        goalId,
        taskId,
        title,
        subject,
        startDate,
        endDate,
        progress,
        isMilestone,
        dependsOnId,
        createdAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_plan_items';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPlanItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(_goalIdMeta,
          goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('is_milestone')) {
      context.handle(
          _isMilestoneMeta,
          isMilestone.isAcceptableOrUnknown(
              data['is_milestone']!, _isMilestoneMeta));
    }
    if (data.containsKey('depends_on_id')) {
      context.handle(
          _dependsOnIdMeta,
          dependsOnId.isAcceptableOrUnknown(
              data['depends_on_id']!, _dependsOnIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlanItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlanItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      goalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}goal_id']),
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}progress'])!,
      isMilestone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_milestone'])!,
      dependsOnId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}depends_on_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalPlanItemsTable createAlias(String alias) {
    return $LocalPlanItemsTable(attachedDatabase, alias);
  }
}

class LocalPlanItem extends DataClass implements Insertable<LocalPlanItem> {
  final String id;
  final String userId;
  final String? goalId;

  /// Lien avec le Kanban — « lien direct avec les cartes Trello et tâches ».
  final String? taskId;
  final String title;
  final String? subject;
  final DateTime startDate;
  final DateTime endDate;

  /// Avancement de 0 à 1.
  final double progress;

  /// Jalon : une date sans durée (examen, rendu).
  final bool isMilestone;

  /// Élément qui doit être terminé avant celui-ci.
  final String? dependsOnId;
  final DateTime createdAt;
  final bool isSynced;
  const LocalPlanItem(
      {required this.id,
      required this.userId,
      this.goalId,
      this.taskId,
      required this.title,
      this.subject,
      required this.startDate,
      required this.endDate,
      required this.progress,
      required this.isMilestone,
      this.dependsOnId,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || goalId != null) {
      map['goal_id'] = Variable<String>(goalId);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    map['progress'] = Variable<double>(progress);
    map['is_milestone'] = Variable<bool>(isMilestone);
    if (!nullToAbsent || dependsOnId != null) {
      map['depends_on_id'] = Variable<String>(dependsOnId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalPlanItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlanItemsCompanion(
      id: Value(id),
      userId: Value(userId),
      goalId:
          goalId == null && nullToAbsent ? const Value.absent() : Value(goalId),
      taskId:
          taskId == null && nullToAbsent ? const Value.absent() : Value(taskId),
      title: Value(title),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      startDate: Value(startDate),
      endDate: Value(endDate),
      progress: Value(progress),
      isMilestone: Value(isMilestone),
      dependsOnId: dependsOnId == null && nullToAbsent
          ? const Value.absent()
          : Value(dependsOnId),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalPlanItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlanItem(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      goalId: serializer.fromJson<String?>(json['goalId']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      title: serializer.fromJson<String>(json['title']),
      subject: serializer.fromJson<String?>(json['subject']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      progress: serializer.fromJson<double>(json['progress']),
      isMilestone: serializer.fromJson<bool>(json['isMilestone']),
      dependsOnId: serializer.fromJson<String?>(json['dependsOnId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'goalId': serializer.toJson<String?>(goalId),
      'taskId': serializer.toJson<String?>(taskId),
      'title': serializer.toJson<String>(title),
      'subject': serializer.toJson<String?>(subject),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'progress': serializer.toJson<double>(progress),
      'isMilestone': serializer.toJson<bool>(isMilestone),
      'dependsOnId': serializer.toJson<String?>(dependsOnId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalPlanItem copyWith(
          {String? id,
          String? userId,
          Value<String?> goalId = const Value.absent(),
          Value<String?> taskId = const Value.absent(),
          String? title,
          Value<String?> subject = const Value.absent(),
          DateTime? startDate,
          DateTime? endDate,
          double? progress,
          bool? isMilestone,
          Value<String?> dependsOnId = const Value.absent(),
          DateTime? createdAt,
          bool? isSynced}) =>
      LocalPlanItem(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        goalId: goalId.present ? goalId.value : this.goalId,
        taskId: taskId.present ? taskId.value : this.taskId,
        title: title ?? this.title,
        subject: subject.present ? subject.value : this.subject,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        progress: progress ?? this.progress,
        isMilestone: isMilestone ?? this.isMilestone,
        dependsOnId: dependsOnId.present ? dependsOnId.value : this.dependsOnId,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalPlanItem copyWithCompanion(LocalPlanItemsCompanion data) {
    return LocalPlanItem(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      title: data.title.present ? data.title.value : this.title,
      subject: data.subject.present ? data.subject.value : this.subject,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      progress: data.progress.present ? data.progress.value : this.progress,
      isMilestone:
          data.isMilestone.present ? data.isMilestone.value : this.isMilestone,
      dependsOnId:
          data.dependsOnId.present ? data.dependsOnId.value : this.dependsOnId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlanItem(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('goalId: $goalId, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('progress: $progress, ')
          ..write('isMilestone: $isMilestone, ')
          ..write('dependsOnId: $dependsOnId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      goalId,
      taskId,
      title,
      subject,
      startDate,
      endDate,
      progress,
      isMilestone,
      dependsOnId,
      createdAt,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlanItem &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.goalId == this.goalId &&
          other.taskId == this.taskId &&
          other.title == this.title &&
          other.subject == this.subject &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.progress == this.progress &&
          other.isMilestone == this.isMilestone &&
          other.dependsOnId == this.dependsOnId &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalPlanItemsCompanion extends UpdateCompanion<LocalPlanItem> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> goalId;
  final Value<String?> taskId;
  final Value<String> title;
  final Value<String?> subject;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<double> progress;
  final Value<bool> isMilestone;
  final Value<String?> dependsOnId;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalPlanItemsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.goalId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.title = const Value.absent(),
    this.subject = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.progress = const Value.absent(),
    this.isMilestone = const Value.absent(),
    this.dependsOnId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPlanItemsCompanion.insert({
    required String id,
    required String userId,
    this.goalId = const Value.absent(),
    this.taskId = const Value.absent(),
    required String title,
    this.subject = const Value.absent(),
    required DateTime startDate,
    required DateTime endDate,
    this.progress = const Value.absent(),
    this.isMilestone = const Value.absent(),
    this.dependsOnId = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        startDate = Value(startDate),
        endDate = Value(endDate),
        createdAt = Value(createdAt);
  static Insertable<LocalPlanItem> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? goalId,
    Expression<String>? taskId,
    Expression<String>? title,
    Expression<String>? subject,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<double>? progress,
    Expression<bool>? isMilestone,
    Expression<String>? dependsOnId,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (goalId != null) 'goal_id': goalId,
      if (taskId != null) 'task_id': taskId,
      if (title != null) 'title': title,
      if (subject != null) 'subject': subject,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (progress != null) 'progress': progress,
      if (isMilestone != null) 'is_milestone': isMilestone,
      if (dependsOnId != null) 'depends_on_id': dependsOnId,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPlanItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? goalId,
      Value<String?>? taskId,
      Value<String>? title,
      Value<String?>? subject,
      Value<DateTime>? startDate,
      Value<DateTime>? endDate,
      Value<double>? progress,
      Value<bool>? isMilestone,
      Value<String?>? dependsOnId,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalPlanItemsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalId: goalId ?? this.goalId,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      isMilestone: isMilestone ?? this.isMilestone,
      dependsOnId: dependsOnId ?? this.dependsOnId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (isMilestone.present) {
      map['is_milestone'] = Variable<bool>(isMilestone.value);
    }
    if (dependsOnId.present) {
      map['depends_on_id'] = Variable<String>(dependsOnId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlanItemsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('goalId: $goalId, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('progress: $progress, ')
          ..write('isMilestone: $isMilestone, ')
          ..write('dependsOnId: $dependsOnId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSpeedSamplesTable extends LocalSpeedSamples
    with TableInfo<$LocalSpeedSamplesTable, LocalSpeedSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSpeedSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activityMeta =
      const VerificationMeta('activity');
  @override
  late final GeneratedColumn<String> activity = GeneratedColumn<String>(
      'activity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unitsMeta = const VerificationMeta('units');
  @override
  late final GeneratedColumn<double> units = GeneratedColumn<double>(
      'units', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        activity,
        subject,
        units,
        durationSeconds,
        createdAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_speed_samples';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSpeedSample> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('activity')) {
      context.handle(_activityMeta,
          activity.isAcceptableOrUnknown(data['activity']!, _activityMeta));
    } else if (isInserting) {
      context.missing(_activityMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('units')) {
      context.handle(
          _unitsMeta, units.isAcceptableOrUnknown(data['units']!, _unitsMeta));
    } else if (isInserting) {
      context.missing(_unitsMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSpeedSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSpeedSample(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      activity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject']),
      units: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}units'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalSpeedSamplesTable createAlias(String alias) {
    return $LocalSpeedSamplesTable(attachedDatabase, alias);
  }
}

class LocalSpeedSample extends DataClass
    implements Insertable<LocalSpeedSample> {
  final String id;
  final String userId;

  /// `reading` | `writing` | `memorising` | `exercises`
  final String activity;
  final String? subject;

  /// Quantité traitée, dans l'unité de l'activité (pages, mots, cartes…).
  final double units;
  final int durationSeconds;
  final DateTime createdAt;
  final bool isSynced;
  const LocalSpeedSample(
      {required this.id,
      required this.userId,
      required this.activity,
      this.subject,
      required this.units,
      required this.durationSeconds,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['activity'] = Variable<String>(activity);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    map['units'] = Variable<double>(units);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalSpeedSamplesCompanion toCompanion(bool nullToAbsent) {
    return LocalSpeedSamplesCompanion(
      id: Value(id),
      userId: Value(userId),
      activity: Value(activity),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      units: Value(units),
      durationSeconds: Value(durationSeconds),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalSpeedSample.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSpeedSample(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      activity: serializer.fromJson<String>(json['activity']),
      subject: serializer.fromJson<String?>(json['subject']),
      units: serializer.fromJson<double>(json['units']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'activity': serializer.toJson<String>(activity),
      'subject': serializer.toJson<String?>(subject),
      'units': serializer.toJson<double>(units),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalSpeedSample copyWith(
          {String? id,
          String? userId,
          String? activity,
          Value<String?> subject = const Value.absent(),
          double? units,
          int? durationSeconds,
          DateTime? createdAt,
          bool? isSynced}) =>
      LocalSpeedSample(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        activity: activity ?? this.activity,
        subject: subject.present ? subject.value : this.subject,
        units: units ?? this.units,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalSpeedSample copyWithCompanion(LocalSpeedSamplesCompanion data) {
    return LocalSpeedSample(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      activity: data.activity.present ? data.activity.value : this.activity,
      subject: data.subject.present ? data.subject.value : this.subject,
      units: data.units.present ? data.units.value : this.units,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSpeedSample(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('activity: $activity, ')
          ..write('subject: $subject, ')
          ..write('units: $units, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, activity, subject, units,
      durationSeconds, createdAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSpeedSample &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.activity == this.activity &&
          other.subject == this.subject &&
          other.units == this.units &&
          other.durationSeconds == this.durationSeconds &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalSpeedSamplesCompanion extends UpdateCompanion<LocalSpeedSample> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> activity;
  final Value<String?> subject;
  final Value<double> units;
  final Value<int> durationSeconds;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalSpeedSamplesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.activity = const Value.absent(),
    this.subject = const Value.absent(),
    this.units = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSpeedSamplesCompanion.insert({
    required String id,
    required String userId,
    required String activity,
    this.subject = const Value.absent(),
    required double units,
    required int durationSeconds,
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        activity = Value(activity),
        units = Value(units),
        durationSeconds = Value(durationSeconds),
        createdAt = Value(createdAt);
  static Insertable<LocalSpeedSample> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? activity,
    Expression<String>? subject,
    Expression<double>? units,
    Expression<int>? durationSeconds,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (activity != null) 'activity': activity,
      if (subject != null) 'subject': subject,
      if (units != null) 'units': units,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSpeedSamplesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? activity,
      Value<String?>? subject,
      Value<double>? units,
      Value<int>? durationSeconds,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalSpeedSamplesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activity: activity ?? this.activity,
      subject: subject ?? this.subject,
      units: units ?? this.units,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (activity.present) {
      map['activity'] = Variable<String>(activity.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (units.present) {
      map['units'] = Variable<double>(units.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSpeedSamplesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('activity: $activity, ')
          ..write('subject: $subject, ')
          ..write('units: $units, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalExamTargetsTable extends LocalExamTargets
    with TableInfo<$LocalExamTargetsTable, LocalExamTarget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalExamTargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_notes (id) ON DELETE SET NULL'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _examWeightMeta =
      const VerificationMeta('examWeight');
  @override
  late final GeneratedColumn<double> examWeight = GeneratedColumn<double>(
      'exam_weight', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentGradeMeta =
      const VerificationMeta('currentGrade');
  @override
  late final GeneratedColumn<double> currentGrade = GeneratedColumn<double>(
      'current_grade', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _reachableGradeMeta =
      const VerificationMeta('reachableGrade');
  @override
  late final GeneratedColumn<double> reachableGrade = GeneratedColumn<double>(
      'reachable_grade', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(20));
  static const VerificationMeta _lengthHoursMeta =
      const VerificationMeta('lengthHours');
  @override
  late final GeneratedColumn<double> lengthHours = GeneratedColumn<double>(
      'length_hours', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _examDateMeta =
      const VerificationMeta('examDate');
  @override
  late final GeneratedColumn<DateTime> examDate = GeneratedColumn<DateTime>(
      'exam_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        noteId,
        title,
        subject,
        examWeight,
        currentGrade,
        reachableGrade,
        lengthHours,
        difficulty,
        examDate,
        createdAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_exam_targets';
  @override
  VerificationContext validateIntegrity(Insertable<LocalExamTarget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('exam_weight')) {
      context.handle(
          _examWeightMeta,
          examWeight.isAcceptableOrUnknown(
              data['exam_weight']!, _examWeightMeta));
    }
    if (data.containsKey('current_grade')) {
      context.handle(
          _currentGradeMeta,
          currentGrade.isAcceptableOrUnknown(
              data['current_grade']!, _currentGradeMeta));
    }
    if (data.containsKey('reachable_grade')) {
      context.handle(
          _reachableGradeMeta,
          reachableGrade.isAcceptableOrUnknown(
              data['reachable_grade']!, _reachableGradeMeta));
    }
    if (data.containsKey('length_hours')) {
      context.handle(
          _lengthHoursMeta,
          lengthHours.isAcceptableOrUnknown(
              data['length_hours']!, _lengthHoursMeta));
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    if (data.containsKey('exam_date')) {
      context.handle(_examDateMeta,
          examDate.isAcceptableOrUnknown(data['exam_date']!, _examDateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalExamTarget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalExamTarget(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject']),
      examWeight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}exam_weight'])!,
      currentGrade: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}current_grade'])!,
      reachableGrade: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}reachable_grade'])!,
      lengthHours: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}length_hours'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}difficulty'])!,
      examDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}exam_date']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalExamTargetsTable createAlias(String alias) {
    return $LocalExamTargetsTable(attachedDatabase, alias);
  }
}

class LocalExamTarget extends DataClass implements Insertable<LocalExamTarget> {
  final String id;
  final String userId;
  final String? noteId;
  final String title;
  final String? subject;

  /// Points que ce chapitre pèse dans l'examen.
  final double examWeight;

  /// Note actuelle estimée, sur 20.
  final double currentGrade;

  /// Note que l'on pense pouvoir atteindre, sur 20.
  final double reachableGrade;

  /// Longueur du cours, en heures de travail estimées.
  final double lengthHours;

  /// Difficulté ressentie, de 1 à 5.
  final int difficulty;
  final DateTime? examDate;
  final DateTime createdAt;
  final bool isSynced;
  const LocalExamTarget(
      {required this.id,
      required this.userId,
      this.noteId,
      required this.title,
      this.subject,
      required this.examWeight,
      required this.currentGrade,
      required this.reachableGrade,
      required this.lengthHours,
      required this.difficulty,
      this.examDate,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<String>(noteId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    map['exam_weight'] = Variable<double>(examWeight);
    map['current_grade'] = Variable<double>(currentGrade);
    map['reachable_grade'] = Variable<double>(reachableGrade);
    map['length_hours'] = Variable<double>(lengthHours);
    map['difficulty'] = Variable<int>(difficulty);
    if (!nullToAbsent || examDate != null) {
      map['exam_date'] = Variable<DateTime>(examDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalExamTargetsCompanion toCompanion(bool nullToAbsent) {
    return LocalExamTargetsCompanion(
      id: Value(id),
      userId: Value(userId),
      noteId:
          noteId == null && nullToAbsent ? const Value.absent() : Value(noteId),
      title: Value(title),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      examWeight: Value(examWeight),
      currentGrade: Value(currentGrade),
      reachableGrade: Value(reachableGrade),
      lengthHours: Value(lengthHours),
      difficulty: Value(difficulty),
      examDate: examDate == null && nullToAbsent
          ? const Value.absent()
          : Value(examDate),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalExamTarget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalExamTarget(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      noteId: serializer.fromJson<String?>(json['noteId']),
      title: serializer.fromJson<String>(json['title']),
      subject: serializer.fromJson<String?>(json['subject']),
      examWeight: serializer.fromJson<double>(json['examWeight']),
      currentGrade: serializer.fromJson<double>(json['currentGrade']),
      reachableGrade: serializer.fromJson<double>(json['reachableGrade']),
      lengthHours: serializer.fromJson<double>(json['lengthHours']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      examDate: serializer.fromJson<DateTime?>(json['examDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'noteId': serializer.toJson<String?>(noteId),
      'title': serializer.toJson<String>(title),
      'subject': serializer.toJson<String?>(subject),
      'examWeight': serializer.toJson<double>(examWeight),
      'currentGrade': serializer.toJson<double>(currentGrade),
      'reachableGrade': serializer.toJson<double>(reachableGrade),
      'lengthHours': serializer.toJson<double>(lengthHours),
      'difficulty': serializer.toJson<int>(difficulty),
      'examDate': serializer.toJson<DateTime?>(examDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalExamTarget copyWith(
          {String? id,
          String? userId,
          Value<String?> noteId = const Value.absent(),
          String? title,
          Value<String?> subject = const Value.absent(),
          double? examWeight,
          double? currentGrade,
          double? reachableGrade,
          double? lengthHours,
          int? difficulty,
          Value<DateTime?> examDate = const Value.absent(),
          DateTime? createdAt,
          bool? isSynced}) =>
      LocalExamTarget(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        noteId: noteId.present ? noteId.value : this.noteId,
        title: title ?? this.title,
        subject: subject.present ? subject.value : this.subject,
        examWeight: examWeight ?? this.examWeight,
        currentGrade: currentGrade ?? this.currentGrade,
        reachableGrade: reachableGrade ?? this.reachableGrade,
        lengthHours: lengthHours ?? this.lengthHours,
        difficulty: difficulty ?? this.difficulty,
        examDate: examDate.present ? examDate.value : this.examDate,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalExamTarget copyWithCompanion(LocalExamTargetsCompanion data) {
    return LocalExamTarget(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      title: data.title.present ? data.title.value : this.title,
      subject: data.subject.present ? data.subject.value : this.subject,
      examWeight:
          data.examWeight.present ? data.examWeight.value : this.examWeight,
      currentGrade: data.currentGrade.present
          ? data.currentGrade.value
          : this.currentGrade,
      reachableGrade: data.reachableGrade.present
          ? data.reachableGrade.value
          : this.reachableGrade,
      lengthHours:
          data.lengthHours.present ? data.lengthHours.value : this.lengthHours,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      examDate: data.examDate.present ? data.examDate.value : this.examDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalExamTarget(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('noteId: $noteId, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('examWeight: $examWeight, ')
          ..write('currentGrade: $currentGrade, ')
          ..write('reachableGrade: $reachableGrade, ')
          ..write('lengthHours: $lengthHours, ')
          ..write('difficulty: $difficulty, ')
          ..write('examDate: $examDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      noteId,
      title,
      subject,
      examWeight,
      currentGrade,
      reachableGrade,
      lengthHours,
      difficulty,
      examDate,
      createdAt,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalExamTarget &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.noteId == this.noteId &&
          other.title == this.title &&
          other.subject == this.subject &&
          other.examWeight == this.examWeight &&
          other.currentGrade == this.currentGrade &&
          other.reachableGrade == this.reachableGrade &&
          other.lengthHours == this.lengthHours &&
          other.difficulty == this.difficulty &&
          other.examDate == this.examDate &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalExamTargetsCompanion extends UpdateCompanion<LocalExamTarget> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> noteId;
  final Value<String> title;
  final Value<String?> subject;
  final Value<double> examWeight;
  final Value<double> currentGrade;
  final Value<double> reachableGrade;
  final Value<double> lengthHours;
  final Value<int> difficulty;
  final Value<DateTime?> examDate;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalExamTargetsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.noteId = const Value.absent(),
    this.title = const Value.absent(),
    this.subject = const Value.absent(),
    this.examWeight = const Value.absent(),
    this.currentGrade = const Value.absent(),
    this.reachableGrade = const Value.absent(),
    this.lengthHours = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.examDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalExamTargetsCompanion.insert({
    required String id,
    required String userId,
    this.noteId = const Value.absent(),
    required String title,
    this.subject = const Value.absent(),
    this.examWeight = const Value.absent(),
    this.currentGrade = const Value.absent(),
    this.reachableGrade = const Value.absent(),
    this.lengthHours = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.examDate = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        createdAt = Value(createdAt);
  static Insertable<LocalExamTarget> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? noteId,
    Expression<String>? title,
    Expression<String>? subject,
    Expression<double>? examWeight,
    Expression<double>? currentGrade,
    Expression<double>? reachableGrade,
    Expression<double>? lengthHours,
    Expression<int>? difficulty,
    Expression<DateTime>? examDate,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (noteId != null) 'note_id': noteId,
      if (title != null) 'title': title,
      if (subject != null) 'subject': subject,
      if (examWeight != null) 'exam_weight': examWeight,
      if (currentGrade != null) 'current_grade': currentGrade,
      if (reachableGrade != null) 'reachable_grade': reachableGrade,
      if (lengthHours != null) 'length_hours': lengthHours,
      if (difficulty != null) 'difficulty': difficulty,
      if (examDate != null) 'exam_date': examDate,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalExamTargetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? noteId,
      Value<String>? title,
      Value<String?>? subject,
      Value<double>? examWeight,
      Value<double>? currentGrade,
      Value<double>? reachableGrade,
      Value<double>? lengthHours,
      Value<int>? difficulty,
      Value<DateTime?>? examDate,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalExamTargetsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      noteId: noteId ?? this.noteId,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      examWeight: examWeight ?? this.examWeight,
      currentGrade: currentGrade ?? this.currentGrade,
      reachableGrade: reachableGrade ?? this.reachableGrade,
      lengthHours: lengthHours ?? this.lengthHours,
      difficulty: difficulty ?? this.difficulty,
      examDate: examDate ?? this.examDate,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (examWeight.present) {
      map['exam_weight'] = Variable<double>(examWeight.value);
    }
    if (currentGrade.present) {
      map['current_grade'] = Variable<double>(currentGrade.value);
    }
    if (reachableGrade.present) {
      map['reachable_grade'] = Variable<double>(reachableGrade.value);
    }
    if (lengthHours.present) {
      map['length_hours'] = Variable<double>(lengthHours.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (examDate.present) {
      map['exam_date'] = Variable<DateTime>(examDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalExamTargetsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('noteId: $noteId, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('examWeight: $examWeight, ')
          ..write('currentGrade: $currentGrade, ')
          ..write('reachableGrade: $reachableGrade, ')
          ..write('lengthHours: $lengthHours, ')
          ..write('difficulty: $difficulty, ')
          ..write('examDate: $examDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTasksTable extends LocalTasks
    with TableInfo<$LocalTasksTable, LocalTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('todo'));
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('medium'));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isUrgentMeta =
      const VerificationMeta('isUrgent');
  @override
  late final GeneratedColumn<bool> isUrgent = GeneratedColumn<bool>(
      'is_urgent', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_urgent" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isImportantMeta =
      const VerificationMeta('isImportant');
  @override
  late final GeneratedColumn<bool> isImportant = GeneratedColumn<bool>(
      'is_important', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_important" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        title,
        description,
        status,
        priority,
        dueDate,
        isUrgent,
        isImportant,
        position,
        createdAt,
        updatedAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<LocalTask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('is_urgent')) {
      context.handle(_isUrgentMeta,
          isUrgent.isAcceptableOrUnknown(data['is_urgent']!, _isUrgentMeta));
    }
    if (data.containsKey('is_important')) {
      context.handle(
          _isImportantMeta,
          isImportant.isAcceptableOrUnknown(
              data['is_important']!, _isImportantMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTask(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      isUrgent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_urgent'])!,
      isImportant: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_important'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalTasksTable createAlias(String alias) {
    return $LocalTasksTable(attachedDatabase, alias);
  }
}

class LocalTask extends DataClass implements Insertable<LocalTask> {
  final String id;
  final String userId;
  final String title;
  final String description;

  /// `todo` | `doing` | `done`
  final String status;

  /// `low` | `medium` | `high`
  final String priority;
  final DateTime? dueDate;
  final bool isUrgent;
  final bool isImportant;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  const LocalTask(
      {required this.id,
      required this.userId,
      required this.title,
      required this.description,
      required this.status,
      required this.priority,
      this.dueDate,
      required this.isUrgent,
      required this.isImportant,
      required this.position,
      required this.createdAt,
      required this.updatedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['is_urgent'] = Variable<bool>(isUrgent);
    map['is_important'] = Variable<bool>(isImportant);
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalTasksCompanion toCompanion(bool nullToAbsent) {
    return LocalTasksCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      description: Value(description),
      status: Value(status),
      priority: Value(priority),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      isUrgent: Value(isUrgent),
      isImportant: Value(isImportant),
      position: Value(position),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalTask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTask(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      isUrgent: serializer.fromJson<bool>(json['isUrgent']),
      isImportant: serializer.fromJson<bool>(json['isImportant']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'isUrgent': serializer.toJson<bool>(isUrgent),
      'isImportant': serializer.toJson<bool>(isImportant),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalTask copyWith(
          {String? id,
          String? userId,
          String? title,
          String? description,
          String? status,
          String? priority,
          Value<DateTime?> dueDate = const Value.absent(),
          bool? isUrgent,
          bool? isImportant,
          int? position,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? isSynced}) =>
      LocalTask(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        isUrgent: isUrgent ?? this.isUrgent,
        isImportant: isImportant ?? this.isImportant,
        position: position ?? this.position,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalTask copyWithCompanion(LocalTasksCompanion data) {
    return LocalTask(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      isUrgent: data.isUrgent.present ? data.isUrgent.value : this.isUrgent,
      isImportant:
          data.isImportant.present ? data.isImportant.value : this.isImportant,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTask(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueDate: $dueDate, ')
          ..write('isUrgent: $isUrgent, ')
          ..write('isImportant: $isImportant, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      title,
      description,
      status,
      priority,
      dueDate,
      isUrgent,
      isImportant,
      position,
      createdAt,
      updatedAt,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTask &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.description == this.description &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.dueDate == this.dueDate &&
          other.isUrgent == this.isUrgent &&
          other.isImportant == this.isImportant &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced);
}

class LocalTasksCompanion extends UpdateCompanion<LocalTask> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String> description;
  final Value<String> status;
  final Value<String> priority;
  final Value<DateTime?> dueDate;
  final Value<bool> isUrgent;
  final Value<bool> isImportant;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalTasksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isUrgent = const Value.absent(),
    this.isImportant = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTasksCompanion.insert({
    required String id,
    required String userId,
    required String title,
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isUrgent = const Value.absent(),
    this.isImportant = const Value.absent(),
    this.position = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalTask> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<DateTime>? dueDate,
    Expression<bool>? isUrgent,
    Expression<bool>? isImportant,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (dueDate != null) 'due_date': dueDate,
      if (isUrgent != null) 'is_urgent': isUrgent,
      if (isImportant != null) 'is_important': isImportant,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? title,
      Value<String>? description,
      Value<String>? status,
      Value<String>? priority,
      Value<DateTime?>? dueDate,
      Value<bool>? isUrgent,
      Value<bool>? isImportant,
      Value<int>? position,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalTasksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isUrgent: isUrgent ?? this.isUrgent,
      isImportant: isImportant ?? this.isImportant,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (isUrgent.present) {
      map['is_urgent'] = Variable<bool>(isUrgent.value);
    }
    if (isImportant.present) {
      map['is_important'] = Variable<bool>(isImportant.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTasksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueDate: $dueDate, ')
          ..write('isUrgent: $isUrgent, ')
          ..write('isImportant: $isImportant, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalHabitsTable extends LocalHabits
    with TableInfo<$LocalHabitsTable, LocalHabit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalHabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('daily'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
      'position', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, name, frequency, createdAt, isSynced, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_habits';
  @override
  VerificationContext validateIntegrity(Insertable<LocalHabit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalHabit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalHabit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}position']),
    );
  }

  @override
  $LocalHabitsTable createAlias(String alias) {
    return $LocalHabitsTable(attachedDatabase, alias);
  }
}

class LocalHabit extends DataClass implements Insertable<LocalHabit> {
  final String id;
  final String userId;
  final String name;

  /// `daily` | `weekly` | `monthly`
  final String frequency;
  final DateTime createdAt;
  final bool isSynced;

  /// Clé d'ordre manuel, synchronisée (cf. LocalNotes.position).
  final String? position;
  const LocalHabit(
      {required this.id,
      required this.userId,
      required this.name,
      required this.frequency,
      required this.createdAt,
      required this.isSynced,
      this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['frequency'] = Variable<String>(frequency);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<String>(position);
    }
    return map;
  }

  LocalHabitsCompanion toCompanion(bool nullToAbsent) {
    return LocalHabitsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      frequency: Value(frequency),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
    );
  }

  factory LocalHabit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalHabit(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      frequency: serializer.fromJson<String>(json['frequency']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      position: serializer.fromJson<String?>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'frequency': serializer.toJson<String>(frequency),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'position': serializer.toJson<String?>(position),
    };
  }

  LocalHabit copyWith(
          {String? id,
          String? userId,
          String? name,
          String? frequency,
          DateTime? createdAt,
          bool? isSynced,
          Value<String?> position = const Value.absent()}) =>
      LocalHabit(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        frequency: frequency ?? this.frequency,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
        position: position.present ? position.value : this.position,
      );
  LocalHabit copyWithCompanion(LocalHabitsCompanion data) {
    return LocalHabit(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalHabit(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('frequency: $frequency, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, name, frequency, createdAt, isSynced, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalHabit &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.frequency == this.frequency &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced &&
          other.position == this.position);
}

class LocalHabitsCompanion extends UpdateCompanion<LocalHabit> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> frequency;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<String?> position;
  final Value<int> rowid;
  const LocalHabitsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.frequency = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalHabitsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    this.frequency = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<LocalHabit> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? frequency,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<String>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (frequency != null) 'frequency': frequency,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalHabitsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? name,
      Value<String>? frequency,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<String?>? position,
      Value<int>? rowid}) {
    return LocalHabitsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      position: position ?? this.position,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalHabitsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('frequency: $frequency, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalHabitLogsTable extends LocalHabitLogs
    with TableInfo<$LocalHabitLogsTable, LocalHabitLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalHabitLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _habitIdMeta =
      const VerificationMeta('habitId');
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
      'habit_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_habits (id) ON DELETE CASCADE'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [habitId, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_habit_logs';
  @override
  VerificationContext validateIntegrity(Insertable<LocalHabitLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('habit_id')) {
      context.handle(_habitIdMeta,
          habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta));
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {habitId, date};
  @override
  LocalHabitLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalHabitLog(
      habitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}habit_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
    );
  }

  @override
  $LocalHabitLogsTable createAlias(String alias) {
    return $LocalHabitLogsTable(attachedDatabase, alias);
  }
}

class LocalHabitLog extends DataClass implements Insertable<LocalHabitLog> {
  final String habitId;

  /// Jour local au format `yyyy-MM-dd` (cf. `Habit.toDateKey`).
  final String date;
  const LocalHabitLog({required this.habitId, required this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['habit_id'] = Variable<String>(habitId);
    map['date'] = Variable<String>(date);
    return map;
  }

  LocalHabitLogsCompanion toCompanion(bool nullToAbsent) {
    return LocalHabitLogsCompanion(
      habitId: Value(habitId),
      date: Value(date),
    );
  }

  factory LocalHabitLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalHabitLog(
      habitId: serializer.fromJson<String>(json['habitId']),
      date: serializer.fromJson<String>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'habitId': serializer.toJson<String>(habitId),
      'date': serializer.toJson<String>(date),
    };
  }

  LocalHabitLog copyWith({String? habitId, String? date}) => LocalHabitLog(
        habitId: habitId ?? this.habitId,
        date: date ?? this.date,
      );
  LocalHabitLog copyWithCompanion(LocalHabitLogsCompanion data) {
    return LocalHabitLog(
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalHabitLog(')
          ..write('habitId: $habitId, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(habitId, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalHabitLog &&
          other.habitId == this.habitId &&
          other.date == this.date);
}

class LocalHabitLogsCompanion extends UpdateCompanion<LocalHabitLog> {
  final Value<String> habitId;
  final Value<String> date;
  final Value<int> rowid;
  const LocalHabitLogsCompanion({
    this.habitId = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalHabitLogsCompanion.insert({
    required String habitId,
    required String date,
    this.rowid = const Value.absent(),
  })  : habitId = Value(habitId),
        date = Value(date);
  static Insertable<LocalHabitLog> custom({
    Expression<String>? habitId,
    Expression<String>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (habitId != null) 'habit_id': habitId,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalHabitLogsCompanion copyWith(
      {Value<String>? habitId, Value<String>? date, Value<int>? rowid}) {
    return LocalHabitLogsCompanion(
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalHabitLogsCompanion(')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPomodoroSessionsTable extends LocalPomodoroSessions
    with TableInfo<$LocalPomodoroSessionsTable, LocalPomodoroSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPomodoroSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
      'task_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, startedAt, durationSeconds, taskId, isSynced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_pomodoro_sessions';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalPomodoroSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPomodoroSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPomodoroSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_id']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalPomodoroSessionsTable createAlias(String alias) {
    return $LocalPomodoroSessionsTable(attachedDatabase, alias);
  }
}

class LocalPomodoroSession extends DataClass
    implements Insertable<LocalPomodoroSession> {
  final String id;
  final String userId;
  final DateTime startedAt;
  final int durationSeconds;

  /// Volontairement sans clé étrangère locale : la tâche peut n'exister que
  /// sur un autre appareil, pas encore rapatriée.
  final String? taskId;
  final bool isSynced;
  const LocalPomodoroSession(
      {required this.id,
      required this.userId,
      required this.startedAt,
      required this.durationSeconds,
      this.taskId,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalPomodoroSessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalPomodoroSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      startedAt: Value(startedAt),
      durationSeconds: Value(durationSeconds),
      taskId:
          taskId == null && nullToAbsent ? const Value.absent() : Value(taskId),
      isSynced: Value(isSynced),
    );
  }

  factory LocalPomodoroSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPomodoroSession(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'taskId': serializer.toJson<String?>(taskId),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalPomodoroSession copyWith(
          {String? id,
          String? userId,
          DateTime? startedAt,
          int? durationSeconds,
          Value<String?> taskId = const Value.absent(),
          bool? isSynced}) =>
      LocalPomodoroSession(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        startedAt: startedAt ?? this.startedAt,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        taskId: taskId.present ? taskId.value : this.taskId,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalPomodoroSession copyWithCompanion(LocalPomodoroSessionsCompanion data) {
    return LocalPomodoroSession(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPomodoroSession(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('taskId: $taskId, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, startedAt, durationSeconds, taskId, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPomodoroSession &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.startedAt == this.startedAt &&
          other.durationSeconds == this.durationSeconds &&
          other.taskId == this.taskId &&
          other.isSynced == this.isSynced);
}

class LocalPomodoroSessionsCompanion
    extends UpdateCompanion<LocalPomodoroSession> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> startedAt;
  final Value<int> durationSeconds;
  final Value<String?> taskId;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalPomodoroSessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.taskId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPomodoroSessionsCompanion.insert({
    required String id,
    required String userId,
    required DateTime startedAt,
    required int durationSeconds,
    this.taskId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        startedAt = Value(startedAt),
        durationSeconds = Value(durationSeconds);
  static Insertable<LocalPomodoroSession> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? startedAt,
    Expression<int>? durationSeconds,
    Expression<String>? taskId,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (startedAt != null) 'started_at': startedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (taskId != null) 'task_id': taskId,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPomodoroSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<DateTime>? startedAt,
      Value<int>? durationSeconds,
      Value<String?>? taskId,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalPomodoroSessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      taskId: taskId ?? this.taskId,
      isSynced: isSynced ?? this.isSynced,
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
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPomodoroSessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('taskId: $taskId, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueEntriesTable extends SyncQueueEntries
    with TableInfo<$SyncQueueEntriesTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTableMeta =
      const VerificationMeta('entityTable');
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
      'entity_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _queuedAtMeta =
      const VerificationMeta('queuedAt');
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
      'queued_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, entityTable, entityId, operation, queuedAt, attempts, lastError];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_entries';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_table')) {
      context.handle(
          _entityTableMeta,
          entityTable.isAcceptableOrUnknown(
              data['entity_table']!, _entityTableMeta));
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(_queuedAtMeta,
          queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta));
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_table'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      queuedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}queued_at'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $SyncQueueEntriesTable createAlias(String alias) {
    return $SyncQueueEntriesTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final int id;
  final String entityTable;
  final String entityId;

  /// `upsert` | `delete`
  final String operation;
  final DateTime queuedAt;
  final int attempts;
  final String? lastError;
  const SyncQueueEntry(
      {required this.id,
      required this.entityTable,
      required this.entityId,
      required this.operation,
      required this.queuedAt,
      required this.attempts,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_table'] = Variable<String>(entityTable);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueEntriesCompanion(
      id: Value(id),
      entityTable: Value(entityTable),
      entityId: Value(entityId),
      operation: Value(operation),
      queuedAt: Value(queuedAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      id: serializer.fromJson<int>(json['id']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityTable': serializer.toJson<String>(entityTable),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueEntry copyWith(
          {int? id,
          String? entityTable,
          String? entityId,
          String? operation,
          DateTime? queuedAt,
          int? attempts,
          Value<String?> lastError = const Value.absent()}) =>
      SyncQueueEntry(
        id: id ?? this.id,
        entityTable: entityTable ?? this.entityTable,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        queuedAt: queuedAt ?? this.queuedAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  SyncQueueEntry copyWithCompanion(SyncQueueEntriesCompanion data) {
    return SyncQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      entityTable:
          data.entityTable.present ? data.entityTable.value : this.entityTable,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, entityTable, entityId, operation, queuedAt, attempts, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.id == this.id &&
          other.entityTable == this.entityTable &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.queuedAt == this.queuedAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class SyncQueueEntriesCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<int> id;
  final Value<String> entityTable;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<DateTime> queuedAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  const SyncQueueEntriesCompanion({
    this.id = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncQueueEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String entityTable,
    required String entityId,
    required String operation,
    required DateTime queuedAt,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  })  : entityTable = Value(entityTable),
        entityId = Value(entityId),
        operation = Value(operation),
        queuedAt = Value(queuedAt);
  static Insertable<SyncQueueEntry> custom({
    Expression<int>? id,
    Expression<String>? entityTable,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<DateTime>? queuedAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityTable != null) 'entity_table': entityTable,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncQueueEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityTable,
      Value<String>? entityId,
      Value<String>? operation,
      Value<DateTime>? queuedAt,
      Value<int>? attempts,
      Value<String?>? lastError}) {
    return SyncQueueEntriesCompanion(
      id: id ?? this.id,
      entityTable: entityTable ?? this.entityTable,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      queuedAt: queuedAt ?? this.queuedAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntriesCompanion(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remoteTableMeta =
      const VerificationMeta('remoteTable');
  @override
  late final GeneratedColumn<String> remoteTable = GeneratedColumn<String>(
      'remote_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pulledUntilMeta =
      const VerificationMeta('pulledUntil');
  @override
  late final GeneratedColumn<String> pulledUntil = GeneratedColumn<String>(
      'pulled_until', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [userId, remoteTable, pulledUntil];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(Insertable<SyncCursor> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('remote_table')) {
      context.handle(
          _remoteTableMeta,
          remoteTable.isAcceptableOrUnknown(
              data['remote_table']!, _remoteTableMeta));
    } else if (isInserting) {
      context.missing(_remoteTableMeta);
    }
    if (data.containsKey('pulled_until')) {
      context.handle(
          _pulledUntilMeta,
          pulledUntil.isAcceptableOrUnknown(
              data['pulled_until']!, _pulledUntilMeta));
    } else if (isInserting) {
      context.missing(_pulledUntilMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, remoteTable};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      remoteTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_table'])!,
      pulledUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pulled_until'])!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String userId;
  final String remoteTable;
  final String pulledUntil;
  const SyncCursor(
      {required this.userId,
      required this.remoteTable,
      required this.pulledUntil});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['remote_table'] = Variable<String>(remoteTable);
    map['pulled_until'] = Variable<String>(pulledUntil);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      userId: Value(userId),
      remoteTable: Value(remoteTable),
      pulledUntil: Value(pulledUntil),
    );
  }

  factory SyncCursor.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      userId: serializer.fromJson<String>(json['userId']),
      remoteTable: serializer.fromJson<String>(json['remoteTable']),
      pulledUntil: serializer.fromJson<String>(json['pulledUntil']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'remoteTable': serializer.toJson<String>(remoteTable),
      'pulledUntil': serializer.toJson<String>(pulledUntil),
    };
  }

  SyncCursor copyWith(
          {String? userId, String? remoteTable, String? pulledUntil}) =>
      SyncCursor(
        userId: userId ?? this.userId,
        remoteTable: remoteTable ?? this.remoteTable,
        pulledUntil: pulledUntil ?? this.pulledUntil,
      );
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      userId: data.userId.present ? data.userId.value : this.userId,
      remoteTable:
          data.remoteTable.present ? data.remoteTable.value : this.remoteTable,
      pulledUntil:
          data.pulledUntil.present ? data.pulledUntil.value : this.pulledUntil,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('userId: $userId, ')
          ..write('remoteTable: $remoteTable, ')
          ..write('pulledUntil: $pulledUntil')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, remoteTable, pulledUntil);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor &&
          other.userId == this.userId &&
          other.remoteTable == this.remoteTable &&
          other.pulledUntil == this.pulledUntil);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> userId;
  final Value<String> remoteTable;
  final Value<String> pulledUntil;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.userId = const Value.absent(),
    this.remoteTable = const Value.absent(),
    this.pulledUntil = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String userId,
    required String remoteTable,
    required String pulledUntil,
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        remoteTable = Value(remoteTable),
        pulledUntil = Value(pulledUntil);
  static Insertable<SyncCursor> custom({
    Expression<String>? userId,
    Expression<String>? remoteTable,
    Expression<String>? pulledUntil,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (remoteTable != null) 'remote_table': remoteTable,
      if (pulledUntil != null) 'pulled_until': pulledUntil,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith(
      {Value<String>? userId,
      Value<String>? remoteTable,
      Value<String>? pulledUntil,
      Value<int>? rowid}) {
    return SyncCursorsCompanion(
      userId: userId ?? this.userId,
      remoteTable: remoteTable ?? this.remoteTable,
      pulledUntil: pulledUntil ?? this.pulledUntil,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (remoteTable.present) {
      map['remote_table'] = Variable<String>(remoteTable.value);
    }
    if (pulledUntil.present) {
      map['pulled_until'] = Variable<String>(pulledUntil.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('userId: $userId, ')
          ..write('remoteTable: $remoteTable, ')
          ..write('pulledUntil: $pulledUntil, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPreferencesTable extends LocalPreferences
    with TableInfo<$LocalPreferencesTable, LocalPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _settingsMeta =
      const VerificationMeta('settings');
  @override
  late final GeneratedColumn<String> settings = GeneratedColumn<String>(
      'settings', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dashboardLayoutMeta =
      const VerificationMeta('dashboardLayout');
  @override
  late final GeneratedColumn<String> dashboardLayout = GeneratedColumn<String>(
      'dashboard_layout', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [userId, settings, dashboardLayout];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_preferences';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPreference> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('settings')) {
      context.handle(_settingsMeta,
          settings.isAcceptableOrUnknown(data['settings']!, _settingsMeta));
    }
    if (data.containsKey('dashboard_layout')) {
      context.handle(
          _dashboardLayoutMeta,
          dashboardLayout.isAcceptableOrUnknown(
              data['dashboard_layout']!, _dashboardLayoutMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPreference(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      settings: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}settings']),
      dashboardLayout: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}dashboard_layout']),
    );
  }

  @override
  $LocalPreferencesTable createAlias(String alias) {
    return $LocalPreferencesTable(attachedDatabase, alias);
  }
}

class LocalPreference extends DataClass implements Insertable<LocalPreference> {
  final String userId;
  final String? settings;
  final String? dashboardLayout;
  const LocalPreference(
      {required this.userId, this.settings, this.dashboardLayout});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || settings != null) {
      map['settings'] = Variable<String>(settings);
    }
    if (!nullToAbsent || dashboardLayout != null) {
      map['dashboard_layout'] = Variable<String>(dashboardLayout);
    }
    return map;
  }

  LocalPreferencesCompanion toCompanion(bool nullToAbsent) {
    return LocalPreferencesCompanion(
      userId: Value(userId),
      settings: settings == null && nullToAbsent
          ? const Value.absent()
          : Value(settings),
      dashboardLayout: dashboardLayout == null && nullToAbsent
          ? const Value.absent()
          : Value(dashboardLayout),
    );
  }

  factory LocalPreference.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPreference(
      userId: serializer.fromJson<String>(json['userId']),
      settings: serializer.fromJson<String?>(json['settings']),
      dashboardLayout: serializer.fromJson<String?>(json['dashboardLayout']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'settings': serializer.toJson<String?>(settings),
      'dashboardLayout': serializer.toJson<String?>(dashboardLayout),
    };
  }

  LocalPreference copyWith(
          {String? userId,
          Value<String?> settings = const Value.absent(),
          Value<String?> dashboardLayout = const Value.absent()}) =>
      LocalPreference(
        userId: userId ?? this.userId,
        settings: settings.present ? settings.value : this.settings,
        dashboardLayout: dashboardLayout.present
            ? dashboardLayout.value
            : this.dashboardLayout,
      );
  LocalPreference copyWithCompanion(LocalPreferencesCompanion data) {
    return LocalPreference(
      userId: data.userId.present ? data.userId.value : this.userId,
      settings: data.settings.present ? data.settings.value : this.settings,
      dashboardLayout: data.dashboardLayout.present
          ? data.dashboardLayout.value
          : this.dashboardLayout,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPreference(')
          ..write('userId: $userId, ')
          ..write('settings: $settings, ')
          ..write('dashboardLayout: $dashboardLayout')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, settings, dashboardLayout);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPreference &&
          other.userId == this.userId &&
          other.settings == this.settings &&
          other.dashboardLayout == this.dashboardLayout);
}

class LocalPreferencesCompanion extends UpdateCompanion<LocalPreference> {
  final Value<String> userId;
  final Value<String?> settings;
  final Value<String?> dashboardLayout;
  final Value<int> rowid;
  const LocalPreferencesCompanion({
    this.userId = const Value.absent(),
    this.settings = const Value.absent(),
    this.dashboardLayout = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPreferencesCompanion.insert({
    required String userId,
    this.settings = const Value.absent(),
    this.dashboardLayout = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<LocalPreference> custom({
    Expression<String>? userId,
    Expression<String>? settings,
    Expression<String>? dashboardLayout,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (settings != null) 'settings': settings,
      if (dashboardLayout != null) 'dashboard_layout': dashboardLayout,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPreferencesCompanion copyWith(
      {Value<String>? userId,
      Value<String?>? settings,
      Value<String?>? dashboardLayout,
      Value<int>? rowid}) {
    return LocalPreferencesCompanion(
      userId: userId ?? this.userId,
      settings: settings ?? this.settings,
      dashboardLayout: dashboardLayout ?? this.dashboardLayout,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (settings.present) {
      map['settings'] = Variable<String>(settings.value);
    }
    if (dashboardLayout.present) {
      map['dashboard_layout'] = Variable<String>(dashboardLayout.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPreferencesCompanion(')
          ..write('userId: $userId, ')
          ..write('settings: $settings, ')
          ..write('dashboardLayout: $dashboardLayout, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalFoldersTable extends LocalFolders
    with TableInfo<$LocalFoldersTable, LocalFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 120),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
      'position', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, parentId, name, position, createdAt, isSynced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_folders';
  @override
  VerificationContext validateIntegrity(Insertable<LocalFolder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFolder(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}position']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalFoldersTable createAlias(String alias) {
    return $LocalFoldersTable(attachedDatabase, alias);
  }
}

class LocalFolder extends DataClass implements Insertable<LocalFolder> {
  final String id;
  final String userId;
  final String? parentId;
  final String name;

  /// Clé d'ordre manuel ; `null` : ordre alphabétique.
  final String? position;
  final DateTime createdAt;
  final bool isSynced;
  const LocalFolder(
      {required this.id,
      required this.userId,
      this.parentId,
      required this.name,
      this.position,
      required this.createdAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<String>(position);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalFoldersCompanion toCompanion(bool nullToAbsent) {
    return LocalFoldersCompanion(
      id: Value(id),
      userId: Value(userId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalFolder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFolder(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<String?>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<String?>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalFolder copyWith(
          {String? id,
          String? userId,
          Value<String?> parentId = const Value.absent(),
          String? name,
          Value<String?> position = const Value.absent(),
          DateTime? createdAt,
          bool? isSynced}) =>
      LocalFolder(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        parentId: parentId.present ? parentId.value : this.parentId,
        name: name ?? this.name,
        position: position.present ? position.value : this.position,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalFolder copyWithCompanion(LocalFoldersCompanion data) {
    return LocalFolder(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFolder(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, parentId, name, position, createdAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFolder &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class LocalFoldersCompanion extends UpdateCompanion<LocalFolder> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<String?> position;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalFoldersCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalFoldersCompanion.insert({
    required String id,
    required String userId,
    this.parentId = const Value.absent(),
    required String name,
    this.position = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<LocalFolder> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<String>? position,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalFoldersCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? parentId,
      Value<String>? name,
      Value<String?>? position,
      Value<DateTime>? createdAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalFoldersCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFoldersCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalNotesTable localNotes = $LocalNotesTable(this);
  late final $LocalNoteBlocksTable localNoteBlocks =
      $LocalNoteBlocksTable(this);
  late final Trigger localNoteBlocksRevisionInsert = Trigger(
      'CREATE TRIGGER local_note_blocks_revision_insert AFTER INSERT ON local_note_blocks BEGIN UPDATE local_notes SET revision = revision + 1 WHERE id = new.note_id;END',
      'local_note_blocks_revision_insert');
  late final Trigger localNoteBlocksRevisionUpdate = Trigger(
      'CREATE TRIGGER local_note_blocks_revision_update AFTER UPDATE ON local_note_blocks BEGIN UPDATE local_notes SET revision = revision + 1 WHERE id = new.note_id OR id = old.note_id;END',
      'local_note_blocks_revision_update');
  late final Trigger localNoteBlocksRevisionDelete = Trigger(
      'CREATE TRIGGER local_note_blocks_revision_delete AFTER DELETE ON local_note_blocks BEGIN UPDATE local_notes SET revision = revision + 1 WHERE id = old.note_id;END',
      'local_note_blocks_revision_delete');
  late final $LocalNoteLinksTable localNoteLinks = $LocalNoteLinksTable(this);
  late final $LocalFlashcardsTable localFlashcards =
      $LocalFlashcardsTable(this);
  late final $LocalReviewLogsTable localReviewLogs =
      $LocalReviewLogsTable(this);
  late final $LocalSq3rSessionsTable localSq3rSessions =
      $LocalSq3rSessionsTable(this);
  late final $LocalExplanationsTable localExplanations =
      $LocalExplanationsTable(this);
  late final $LocalJournalEntriesTable localJournalEntries =
      $LocalJournalEntriesTable(this);
  late final $LocalReframesTable localReframes = $LocalReframesTable(this);
  late final $LocalWhyChainsTable localWhyChains = $LocalWhyChainsTable(this);
  late final $LocalErrorLogsTable localErrorLogs = $LocalErrorLogsTable(this);
  late final $LocalLearningProfilesTable localLearningProfiles =
      $LocalLearningProfilesTable(this);
  late final $LocalStudyGoalsTable localStudyGoals =
      $LocalStudyGoalsTable(this);
  late final $LocalPlanItemsTable localPlanItems = $LocalPlanItemsTable(this);
  late final $LocalSpeedSamplesTable localSpeedSamples =
      $LocalSpeedSamplesTable(this);
  late final $LocalExamTargetsTable localExamTargets =
      $LocalExamTargetsTable(this);
  late final $LocalTasksTable localTasks = $LocalTasksTable(this);
  late final $LocalHabitsTable localHabits = $LocalHabitsTable(this);
  late final $LocalHabitLogsTable localHabitLogs = $LocalHabitLogsTable(this);
  late final $LocalPomodoroSessionsTable localPomodoroSessions =
      $LocalPomodoroSessionsTable(this);
  late final $SyncQueueEntriesTable syncQueueEntries =
      $SyncQueueEntriesTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $LocalPreferencesTable localPreferences =
      $LocalPreferencesTable(this);
  late final $LocalFoldersTable localFolders = $LocalFoldersTable(this);
  late final Index localNotesUserUpdated = Index('local_notes_user_updated',
      'CREATE INDEX local_notes_user_updated ON local_notes (user_id, updated_at)');
  late final Index localNoteBlocksNotePosition = Index(
      'local_note_blocks_note_position',
      'CREATE INDEX local_note_blocks_note_position ON local_note_blocks (note_id, position)');
  late final Index localNoteLinksUserCreated = Index(
      'local_note_links_user_created',
      'CREATE INDEX local_note_links_user_created ON local_note_links (user_id, created_at)');
  late final Index localNoteLinksTarget = Index('local_note_links_target',
      'CREATE INDEX local_note_links_target ON local_note_links (target_id)');
  late final Index localFlashcardsUserDue = Index('local_flashcards_user_due',
      'CREATE INDEX local_flashcards_user_due ON local_flashcards (user_id, due_at)');
  late final Index localFlashcardsNote = Index('local_flashcards_note',
      'CREATE INDEX local_flashcards_note ON local_flashcards (note_id)');
  late final Index localReviewLogsUserReviewed = Index(
      'local_review_logs_user_reviewed',
      'CREATE INDEX local_review_logs_user_reviewed ON local_review_logs (user_id, reviewed_at)');
  late final Index localReviewLogsCard = Index('local_review_logs_card',
      'CREATE INDEX local_review_logs_card ON local_review_logs (card_id)');
  late final Index localExplanationsUserCreated = Index(
      'local_explanations_user_created',
      'CREATE INDEX local_explanations_user_created ON local_explanations (user_id, created_at)');
  late final Index localExplanationsNote = Index('local_explanations_note',
      'CREATE INDEX local_explanations_note ON local_explanations (note_id)');
  late final Index localJournalEntriesUserCreated = Index(
      'local_journal_entries_user_created',
      'CREATE INDEX local_journal_entries_user_created ON local_journal_entries (user_id, created_at)');
  late final Index localJournalEntriesNote = Index('local_journal_entries_note',
      'CREATE INDEX local_journal_entries_note ON local_journal_entries (note_id)');
  late final Index localReframesUserCreated = Index(
      'local_reframes_user_created',
      'CREATE INDEX local_reframes_user_created ON local_reframes (user_id, created_at)');
  late final Index localWhyChainsUserCreated = Index(
      'local_why_chains_user_created',
      'CREATE INDEX local_why_chains_user_created ON local_why_chains (user_id, created_at)');
  late final Index localErrorLogsUserCreated = Index(
      'local_error_logs_user_created',
      'CREATE INDEX local_error_logs_user_created ON local_error_logs (user_id, created_at)');
  late final Index localErrorLogsNote = Index('local_error_logs_note',
      'CREATE INDEX local_error_logs_note ON local_error_logs (note_id)');
  late final Index localStudyGoalsUserDeadline = Index(
      'local_study_goals_user_deadline',
      'CREATE INDEX local_study_goals_user_deadline ON local_study_goals (user_id, deadline)');
  late final Index localPlanItemsUserStart = Index(
      'local_plan_items_user_start',
      'CREATE INDEX local_plan_items_user_start ON local_plan_items (user_id, start_date)');
  late final Index localPlanItemsGoal = Index('local_plan_items_goal',
      'CREATE INDEX local_plan_items_goal ON local_plan_items (goal_id)');
  late final Index localPlanItemsDependsOn = Index(
      'local_plan_items_depends_on',
      'CREATE INDEX local_plan_items_depends_on ON local_plan_items (depends_on_id)');
  late final Index localSpeedSamplesUserCreated = Index(
      'local_speed_samples_user_created',
      'CREATE INDEX local_speed_samples_user_created ON local_speed_samples (user_id, created_at)');
  late final Index localExamTargetsUserExam = Index(
      'local_exam_targets_user_exam',
      'CREATE INDEX local_exam_targets_user_exam ON local_exam_targets (user_id, exam_date)');
  late final Index localExamTargetsNote = Index('local_exam_targets_note',
      'CREATE INDEX local_exam_targets_note ON local_exam_targets (note_id)');
  late final Index localTasksUserPosition = Index('local_tasks_user_position',
      'CREATE INDEX local_tasks_user_position ON local_tasks (user_id, position, created_at)');
  late final Index localHabitsUserCreated = Index('local_habits_user_created',
      'CREATE INDEX local_habits_user_created ON local_habits (user_id, created_at)');
  late final Index localPomodoroSessionsUserStarted = Index(
      'local_pomodoro_sessions_user_started',
      'CREATE INDEX local_pomodoro_sessions_user_started ON local_pomodoro_sessions (user_id, started_at)');
  late final Index syncQueueEntriesEntity = Index('sync_queue_entries_entity',
      'CREATE INDEX sync_queue_entries_entity ON sync_queue_entries (entity_table, entity_id)');
  late final Index localFoldersUserParent = Index('local_folders_user_parent',
      'CREATE INDEX local_folders_user_parent ON local_folders (user_id, parent_id)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        localNotes,
        localNoteBlocks,
        localNoteBlocksRevisionInsert,
        localNoteBlocksRevisionUpdate,
        localNoteBlocksRevisionDelete,
        localNoteLinks,
        localFlashcards,
        localReviewLogs,
        localSq3rSessions,
        localExplanations,
        localJournalEntries,
        localReframes,
        localWhyChains,
        localErrorLogs,
        localLearningProfiles,
        localStudyGoals,
        localPlanItems,
        localSpeedSamples,
        localExamTargets,
        localTasks,
        localHabits,
        localHabitLogs,
        localPomodoroSessions,
        syncQueueEntries,
        syncCursors,
        localPreferences,
        localFolders,
        localNotesUserUpdated,
        localNoteBlocksNotePosition,
        localNoteLinksUserCreated,
        localNoteLinksTarget,
        localFlashcardsUserDue,
        localFlashcardsNote,
        localReviewLogsUserReviewed,
        localReviewLogsCard,
        localExplanationsUserCreated,
        localExplanationsNote,
        localJournalEntriesUserCreated,
        localJournalEntriesNote,
        localReframesUserCreated,
        localWhyChainsUserCreated,
        localErrorLogsUserCreated,
        localErrorLogsNote,
        localStudyGoalsUserDeadline,
        localPlanItemsUserStart,
        localPlanItemsGoal,
        localPlanItemsDependsOn,
        localSpeedSamplesUserCreated,
        localExamTargetsUserExam,
        localExamTargetsNote,
        localTasksUserPosition,
        localHabitsUserCreated,
        localPomodoroSessionsUserStarted,
        syncQueueEntriesEntity,
        localFoldersUserParent
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_notes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_note_blocks', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_note_blocks',
                limitUpdateKind: UpdateKind.insert),
            result: [
              TableUpdate('local_notes', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_note_blocks',
                limitUpdateKind: UpdateKind.update),
            result: [
              TableUpdate('local_notes', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_note_blocks',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_notes', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_notes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_note_links', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_notes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_note_links', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_notes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_flashcards', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_flashcards',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_review_logs', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_notes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_sq3r_sessions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_notes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_explanations', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_notes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_journal_entries', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_notes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_error_logs', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_study_goals',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_plan_items', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_notes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_exam_targets', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('local_habits',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('local_habit_logs', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$LocalNotesTableCreateCompanionBuilder = LocalNotesCompanion Function({
  required String id,
  required String userId,
  required String title,
  Value<String> content,
  Value<String?> subject,
  Value<String> tags,
  Value<int> importance,
  Value<bool> isFavorite,
  Value<bool> isArchived,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> isDeleted,
  Value<bool> isSynced,
  Value<int> revision,
  Value<String?> position,
  Value<String?> folderId,
  Value<int> rowid,
});
typedef $$LocalNotesTableUpdateCompanionBuilder = LocalNotesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> title,
  Value<String> content,
  Value<String?> subject,
  Value<String> tags,
  Value<int> importance,
  Value<bool> isFavorite,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
  Value<bool> isSynced,
  Value<int> revision,
  Value<String?> position,
  Value<String?> folderId,
  Value<int> rowid,
});

final class $$LocalNotesTableReferences
    extends BaseReferences<_$AppDatabase, $LocalNotesTable, LocalNote> {
  $$LocalNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LocalNoteBlocksTable, List<LocalNoteBlock>>
      _localNoteBlocksRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.localNoteBlocks,
              aliasName: 'local_notes__id__local_note_blocks__note_id');

  $$LocalNoteBlocksTableProcessedTableManager get localNoteBlocksRefs {
    final manager =
        $$LocalNoteBlocksTableTableManager($_db, $_db.localNoteBlocks)
            .filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_localNoteBlocksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LocalFlashcardsTable, List<LocalFlashcard>>
      _localFlashcardsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.localFlashcards,
              aliasName: 'local_notes__id__local_flashcards__note_id');

  $$LocalFlashcardsTableProcessedTableManager get localFlashcardsRefs {
    final manager =
        $$LocalFlashcardsTableTableManager($_db, $_db.localFlashcards)
            .filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_localFlashcardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LocalSq3rSessionsTable, List<LocalSq3rSession>>
      _localSq3rSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.localSq3rSessions,
              aliasName: 'local_notes__id__local_sq3r_sessions__note_id');

  $$LocalSq3rSessionsTableProcessedTableManager get localSq3rSessionsRefs {
    final manager =
        $$LocalSq3rSessionsTableTableManager($_db, $_db.localSq3rSessions)
            .filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_localSq3rSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LocalExplanationsTable, List<LocalExplanation>>
      _localExplanationsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.localExplanations,
              aliasName: 'local_notes__id__local_explanations__note_id');

  $$LocalExplanationsTableProcessedTableManager get localExplanationsRefs {
    final manager =
        $$LocalExplanationsTableTableManager($_db, $_db.localExplanations)
            .filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_localExplanationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LocalJournalEntriesTable, List<LocalJournalEntry>>
      _localJournalEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.localJournalEntries,
              aliasName: 'local_notes__id__local_journal_entries__note_id');

  $$LocalJournalEntriesTableProcessedTableManager get localJournalEntriesRefs {
    final manager =
        $$LocalJournalEntriesTableTableManager($_db, $_db.localJournalEntries)
            .filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_localJournalEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LocalErrorLogsTable, List<LocalErrorLog>>
      _localErrorLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.localErrorLogs,
              aliasName: 'local_notes__id__local_error_logs__note_id');

  $$LocalErrorLogsTableProcessedTableManager get localErrorLogsRefs {
    final manager = $$LocalErrorLogsTableTableManager($_db, $_db.localErrorLogs)
        .filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_localErrorLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LocalExamTargetsTable, List<LocalExamTarget>>
      _localExamTargetsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.localExamTargets,
              aliasName: 'local_notes__id__local_exam_targets__note_id');

  $$LocalExamTargetsTableProcessedTableManager get localExamTargetsRefs {
    final manager =
        $$LocalExamTargetsTableTableManager($_db, $_db.localExamTargets)
            .filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_localExamTargetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LocalNotesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalNotesTable> {
  $$LocalNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get revision => $composableBuilder(
      column: $table.revision, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnFilters(column));

  Expression<bool> localNoteBlocksRefs(
      Expression<bool> Function($$LocalNoteBlocksTableFilterComposer f) f) {
    final $$LocalNoteBlocksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localNoteBlocks,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNoteBlocksTableFilterComposer(
              $db: $db,
              $table: $db.localNoteBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> localFlashcardsRefs(
      Expression<bool> Function($$LocalFlashcardsTableFilterComposer f) f) {
    final $$LocalFlashcardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localFlashcards,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalFlashcardsTableFilterComposer(
              $db: $db,
              $table: $db.localFlashcards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> localSq3rSessionsRefs(
      Expression<bool> Function($$LocalSq3rSessionsTableFilterComposer f) f) {
    final $$LocalSq3rSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localSq3rSessions,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalSq3rSessionsTableFilterComposer(
              $db: $db,
              $table: $db.localSq3rSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> localExplanationsRefs(
      Expression<bool> Function($$LocalExplanationsTableFilterComposer f) f) {
    final $$LocalExplanationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localExplanations,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalExplanationsTableFilterComposer(
              $db: $db,
              $table: $db.localExplanations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> localJournalEntriesRefs(
      Expression<bool> Function($$LocalJournalEntriesTableFilterComposer f) f) {
    final $$LocalJournalEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localJournalEntries,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalJournalEntriesTableFilterComposer(
              $db: $db,
              $table: $db.localJournalEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> localErrorLogsRefs(
      Expression<bool> Function($$LocalErrorLogsTableFilterComposer f) f) {
    final $$LocalErrorLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localErrorLogs,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalErrorLogsTableFilterComposer(
              $db: $db,
              $table: $db.localErrorLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> localExamTargetsRefs(
      Expression<bool> Function($$LocalExamTargetsTableFilterComposer f) f) {
    final $$LocalExamTargetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localExamTargets,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalExamTargetsTableFilterComposer(
              $db: $db,
              $table: $db.localExamTargets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalNotesTable> {
  $$LocalNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get revision => $composableBuilder(
      column: $table.revision, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnOrderings(column));
}

class $$LocalNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalNotesTable> {
  $$LocalNotesTableAnnotationComposer({
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

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  Expression<T> localNoteBlocksRefs<T extends Object>(
      Expression<T> Function($$LocalNoteBlocksTableAnnotationComposer a) f) {
    final $$LocalNoteBlocksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localNoteBlocks,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNoteBlocksTableAnnotationComposer(
              $db: $db,
              $table: $db.localNoteBlocks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> localFlashcardsRefs<T extends Object>(
      Expression<T> Function($$LocalFlashcardsTableAnnotationComposer a) f) {
    final $$LocalFlashcardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localFlashcards,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalFlashcardsTableAnnotationComposer(
              $db: $db,
              $table: $db.localFlashcards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> localSq3rSessionsRefs<T extends Object>(
      Expression<T> Function($$LocalSq3rSessionsTableAnnotationComposer a) f) {
    final $$LocalSq3rSessionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.localSq3rSessions,
            getReferencedColumn: (t) => t.noteId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$LocalSq3rSessionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.localSq3rSessions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> localExplanationsRefs<T extends Object>(
      Expression<T> Function($$LocalExplanationsTableAnnotationComposer a) f) {
    final $$LocalExplanationsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.localExplanations,
            getReferencedColumn: (t) => t.noteId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$LocalExplanationsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.localExplanations,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> localJournalEntriesRefs<T extends Object>(
      Expression<T> Function($$LocalJournalEntriesTableAnnotationComposer a)
          f) {
    final $$LocalJournalEntriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.localJournalEntries,
            getReferencedColumn: (t) => t.noteId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$LocalJournalEntriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.localJournalEntries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> localErrorLogsRefs<T extends Object>(
      Expression<T> Function($$LocalErrorLogsTableAnnotationComposer a) f) {
    final $$LocalErrorLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localErrorLogs,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalErrorLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.localErrorLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> localExamTargetsRefs<T extends Object>(
      Expression<T> Function($$LocalExamTargetsTableAnnotationComposer a) f) {
    final $$LocalExamTargetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localExamTargets,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalExamTargetsTableAnnotationComposer(
              $db: $db,
              $table: $db.localExamTargets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalNotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalNotesTable,
    LocalNote,
    $$LocalNotesTableFilterComposer,
    $$LocalNotesTableOrderingComposer,
    $$LocalNotesTableAnnotationComposer,
    $$LocalNotesTableCreateCompanionBuilder,
    $$LocalNotesTableUpdateCompanionBuilder,
    (LocalNote, $$LocalNotesTableReferences),
    LocalNote,
    PrefetchHooks Function(
        {bool localNoteBlocksRefs,
        bool localFlashcardsRefs,
        bool localSq3rSessionsRefs,
        bool localExplanationsRefs,
        bool localJournalEntriesRefs,
        bool localErrorLogsRefs,
        bool localExamTargetsRefs})> {
  $$LocalNotesTableTableManager(_$AppDatabase db, $LocalNotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String?> subject = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<int> importance = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> revision = const Value.absent(),
            Value<String?> position = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNotesCompanion(
            id: id,
            userId: userId,
            title: title,
            content: content,
            subject: subject,
            tags: tags,
            importance: importance,
            isFavorite: isFavorite,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            isSynced: isSynced,
            revision: revision,
            position: position,
            folderId: folderId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String title,
            Value<String> content = const Value.absent(),
            Value<String?> subject = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<int> importance = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> revision = const Value.absent(),
            Value<String?> position = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNotesCompanion.insert(
            id: id,
            userId: userId,
            title: title,
            content: content,
            subject: subject,
            tags: tags,
            importance: importance,
            isFavorite: isFavorite,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            isSynced: isSynced,
            revision: revision,
            position: position,
            folderId: folderId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalNotesTable, LocalNote>(table),
                    $$LocalNotesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {localNoteBlocksRefs = false,
              localFlashcardsRefs = false,
              localSq3rSessionsRefs = false,
              localExplanationsRefs = false,
              localJournalEntriesRefs = false,
              localErrorLogsRefs = false,
              localExamTargetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localNoteBlocksRefs) db.localNoteBlocks,
                if (localFlashcardsRefs) db.localFlashcards,
                if (localSq3rSessionsRefs) db.localSq3rSessions,
                if (localExplanationsRefs) db.localExplanations,
                if (localJournalEntriesRefs) db.localJournalEntries,
                if (localErrorLogsRefs) db.localErrorLogs,
                if (localExamTargetsRefs) db.localExamTargets
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localNoteBlocksRefs)
                    await $_getPrefetchedData<LocalNote, $LocalNotesTable,
                            LocalNoteBlock>(
                        currentTable: table,
                        referencedTable: $$LocalNotesTableReferences
                            ._localNoteBlocksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalNotesTableReferences(db, table, p0)
                                .localNoteBlocksRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.noteId == item.id),
                        typedResults: items),
                  if (localFlashcardsRefs)
                    await $_getPrefetchedData<LocalNote, $LocalNotesTable,
                            LocalFlashcard>(
                        currentTable: table,
                        referencedTable: $$LocalNotesTableReferences
                            ._localFlashcardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalNotesTableReferences(db, table, p0)
                                .localFlashcardsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.noteId == item.id),
                        typedResults: items),
                  if (localSq3rSessionsRefs)
                    await $_getPrefetchedData<LocalNote, $LocalNotesTable,
                            LocalSq3rSession>(
                        currentTable: table,
                        referencedTable: $$LocalNotesTableReferences
                            ._localSq3rSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalNotesTableReferences(db, table, p0)
                                .localSq3rSessionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.noteId == item.id),
                        typedResults: items),
                  if (localExplanationsRefs)
                    await $_getPrefetchedData<LocalNote, $LocalNotesTable,
                            LocalExplanation>(
                        currentTable: table,
                        referencedTable: $$LocalNotesTableReferences
                            ._localExplanationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalNotesTableReferences(db, table, p0)
                                .localExplanationsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.noteId == item.id),
                        typedResults: items),
                  if (localJournalEntriesRefs)
                    await $_getPrefetchedData<LocalNote, $LocalNotesTable,
                            LocalJournalEntry>(
                        currentTable: table,
                        referencedTable: $$LocalNotesTableReferences
                            ._localJournalEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalNotesTableReferences(db, table, p0)
                                .localJournalEntriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.noteId == item.id),
                        typedResults: items),
                  if (localErrorLogsRefs)
                    await $_getPrefetchedData<LocalNote, $LocalNotesTable,
                            LocalErrorLog>(
                        currentTable: table,
                        referencedTable: $$LocalNotesTableReferences
                            ._localErrorLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalNotesTableReferences(db, table, p0)
                                .localErrorLogsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.noteId == item.id),
                        typedResults: items),
                  if (localExamTargetsRefs)
                    await $_getPrefetchedData<LocalNote, $LocalNotesTable,
                            LocalExamTarget>(
                        currentTable: table,
                        referencedTable: $$LocalNotesTableReferences
                            ._localExamTargetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalNotesTableReferences(db, table, p0)
                                .localExamTargetsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.noteId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LocalNotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalNotesTable,
    LocalNote,
    $$LocalNotesTableFilterComposer,
    $$LocalNotesTableOrderingComposer,
    $$LocalNotesTableAnnotationComposer,
    $$LocalNotesTableCreateCompanionBuilder,
    $$LocalNotesTableUpdateCompanionBuilder,
    (LocalNote, $$LocalNotesTableReferences),
    LocalNote,
    PrefetchHooks Function(
        {bool localNoteBlocksRefs,
        bool localFlashcardsRefs,
        bool localSq3rSessionsRefs,
        bool localExplanationsRefs,
        bool localJournalEntriesRefs,
        bool localErrorLogsRefs,
        bool localExamTargetsRefs})>;
typedef $$LocalNoteBlocksTableCreateCompanionBuilder = LocalNoteBlocksCompanion
    Function({
  required String id,
  required String noteId,
  required String type,
  Value<String> content,
  Value<bool> isChecked,
  required int position,
  Value<int> rowid,
});
typedef $$LocalNoteBlocksTableUpdateCompanionBuilder = LocalNoteBlocksCompanion
    Function({
  Value<String> id,
  Value<String> noteId,
  Value<String> type,
  Value<String> content,
  Value<bool> isChecked,
  Value<int> position,
  Value<int> rowid,
});

final class $$LocalNoteBlocksTableReferences extends BaseReferences<
    _$AppDatabase, $LocalNoteBlocksTable, LocalNoteBlock> {
  $$LocalNoteBlocksTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalNotesTable _noteIdTable(_$AppDatabase db) =>
      db.localNotes.createAlias('local_note_blocks__note_id__local_notes__id');

  $$LocalNotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$LocalNotesTableTableManager($_db, $_db.localNotes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalNoteBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $LocalNoteBlocksTable> {
  $$LocalNoteBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isChecked => $composableBuilder(
      column: $table.isChecked, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  $$LocalNotesTableFilterComposer get noteId {
    final $$LocalNotesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableFilterComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalNoteBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalNoteBlocksTable> {
  $$LocalNoteBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isChecked => $composableBuilder(
      column: $table.isChecked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  $$LocalNotesTableOrderingComposer get noteId {
    final $$LocalNotesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableOrderingComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalNoteBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalNoteBlocksTable> {
  $$LocalNoteBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isChecked =>
      $composableBuilder(column: $table.isChecked, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$LocalNotesTableAnnotationComposer get noteId {
    final $$LocalNotesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableAnnotationComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalNoteBlocksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalNoteBlocksTable,
    LocalNoteBlock,
    $$LocalNoteBlocksTableFilterComposer,
    $$LocalNoteBlocksTableOrderingComposer,
    $$LocalNoteBlocksTableAnnotationComposer,
    $$LocalNoteBlocksTableCreateCompanionBuilder,
    $$LocalNoteBlocksTableUpdateCompanionBuilder,
    (LocalNoteBlock, $$LocalNoteBlocksTableReferences),
    LocalNoteBlock,
    PrefetchHooks Function({bool noteId})> {
  $$LocalNoteBlocksTableTableManager(
      _$AppDatabase db, $LocalNoteBlocksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalNoteBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalNoteBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalNoteBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> noteId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<bool> isChecked = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNoteBlocksCompanion(
            id: id,
            noteId: noteId,
            type: type,
            content: content,
            isChecked: isChecked,
            position: position,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String noteId,
            required String type,
            Value<String> content = const Value.absent(),
            Value<bool> isChecked = const Value.absent(),
            required int position,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNoteBlocksCompanion.insert(
            id: id,
            noteId: noteId,
            type: type,
            content: content,
            isChecked: isChecked,
            position: position,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalNoteBlocksTable, LocalNoteBlock>(table),
                    $$LocalNoteBlocksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (noteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.noteId,
                    referencedTable:
                        $$LocalNoteBlocksTableReferences._noteIdTable(db),
                    referencedColumn:
                        $$LocalNoteBlocksTableReferences._noteIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocalNoteBlocksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalNoteBlocksTable,
    LocalNoteBlock,
    $$LocalNoteBlocksTableFilterComposer,
    $$LocalNoteBlocksTableOrderingComposer,
    $$LocalNoteBlocksTableAnnotationComposer,
    $$LocalNoteBlocksTableCreateCompanionBuilder,
    $$LocalNoteBlocksTableUpdateCompanionBuilder,
    (LocalNoteBlock, $$LocalNoteBlocksTableReferences),
    LocalNoteBlock,
    PrefetchHooks Function({bool noteId})>;
typedef $$LocalNoteLinksTableCreateCompanionBuilder = LocalNoteLinksCompanion
    Function({
  required String id,
  required String userId,
  required String sourceId,
  required String targetId,
  Value<String> type,
  Value<String?> label,
  required DateTime createdAt,
  Value<bool> isDeleted,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalNoteLinksTableUpdateCompanionBuilder = LocalNoteLinksCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> sourceId,
  Value<String> targetId,
  Value<String> type,
  Value<String?> label,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
  Value<bool> isSynced,
  Value<int> rowid,
});

final class $$LocalNoteLinksTableReferences
    extends BaseReferences<_$AppDatabase, $LocalNoteLinksTable, LocalNoteLink> {
  $$LocalNoteLinksTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalNotesTable _sourceIdTable(_$AppDatabase db) =>
      db.localNotes.createAlias('local_note_links__source_id__local_notes__id');

  $$LocalNotesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$LocalNotesTableTableManager($_db, $_db.localNotes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $LocalNotesTable _targetIdTable(_$AppDatabase db) =>
      db.localNotes.createAlias('local_note_links__target_id__local_notes__id');

  $$LocalNotesTableProcessedTableManager get targetId {
    final $_column = $_itemColumn<String>('target_id')!;

    final manager = $$LocalNotesTableTableManager($_db, $_db.localNotes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_targetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalNoteLinksTableFilterComposer
    extends Composer<_$AppDatabase, $LocalNoteLinksTable> {
  $$LocalNoteLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  $$LocalNotesTableFilterComposer get sourceId {
    final $$LocalNotesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableFilterComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalNotesTableFilterComposer get targetId {
    final $$LocalNotesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.targetId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableFilterComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalNoteLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalNoteLinksTable> {
  $$LocalNoteLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  $$LocalNotesTableOrderingComposer get sourceId {
    final $$LocalNotesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableOrderingComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalNotesTableOrderingComposer get targetId {
    final $$LocalNotesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.targetId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableOrderingComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalNoteLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalNoteLinksTable> {
  $$LocalNoteLinksTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$LocalNotesTableAnnotationComposer get sourceId {
    final $$LocalNotesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableAnnotationComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalNotesTableAnnotationComposer get targetId {
    final $$LocalNotesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.targetId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableAnnotationComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalNoteLinksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalNoteLinksTable,
    LocalNoteLink,
    $$LocalNoteLinksTableFilterComposer,
    $$LocalNoteLinksTableOrderingComposer,
    $$LocalNoteLinksTableAnnotationComposer,
    $$LocalNoteLinksTableCreateCompanionBuilder,
    $$LocalNoteLinksTableUpdateCompanionBuilder,
    (LocalNoteLink, $$LocalNoteLinksTableReferences),
    LocalNoteLink,
    PrefetchHooks Function({bool sourceId, bool targetId})> {
  $$LocalNoteLinksTableTableManager(
      _$AppDatabase db, $LocalNoteLinksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalNoteLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalNoteLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalNoteLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> sourceId = const Value.absent(),
            Value<String> targetId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> label = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNoteLinksCompanion(
            id: id,
            userId: userId,
            sourceId: sourceId,
            targetId: targetId,
            type: type,
            label: label,
            createdAt: createdAt,
            isDeleted: isDeleted,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String sourceId,
            required String targetId,
            Value<String> type = const Value.absent(),
            Value<String?> label = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNoteLinksCompanion.insert(
            id: id,
            userId: userId,
            sourceId: sourceId,
            targetId: targetId,
            type: type,
            label: label,
            createdAt: createdAt,
            isDeleted: isDeleted,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalNoteLinksTable, LocalNoteLink>(table),
                    $$LocalNoteLinksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sourceId = false, targetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (sourceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourceId,
                    referencedTable:
                        $$LocalNoteLinksTableReferences._sourceIdTable(db),
                    referencedColumn:
                        $$LocalNoteLinksTableReferences._sourceIdTable(db).id,
                  ) as T;
                }
                if (targetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.targetId,
                    referencedTable:
                        $$LocalNoteLinksTableReferences._targetIdTable(db),
                    referencedColumn:
                        $$LocalNoteLinksTableReferences._targetIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocalNoteLinksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalNoteLinksTable,
    LocalNoteLink,
    $$LocalNoteLinksTableFilterComposer,
    $$LocalNoteLinksTableOrderingComposer,
    $$LocalNoteLinksTableAnnotationComposer,
    $$LocalNoteLinksTableCreateCompanionBuilder,
    $$LocalNoteLinksTableUpdateCompanionBuilder,
    (LocalNoteLink, $$LocalNoteLinksTableReferences),
    LocalNoteLink,
    PrefetchHooks Function({bool sourceId, bool targetId})>;
typedef $$LocalFlashcardsTableCreateCompanionBuilder = LocalFlashcardsCompanion
    Function({
  required String id,
  required String userId,
  Value<String?> noteId,
  required String front,
  required String back,
  Value<String?> deck,
  Value<int> step,
  Value<double> easeFactor,
  required DateTime dueAt,
  Value<DateTime?> lastReviewedAt,
  Value<int> repetitions,
  Value<int> lapses,
  required DateTime createdAt,
  Value<bool> isDeleted,
  Value<bool> isSynced,
  Value<String?> folderId,
  Value<int> rowid,
});
typedef $$LocalFlashcardsTableUpdateCompanionBuilder = LocalFlashcardsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> noteId,
  Value<String> front,
  Value<String> back,
  Value<String?> deck,
  Value<int> step,
  Value<double> easeFactor,
  Value<DateTime> dueAt,
  Value<DateTime?> lastReviewedAt,
  Value<int> repetitions,
  Value<int> lapses,
  Value<DateTime> createdAt,
  Value<bool> isDeleted,
  Value<bool> isSynced,
  Value<String?> folderId,
  Value<int> rowid,
});

final class $$LocalFlashcardsTableReferences extends BaseReferences<
    _$AppDatabase, $LocalFlashcardsTable, LocalFlashcard> {
  $$LocalFlashcardsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalNotesTable _noteIdTable(_$AppDatabase db) =>
      db.localNotes.createAlias('local_flashcards__note_id__local_notes__id');

  $$LocalNotesTableProcessedTableManager? get noteId {
    final $_column = $_itemColumn<String>('note_id');
    if ($_column == null) return null;
    final manager = $$LocalNotesTableTableManager($_db, $_db.localNotes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$LocalReviewLogsTable, List<LocalReviewLog>>
      _localReviewLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.localReviewLogs,
              aliasName: 'local_flashcards__id__local_review_logs__card_id');

  $$LocalReviewLogsTableProcessedTableManager get localReviewLogsRefs {
    final manager =
        $$LocalReviewLogsTableTableManager($_db, $_db.localReviewLogs)
            .filter((f) => f.cardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_localReviewLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LocalFlashcardsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalFlashcardsTable> {
  $$LocalFlashcardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get front => $composableBuilder(
      column: $table.front, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get back => $composableBuilder(
      column: $table.back, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deck => $composableBuilder(
      column: $table.deck, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get step => $composableBuilder(
      column: $table.step, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get easeFactor => $composableBuilder(
      column: $table.easeFactor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
      column: $table.dueAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repetitions => $composableBuilder(
      column: $table.repetitions, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapses => $composableBuilder(
      column: $table.lapses, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnFilters(column));

  $$LocalNotesTableFilterComposer get noteId {
    final $$LocalNotesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableFilterComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> localReviewLogsRefs(
      Expression<bool> Function($$LocalReviewLogsTableFilterComposer f) f) {
    final $$LocalReviewLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localReviewLogs,
        getReferencedColumn: (t) => t.cardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalReviewLogsTableFilterComposer(
              $db: $db,
              $table: $db.localReviewLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalFlashcardsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalFlashcardsTable> {
  $$LocalFlashcardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get front => $composableBuilder(
      column: $table.front, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get back => $composableBuilder(
      column: $table.back, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deck => $composableBuilder(
      column: $table.deck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get step => $composableBuilder(
      column: $table.step, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get easeFactor => $composableBuilder(
      column: $table.easeFactor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
      column: $table.dueAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repetitions => $composableBuilder(
      column: $table.repetitions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapses => $composableBuilder(
      column: $table.lapses, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnOrderings(column));

  $$LocalNotesTableOrderingComposer get noteId {
    final $$LocalNotesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableOrderingComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalFlashcardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalFlashcardsTable> {
  $$LocalFlashcardsTableAnnotationComposer({
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

  GeneratedColumn<String> get front =>
      $composableBuilder(column: $table.front, builder: (column) => column);

  GeneratedColumn<String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  GeneratedColumn<String> get deck =>
      $composableBuilder(column: $table.deck, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<double> get easeFactor => $composableBuilder(
      column: $table.easeFactor, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt, builder: (column) => column);

  GeneratedColumn<int> get repetitions => $composableBuilder(
      column: $table.repetitions, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  $$LocalNotesTableAnnotationComposer get noteId {
    final $$LocalNotesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableAnnotationComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> localReviewLogsRefs<T extends Object>(
      Expression<T> Function($$LocalReviewLogsTableAnnotationComposer a) f) {
    final $$LocalReviewLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localReviewLogs,
        getReferencedColumn: (t) => t.cardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalReviewLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.localReviewLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalFlashcardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalFlashcardsTable,
    LocalFlashcard,
    $$LocalFlashcardsTableFilterComposer,
    $$LocalFlashcardsTableOrderingComposer,
    $$LocalFlashcardsTableAnnotationComposer,
    $$LocalFlashcardsTableCreateCompanionBuilder,
    $$LocalFlashcardsTableUpdateCompanionBuilder,
    (LocalFlashcard, $$LocalFlashcardsTableReferences),
    LocalFlashcard,
    PrefetchHooks Function({bool noteId, bool localReviewLogsRefs})> {
  $$LocalFlashcardsTableTableManager(
      _$AppDatabase db, $LocalFlashcardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFlashcardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalFlashcardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalFlashcardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> noteId = const Value.absent(),
            Value<String> front = const Value.absent(),
            Value<String> back = const Value.absent(),
            Value<String?> deck = const Value.absent(),
            Value<int> step = const Value.absent(),
            Value<double> easeFactor = const Value.absent(),
            Value<DateTime> dueAt = const Value.absent(),
            Value<DateTime?> lastReviewedAt = const Value.absent(),
            Value<int> repetitions = const Value.absent(),
            Value<int> lapses = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalFlashcardsCompanion(
            id: id,
            userId: userId,
            noteId: noteId,
            front: front,
            back: back,
            deck: deck,
            step: step,
            easeFactor: easeFactor,
            dueAt: dueAt,
            lastReviewedAt: lastReviewedAt,
            repetitions: repetitions,
            lapses: lapses,
            createdAt: createdAt,
            isDeleted: isDeleted,
            isSynced: isSynced,
            folderId: folderId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> noteId = const Value.absent(),
            required String front,
            required String back,
            Value<String?> deck = const Value.absent(),
            Value<int> step = const Value.absent(),
            Value<double> easeFactor = const Value.absent(),
            required DateTime dueAt,
            Value<DateTime?> lastReviewedAt = const Value.absent(),
            Value<int> repetitions = const Value.absent(),
            Value<int> lapses = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalFlashcardsCompanion.insert(
            id: id,
            userId: userId,
            noteId: noteId,
            front: front,
            back: back,
            deck: deck,
            step: step,
            easeFactor: easeFactor,
            dueAt: dueAt,
            lastReviewedAt: lastReviewedAt,
            repetitions: repetitions,
            lapses: lapses,
            createdAt: createdAt,
            isDeleted: isDeleted,
            isSynced: isSynced,
            folderId: folderId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalFlashcardsTable, LocalFlashcard>(table),
                    $$LocalFlashcardsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {noteId = false, localReviewLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localReviewLogsRefs) db.localReviewLogs
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (noteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.noteId,
                    referencedTable:
                        $$LocalFlashcardsTableReferences._noteIdTable(db),
                    referencedColumn:
                        $$LocalFlashcardsTableReferences._noteIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localReviewLogsRefs)
                    await $_getPrefetchedData<LocalFlashcard,
                            $LocalFlashcardsTable, LocalReviewLog>(
                        currentTable: table,
                        referencedTable: $$LocalFlashcardsTableReferences
                            ._localReviewLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalFlashcardsTableReferences(db, table, p0)
                                .localReviewLogsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.cardId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LocalFlashcardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalFlashcardsTable,
    LocalFlashcard,
    $$LocalFlashcardsTableFilterComposer,
    $$LocalFlashcardsTableOrderingComposer,
    $$LocalFlashcardsTableAnnotationComposer,
    $$LocalFlashcardsTableCreateCompanionBuilder,
    $$LocalFlashcardsTableUpdateCompanionBuilder,
    (LocalFlashcard, $$LocalFlashcardsTableReferences),
    LocalFlashcard,
    PrefetchHooks Function({bool noteId, bool localReviewLogsRefs})>;
typedef $$LocalReviewLogsTableCreateCompanionBuilder = LocalReviewLogsCompanion
    Function({
  required String id,
  required String userId,
  required String cardId,
  required String grade,
  required int intervalDays,
  required DateTime reviewedAt,
  Value<int> rowid,
});
typedef $$LocalReviewLogsTableUpdateCompanionBuilder = LocalReviewLogsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> cardId,
  Value<String> grade,
  Value<int> intervalDays,
  Value<DateTime> reviewedAt,
  Value<int> rowid,
});

final class $$LocalReviewLogsTableReferences extends BaseReferences<
    _$AppDatabase, $LocalReviewLogsTable, LocalReviewLog> {
  $$LocalReviewLogsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalFlashcardsTable _cardIdTable(_$AppDatabase db) =>
      db.localFlashcards
          .createAlias('local_review_logs__card_id__local_flashcards__id');

  $$LocalFlashcardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<String>('card_id')!;

    final manager =
        $$LocalFlashcardsTableTableManager($_db, $_db.localFlashcards)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalReviewLogsTable> {
  $$LocalReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get grade => $composableBuilder(
      column: $table.grade, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnFilters(column));

  $$LocalFlashcardsTableFilterComposer get cardId {
    final $$LocalFlashcardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.localFlashcards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalFlashcardsTableFilterComposer(
              $db: $db,
              $table: $db.localFlashcards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalReviewLogsTable> {
  $$LocalReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get grade => $composableBuilder(
      column: $table.grade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnOrderings(column));

  $$LocalFlashcardsTableOrderingComposer get cardId {
    final $$LocalFlashcardsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.localFlashcards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalFlashcardsTableOrderingComposer(
              $db: $db,
              $table: $db.localFlashcards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalReviewLogsTable> {
  $$LocalReviewLogsTableAnnotationComposer({
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

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => column);

  $$LocalFlashcardsTableAnnotationComposer get cardId {
    final $$LocalFlashcardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.localFlashcards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalFlashcardsTableAnnotationComposer(
              $db: $db,
              $table: $db.localFlashcards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalReviewLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalReviewLogsTable,
    LocalReviewLog,
    $$LocalReviewLogsTableFilterComposer,
    $$LocalReviewLogsTableOrderingComposer,
    $$LocalReviewLogsTableAnnotationComposer,
    $$LocalReviewLogsTableCreateCompanionBuilder,
    $$LocalReviewLogsTableUpdateCompanionBuilder,
    (LocalReviewLog, $$LocalReviewLogsTableReferences),
    LocalReviewLog,
    PrefetchHooks Function({bool cardId})> {
  $$LocalReviewLogsTableTableManager(
      _$AppDatabase db, $LocalReviewLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> cardId = const Value.absent(),
            Value<String> grade = const Value.absent(),
            Value<int> intervalDays = const Value.absent(),
            Value<DateTime> reviewedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalReviewLogsCompanion(
            id: id,
            userId: userId,
            cardId: cardId,
            grade: grade,
            intervalDays: intervalDays,
            reviewedAt: reviewedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String cardId,
            required String grade,
            required int intervalDays,
            required DateTime reviewedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalReviewLogsCompanion.insert(
            id: id,
            userId: userId,
            cardId: cardId,
            grade: grade,
            intervalDays: intervalDays,
            reviewedAt: reviewedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalReviewLogsTable, LocalReviewLog>(table),
                    $$LocalReviewLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (cardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cardId,
                    referencedTable:
                        $$LocalReviewLogsTableReferences._cardIdTable(db),
                    referencedColumn:
                        $$LocalReviewLogsTableReferences._cardIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocalReviewLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalReviewLogsTable,
    LocalReviewLog,
    $$LocalReviewLogsTableFilterComposer,
    $$LocalReviewLogsTableOrderingComposer,
    $$LocalReviewLogsTableAnnotationComposer,
    $$LocalReviewLogsTableCreateCompanionBuilder,
    $$LocalReviewLogsTableUpdateCompanionBuilder,
    (LocalReviewLog, $$LocalReviewLogsTableReferences),
    LocalReviewLog,
    PrefetchHooks Function({bool cardId})>;
typedef $$LocalSq3rSessionsTableCreateCompanionBuilder
    = LocalSq3rSessionsCompanion Function({
  required String id,
  required String userId,
  required String noteId,
  Value<int> currentStep,
  Value<String> surveyNotes,
  Value<String> questions,
  Value<String> reciteNotes,
  Value<String> reviewNotes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> completedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalSq3rSessionsTableUpdateCompanionBuilder
    = LocalSq3rSessionsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> noteId,
  Value<int> currentStep,
  Value<String> surveyNotes,
  Value<String> questions,
  Value<String> reciteNotes,
  Value<String> reviewNotes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> completedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

final class $$LocalSq3rSessionsTableReferences extends BaseReferences<
    _$AppDatabase, $LocalSq3rSessionsTable, LocalSq3rSession> {
  $$LocalSq3rSessionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalNotesTable _noteIdTable(_$AppDatabase db) => db.localNotes
      .createAlias('local_sq3r_sessions__note_id__local_notes__id');

  $$LocalNotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$LocalNotesTableTableManager($_db, $_db.localNotes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalSq3rSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSq3rSessionsTable> {
  $$LocalSq3rSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentStep => $composableBuilder(
      column: $table.currentStep, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyNotes => $composableBuilder(
      column: $table.surveyNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questions => $composableBuilder(
      column: $table.questions, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reciteNotes => $composableBuilder(
      column: $table.reciteNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reviewNotes => $composableBuilder(
      column: $table.reviewNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  $$LocalNotesTableFilterComposer get noteId {
    final $$LocalNotesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableFilterComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalSq3rSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSq3rSessionsTable> {
  $$LocalSq3rSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentStep => $composableBuilder(
      column: $table.currentStep, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyNotes => $composableBuilder(
      column: $table.surveyNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questions => $composableBuilder(
      column: $table.questions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reciteNotes => $composableBuilder(
      column: $table.reciteNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reviewNotes => $composableBuilder(
      column: $table.reviewNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  $$LocalNotesTableOrderingComposer get noteId {
    final $$LocalNotesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableOrderingComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalSq3rSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSq3rSessionsTable> {
  $$LocalSq3rSessionsTableAnnotationComposer({
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

  GeneratedColumn<int> get currentStep => $composableBuilder(
      column: $table.currentStep, builder: (column) => column);

  GeneratedColumn<String> get surveyNotes => $composableBuilder(
      column: $table.surveyNotes, builder: (column) => column);

  GeneratedColumn<String> get questions =>
      $composableBuilder(column: $table.questions, builder: (column) => column);

  GeneratedColumn<String> get reciteNotes => $composableBuilder(
      column: $table.reciteNotes, builder: (column) => column);

  GeneratedColumn<String> get reviewNotes => $composableBuilder(
      column: $table.reviewNotes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$LocalNotesTableAnnotationComposer get noteId {
    final $$LocalNotesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableAnnotationComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalSq3rSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalSq3rSessionsTable,
    LocalSq3rSession,
    $$LocalSq3rSessionsTableFilterComposer,
    $$LocalSq3rSessionsTableOrderingComposer,
    $$LocalSq3rSessionsTableAnnotationComposer,
    $$LocalSq3rSessionsTableCreateCompanionBuilder,
    $$LocalSq3rSessionsTableUpdateCompanionBuilder,
    (LocalSq3rSession, $$LocalSq3rSessionsTableReferences),
    LocalSq3rSession,
    PrefetchHooks Function({bool noteId})> {
  $$LocalSq3rSessionsTableTableManager(
      _$AppDatabase db, $LocalSq3rSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSq3rSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSq3rSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSq3rSessionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> noteId = const Value.absent(),
            Value<int> currentStep = const Value.absent(),
            Value<String> surveyNotes = const Value.absent(),
            Value<String> questions = const Value.absent(),
            Value<String> reciteNotes = const Value.absent(),
            Value<String> reviewNotes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSq3rSessionsCompanion(
            id: id,
            userId: userId,
            noteId: noteId,
            currentStep: currentStep,
            surveyNotes: surveyNotes,
            questions: questions,
            reciteNotes: reciteNotes,
            reviewNotes: reviewNotes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String noteId,
            Value<int> currentStep = const Value.absent(),
            Value<String> surveyNotes = const Value.absent(),
            Value<String> questions = const Value.absent(),
            Value<String> reciteNotes = const Value.absent(),
            Value<String> reviewNotes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> completedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSq3rSessionsCompanion.insert(
            id: id,
            userId: userId,
            noteId: noteId,
            currentStep: currentStep,
            surveyNotes: surveyNotes,
            questions: questions,
            reciteNotes: reciteNotes,
            reviewNotes: reviewNotes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalSq3rSessionsTable, LocalSq3rSession>(
                        table),
                    $$LocalSq3rSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (noteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.noteId,
                    referencedTable:
                        $$LocalSq3rSessionsTableReferences._noteIdTable(db),
                    referencedColumn:
                        $$LocalSq3rSessionsTableReferences._noteIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocalSq3rSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalSq3rSessionsTable,
    LocalSq3rSession,
    $$LocalSq3rSessionsTableFilterComposer,
    $$LocalSq3rSessionsTableOrderingComposer,
    $$LocalSq3rSessionsTableAnnotationComposer,
    $$LocalSq3rSessionsTableCreateCompanionBuilder,
    $$LocalSq3rSessionsTableUpdateCompanionBuilder,
    (LocalSq3rSession, $$LocalSq3rSessionsTableReferences),
    LocalSq3rSession,
    PrefetchHooks Function({bool noteId})>;
typedef $$LocalExplanationsTableCreateCompanionBuilder
    = LocalExplanationsCompanion Function({
  required String id,
  required String userId,
  required String noteId,
  required String content,
  Value<int> confidence,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalExplanationsTableUpdateCompanionBuilder
    = LocalExplanationsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> noteId,
  Value<String> content,
  Value<int> confidence,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

final class $$LocalExplanationsTableReferences extends BaseReferences<
    _$AppDatabase, $LocalExplanationsTable, LocalExplanation> {
  $$LocalExplanationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalNotesTable _noteIdTable(_$AppDatabase db) =>
      db.localNotes.createAlias('local_explanations__note_id__local_notes__id');

  $$LocalNotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$LocalNotesTableTableManager($_db, $_db.localNotes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalExplanationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalExplanationsTable> {
  $$LocalExplanationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  $$LocalNotesTableFilterComposer get noteId {
    final $$LocalNotesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableFilterComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalExplanationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalExplanationsTable> {
  $$LocalExplanationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  $$LocalNotesTableOrderingComposer get noteId {
    final $$LocalNotesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableOrderingComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalExplanationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalExplanationsTable> {
  $$LocalExplanationsTableAnnotationComposer({
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

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$LocalNotesTableAnnotationComposer get noteId {
    final $$LocalNotesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableAnnotationComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalExplanationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalExplanationsTable,
    LocalExplanation,
    $$LocalExplanationsTableFilterComposer,
    $$LocalExplanationsTableOrderingComposer,
    $$LocalExplanationsTableAnnotationComposer,
    $$LocalExplanationsTableCreateCompanionBuilder,
    $$LocalExplanationsTableUpdateCompanionBuilder,
    (LocalExplanation, $$LocalExplanationsTableReferences),
    LocalExplanation,
    PrefetchHooks Function({bool noteId})> {
  $$LocalExplanationsTableTableManager(
      _$AppDatabase db, $LocalExplanationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalExplanationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalExplanationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalExplanationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> noteId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<int> confidence = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalExplanationsCompanion(
            id: id,
            userId: userId,
            noteId: noteId,
            content: content,
            confidence: confidence,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String noteId,
            required String content,
            Value<int> confidence = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalExplanationsCompanion.insert(
            id: id,
            userId: userId,
            noteId: noteId,
            content: content,
            confidence: confidence,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalExplanationsTable, LocalExplanation>(
                        table),
                    $$LocalExplanationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (noteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.noteId,
                    referencedTable:
                        $$LocalExplanationsTableReferences._noteIdTable(db),
                    referencedColumn:
                        $$LocalExplanationsTableReferences._noteIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocalExplanationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalExplanationsTable,
    LocalExplanation,
    $$LocalExplanationsTableFilterComposer,
    $$LocalExplanationsTableOrderingComposer,
    $$LocalExplanationsTableAnnotationComposer,
    $$LocalExplanationsTableCreateCompanionBuilder,
    $$LocalExplanationsTableUpdateCompanionBuilder,
    (LocalExplanation, $$LocalExplanationsTableReferences),
    LocalExplanation,
    PrefetchHooks Function({bool noteId})>;
typedef $$LocalJournalEntriesTableCreateCompanionBuilder
    = LocalJournalEntriesCompanion Function({
  required String id,
  required String userId,
  Value<String?> noteId,
  Value<int> mood,
  Value<int> energy,
  Value<int> rpe,
  Value<String> whatLearned,
  Value<String> whatWorked,
  Value<String> whatBlocked,
  Value<String> nextStep,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalJournalEntriesTableUpdateCompanionBuilder
    = LocalJournalEntriesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> noteId,
  Value<int> mood,
  Value<int> energy,
  Value<int> rpe,
  Value<String> whatLearned,
  Value<String> whatWorked,
  Value<String> whatBlocked,
  Value<String> nextStep,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

final class $$LocalJournalEntriesTableReferences extends BaseReferences<
    _$AppDatabase, $LocalJournalEntriesTable, LocalJournalEntry> {
  $$LocalJournalEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalNotesTable _noteIdTable(_$AppDatabase db) => db.localNotes
      .createAlias('local_journal_entries__note_id__local_notes__id');

  $$LocalNotesTableProcessedTableManager? get noteId {
    final $_column = $_itemColumn<String>('note_id');
    if ($_column == null) return null;
    final manager = $$LocalNotesTableTableManager($_db, $_db.localNotes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalJournalEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalJournalEntriesTable> {
  $$LocalJournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get energy => $composableBuilder(
      column: $table.energy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rpe => $composableBuilder(
      column: $table.rpe, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get whatLearned => $composableBuilder(
      column: $table.whatLearned, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get whatWorked => $composableBuilder(
      column: $table.whatWorked, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get whatBlocked => $composableBuilder(
      column: $table.whatBlocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nextStep => $composableBuilder(
      column: $table.nextStep, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  $$LocalNotesTableFilterComposer get noteId {
    final $$LocalNotesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableFilterComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalJournalEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalJournalEntriesTable> {
  $$LocalJournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get energy => $composableBuilder(
      column: $table.energy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rpe => $composableBuilder(
      column: $table.rpe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get whatLearned => $composableBuilder(
      column: $table.whatLearned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get whatWorked => $composableBuilder(
      column: $table.whatWorked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get whatBlocked => $composableBuilder(
      column: $table.whatBlocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nextStep => $composableBuilder(
      column: $table.nextStep, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  $$LocalNotesTableOrderingComposer get noteId {
    final $$LocalNotesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableOrderingComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalJournalEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalJournalEntriesTable> {
  $$LocalJournalEntriesTableAnnotationComposer({
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

  GeneratedColumn<int> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<int> get energy =>
      $composableBuilder(column: $table.energy, builder: (column) => column);

  GeneratedColumn<int> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<String> get whatLearned => $composableBuilder(
      column: $table.whatLearned, builder: (column) => column);

  GeneratedColumn<String> get whatWorked => $composableBuilder(
      column: $table.whatWorked, builder: (column) => column);

  GeneratedColumn<String> get whatBlocked => $composableBuilder(
      column: $table.whatBlocked, builder: (column) => column);

  GeneratedColumn<String> get nextStep =>
      $composableBuilder(column: $table.nextStep, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$LocalNotesTableAnnotationComposer get noteId {
    final $$LocalNotesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableAnnotationComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalJournalEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalJournalEntriesTable,
    LocalJournalEntry,
    $$LocalJournalEntriesTableFilterComposer,
    $$LocalJournalEntriesTableOrderingComposer,
    $$LocalJournalEntriesTableAnnotationComposer,
    $$LocalJournalEntriesTableCreateCompanionBuilder,
    $$LocalJournalEntriesTableUpdateCompanionBuilder,
    (LocalJournalEntry, $$LocalJournalEntriesTableReferences),
    LocalJournalEntry,
    PrefetchHooks Function({bool noteId})> {
  $$LocalJournalEntriesTableTableManager(
      _$AppDatabase db, $LocalJournalEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalJournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalJournalEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalJournalEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> noteId = const Value.absent(),
            Value<int> mood = const Value.absent(),
            Value<int> energy = const Value.absent(),
            Value<int> rpe = const Value.absent(),
            Value<String> whatLearned = const Value.absent(),
            Value<String> whatWorked = const Value.absent(),
            Value<String> whatBlocked = const Value.absent(),
            Value<String> nextStep = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalJournalEntriesCompanion(
            id: id,
            userId: userId,
            noteId: noteId,
            mood: mood,
            energy: energy,
            rpe: rpe,
            whatLearned: whatLearned,
            whatWorked: whatWorked,
            whatBlocked: whatBlocked,
            nextStep: nextStep,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> noteId = const Value.absent(),
            Value<int> mood = const Value.absent(),
            Value<int> energy = const Value.absent(),
            Value<int> rpe = const Value.absent(),
            Value<String> whatLearned = const Value.absent(),
            Value<String> whatWorked = const Value.absent(),
            Value<String> whatBlocked = const Value.absent(),
            Value<String> nextStep = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalJournalEntriesCompanion.insert(
            id: id,
            userId: userId,
            noteId: noteId,
            mood: mood,
            energy: energy,
            rpe: rpe,
            whatLearned: whatLearned,
            whatWorked: whatWorked,
            whatBlocked: whatBlocked,
            nextStep: nextStep,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalJournalEntriesTable, LocalJournalEntry>(
                        table),
                    $$LocalJournalEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (noteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.noteId,
                    referencedTable:
                        $$LocalJournalEntriesTableReferences._noteIdTable(db),
                    referencedColumn: $$LocalJournalEntriesTableReferences
                        ._noteIdTable(db)
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
        ));
}

typedef $$LocalJournalEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalJournalEntriesTable,
    LocalJournalEntry,
    $$LocalJournalEntriesTableFilterComposer,
    $$LocalJournalEntriesTableOrderingComposer,
    $$LocalJournalEntriesTableAnnotationComposer,
    $$LocalJournalEntriesTableCreateCompanionBuilder,
    $$LocalJournalEntriesTableUpdateCompanionBuilder,
    (LocalJournalEntry, $$LocalJournalEntriesTableReferences),
    LocalJournalEntry,
    PrefetchHooks Function({bool noteId})>;
typedef $$LocalReframesTableCreateCompanionBuilder = LocalReframesCompanion
    Function({
  required String id,
  required String userId,
  required String limitingThought,
  Value<String?> distortion,
  Value<String> evidenceAgainst,
  Value<String> reframedThought,
  Value<String> growthGoal,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalReframesTableUpdateCompanionBuilder = LocalReframesCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> limitingThought,
  Value<String?> distortion,
  Value<String> evidenceAgainst,
  Value<String> reframedThought,
  Value<String> growthGoal,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$LocalReframesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalReframesTable> {
  $$LocalReframesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get limitingThought => $composableBuilder(
      column: $table.limitingThought,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get distortion => $composableBuilder(
      column: $table.distortion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evidenceAgainst => $composableBuilder(
      column: $table.evidenceAgainst,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reframedThought => $composableBuilder(
      column: $table.reframedThought,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get growthGoal => $composableBuilder(
      column: $table.growthGoal, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$LocalReframesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalReframesTable> {
  $$LocalReframesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get limitingThought => $composableBuilder(
      column: $table.limitingThought,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get distortion => $composableBuilder(
      column: $table.distortion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evidenceAgainst => $composableBuilder(
      column: $table.evidenceAgainst,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reframedThought => $composableBuilder(
      column: $table.reframedThought,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get growthGoal => $composableBuilder(
      column: $table.growthGoal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$LocalReframesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalReframesTable> {
  $$LocalReframesTableAnnotationComposer({
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

  GeneratedColumn<String> get limitingThought => $composableBuilder(
      column: $table.limitingThought, builder: (column) => column);

  GeneratedColumn<String> get distortion => $composableBuilder(
      column: $table.distortion, builder: (column) => column);

  GeneratedColumn<String> get evidenceAgainst => $composableBuilder(
      column: $table.evidenceAgainst, builder: (column) => column);

  GeneratedColumn<String> get reframedThought => $composableBuilder(
      column: $table.reframedThought, builder: (column) => column);

  GeneratedColumn<String> get growthGoal => $composableBuilder(
      column: $table.growthGoal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LocalReframesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalReframesTable,
    LocalReframe,
    $$LocalReframesTableFilterComposer,
    $$LocalReframesTableOrderingComposer,
    $$LocalReframesTableAnnotationComposer,
    $$LocalReframesTableCreateCompanionBuilder,
    $$LocalReframesTableUpdateCompanionBuilder,
    (
      LocalReframe,
      BaseReferences<_$AppDatabase, $LocalReframesTable, LocalReframe>
    ),
    LocalReframe,
    PrefetchHooks Function()> {
  $$LocalReframesTableTableManager(_$AppDatabase db, $LocalReframesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalReframesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalReframesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalReframesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> limitingThought = const Value.absent(),
            Value<String?> distortion = const Value.absent(),
            Value<String> evidenceAgainst = const Value.absent(),
            Value<String> reframedThought = const Value.absent(),
            Value<String> growthGoal = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalReframesCompanion(
            id: id,
            userId: userId,
            limitingThought: limitingThought,
            distortion: distortion,
            evidenceAgainst: evidenceAgainst,
            reframedThought: reframedThought,
            growthGoal: growthGoal,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String limitingThought,
            Value<String?> distortion = const Value.absent(),
            Value<String> evidenceAgainst = const Value.absent(),
            Value<String> reframedThought = const Value.absent(),
            Value<String> growthGoal = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalReframesCompanion.insert(
            id: id,
            userId: userId,
            limitingThought: limitingThought,
            distortion: distortion,
            evidenceAgainst: evidenceAgainst,
            reframedThought: reframedThought,
            growthGoal: growthGoal,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalReframesTable, LocalReframe>(table),
                    BaseReferences<_$AppDatabase, $LocalReframesTable,
                        LocalReframe>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalReframesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalReframesTable,
    LocalReframe,
    $$LocalReframesTableFilterComposer,
    $$LocalReframesTableOrderingComposer,
    $$LocalReframesTableAnnotationComposer,
    $$LocalReframesTableCreateCompanionBuilder,
    $$LocalReframesTableUpdateCompanionBuilder,
    (
      LocalReframe,
      BaseReferences<_$AppDatabase, $LocalReframesTable, LocalReframe>
    ),
    LocalReframe,
    PrefetchHooks Function()>;
typedef $$LocalWhyChainsTableCreateCompanionBuilder = LocalWhyChainsCompanion
    Function({
  required String id,
  required String userId,
  required String problem,
  Value<String> answers,
  Value<String> rootCause,
  Value<String?> blockerType,
  Value<String> actionPlan,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalWhyChainsTableUpdateCompanionBuilder = LocalWhyChainsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> problem,
  Value<String> answers,
  Value<String> rootCause,
  Value<String?> blockerType,
  Value<String> actionPlan,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$LocalWhyChainsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalWhyChainsTable> {
  $$LocalWhyChainsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get problem => $composableBuilder(
      column: $table.problem, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answers => $composableBuilder(
      column: $table.answers, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rootCause => $composableBuilder(
      column: $table.rootCause, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get blockerType => $composableBuilder(
      column: $table.blockerType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionPlan => $composableBuilder(
      column: $table.actionPlan, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$LocalWhyChainsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalWhyChainsTable> {
  $$LocalWhyChainsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get problem => $composableBuilder(
      column: $table.problem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answers => $composableBuilder(
      column: $table.answers, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rootCause => $composableBuilder(
      column: $table.rootCause, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get blockerType => $composableBuilder(
      column: $table.blockerType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionPlan => $composableBuilder(
      column: $table.actionPlan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$LocalWhyChainsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalWhyChainsTable> {
  $$LocalWhyChainsTableAnnotationComposer({
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

  GeneratedColumn<String> get problem =>
      $composableBuilder(column: $table.problem, builder: (column) => column);

  GeneratedColumn<String> get answers =>
      $composableBuilder(column: $table.answers, builder: (column) => column);

  GeneratedColumn<String> get rootCause =>
      $composableBuilder(column: $table.rootCause, builder: (column) => column);

  GeneratedColumn<String> get blockerType => $composableBuilder(
      column: $table.blockerType, builder: (column) => column);

  GeneratedColumn<String> get actionPlan => $composableBuilder(
      column: $table.actionPlan, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LocalWhyChainsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalWhyChainsTable,
    LocalWhyChain,
    $$LocalWhyChainsTableFilterComposer,
    $$LocalWhyChainsTableOrderingComposer,
    $$LocalWhyChainsTableAnnotationComposer,
    $$LocalWhyChainsTableCreateCompanionBuilder,
    $$LocalWhyChainsTableUpdateCompanionBuilder,
    (
      LocalWhyChain,
      BaseReferences<_$AppDatabase, $LocalWhyChainsTable, LocalWhyChain>
    ),
    LocalWhyChain,
    PrefetchHooks Function()> {
  $$LocalWhyChainsTableTableManager(
      _$AppDatabase db, $LocalWhyChainsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalWhyChainsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalWhyChainsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalWhyChainsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> problem = const Value.absent(),
            Value<String> answers = const Value.absent(),
            Value<String> rootCause = const Value.absent(),
            Value<String?> blockerType = const Value.absent(),
            Value<String> actionPlan = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalWhyChainsCompanion(
            id: id,
            userId: userId,
            problem: problem,
            answers: answers,
            rootCause: rootCause,
            blockerType: blockerType,
            actionPlan: actionPlan,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String problem,
            Value<String> answers = const Value.absent(),
            Value<String> rootCause = const Value.absent(),
            Value<String?> blockerType = const Value.absent(),
            Value<String> actionPlan = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalWhyChainsCompanion.insert(
            id: id,
            userId: userId,
            problem: problem,
            answers: answers,
            rootCause: rootCause,
            blockerType: blockerType,
            actionPlan: actionPlan,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalWhyChainsTable, LocalWhyChain>(table),
                    BaseReferences<_$AppDatabase, $LocalWhyChainsTable,
                        LocalWhyChain>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalWhyChainsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalWhyChainsTable,
    LocalWhyChain,
    $$LocalWhyChainsTableFilterComposer,
    $$LocalWhyChainsTableOrderingComposer,
    $$LocalWhyChainsTableAnnotationComposer,
    $$LocalWhyChainsTableCreateCompanionBuilder,
    $$LocalWhyChainsTableUpdateCompanionBuilder,
    (
      LocalWhyChain,
      BaseReferences<_$AppDatabase, $LocalWhyChainsTable, LocalWhyChain>
    ),
    LocalWhyChain,
    PrefetchHooks Function()>;
typedef $$LocalErrorLogsTableCreateCompanionBuilder = LocalErrorLogsCompanion
    Function({
  required String id,
  required String userId,
  Value<String?> noteId,
  Value<String?> subject,
  required String description,
  required String errorType,
  Value<String> correction,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalErrorLogsTableUpdateCompanionBuilder = LocalErrorLogsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> noteId,
  Value<String?> subject,
  Value<String> description,
  Value<String> errorType,
  Value<String> correction,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

final class $$LocalErrorLogsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalErrorLogsTable, LocalErrorLog> {
  $$LocalErrorLogsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalNotesTable _noteIdTable(_$AppDatabase db) =>
      db.localNotes.createAlias('local_error_logs__note_id__local_notes__id');

  $$LocalNotesTableProcessedTableManager? get noteId {
    final $_column = $_itemColumn<String>('note_id');
    if ($_column == null) return null;
    final manager = $$LocalNotesTableTableManager($_db, $_db.localNotes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalErrorLogsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalErrorLogsTable> {
  $$LocalErrorLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorType => $composableBuilder(
      column: $table.errorType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get correction => $composableBuilder(
      column: $table.correction, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  $$LocalNotesTableFilterComposer get noteId {
    final $$LocalNotesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableFilterComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalErrorLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalErrorLogsTable> {
  $$LocalErrorLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorType => $composableBuilder(
      column: $table.errorType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get correction => $composableBuilder(
      column: $table.correction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  $$LocalNotesTableOrderingComposer get noteId {
    final $$LocalNotesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableOrderingComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalErrorLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalErrorLogsTable> {
  $$LocalErrorLogsTableAnnotationComposer({
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

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get errorType =>
      $composableBuilder(column: $table.errorType, builder: (column) => column);

  GeneratedColumn<String> get correction => $composableBuilder(
      column: $table.correction, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$LocalNotesTableAnnotationComposer get noteId {
    final $$LocalNotesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableAnnotationComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalErrorLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalErrorLogsTable,
    LocalErrorLog,
    $$LocalErrorLogsTableFilterComposer,
    $$LocalErrorLogsTableOrderingComposer,
    $$LocalErrorLogsTableAnnotationComposer,
    $$LocalErrorLogsTableCreateCompanionBuilder,
    $$LocalErrorLogsTableUpdateCompanionBuilder,
    (LocalErrorLog, $$LocalErrorLogsTableReferences),
    LocalErrorLog,
    PrefetchHooks Function({bool noteId})> {
  $$LocalErrorLogsTableTableManager(
      _$AppDatabase db, $LocalErrorLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalErrorLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalErrorLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalErrorLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> noteId = const Value.absent(),
            Value<String?> subject = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> errorType = const Value.absent(),
            Value<String> correction = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalErrorLogsCompanion(
            id: id,
            userId: userId,
            noteId: noteId,
            subject: subject,
            description: description,
            errorType: errorType,
            correction: correction,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> noteId = const Value.absent(),
            Value<String?> subject = const Value.absent(),
            required String description,
            required String errorType,
            Value<String> correction = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalErrorLogsCompanion.insert(
            id: id,
            userId: userId,
            noteId: noteId,
            subject: subject,
            description: description,
            errorType: errorType,
            correction: correction,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalErrorLogsTable, LocalErrorLog>(table),
                    $$LocalErrorLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (noteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.noteId,
                    referencedTable:
                        $$LocalErrorLogsTableReferences._noteIdTable(db),
                    referencedColumn:
                        $$LocalErrorLogsTableReferences._noteIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocalErrorLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalErrorLogsTable,
    LocalErrorLog,
    $$LocalErrorLogsTableFilterComposer,
    $$LocalErrorLogsTableOrderingComposer,
    $$LocalErrorLogsTableAnnotationComposer,
    $$LocalErrorLogsTableCreateCompanionBuilder,
    $$LocalErrorLogsTableUpdateCompanionBuilder,
    (LocalErrorLog, $$LocalErrorLogsTableReferences),
    LocalErrorLog,
    PrefetchHooks Function({bool noteId})>;
typedef $$LocalLearningProfilesTableCreateCompanionBuilder
    = LocalLearningProfilesCompanion Function({
  required String userId,
  Value<String> answers,
  Value<String?> processingStyle,
  Value<String?> preferredChannel,
  Value<DateTime?> completedAt,
  required DateTime updatedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalLearningProfilesTableUpdateCompanionBuilder
    = LocalLearningProfilesCompanion Function({
  Value<String> userId,
  Value<String> answers,
  Value<String?> processingStyle,
  Value<String?> preferredChannel,
  Value<DateTime?> completedAt,
  Value<DateTime> updatedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$LocalLearningProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalLearningProfilesTable> {
  $$LocalLearningProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answers => $composableBuilder(
      column: $table.answers, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get processingStyle => $composableBuilder(
      column: $table.processingStyle,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get preferredChannel => $composableBuilder(
      column: $table.preferredChannel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$LocalLearningProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalLearningProfilesTable> {
  $$LocalLearningProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answers => $composableBuilder(
      column: $table.answers, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get processingStyle => $composableBuilder(
      column: $table.processingStyle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get preferredChannel => $composableBuilder(
      column: $table.preferredChannel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$LocalLearningProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalLearningProfilesTable> {
  $$LocalLearningProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get answers =>
      $composableBuilder(column: $table.answers, builder: (column) => column);

  GeneratedColumn<String> get processingStyle => $composableBuilder(
      column: $table.processingStyle, builder: (column) => column);

  GeneratedColumn<String> get preferredChannel => $composableBuilder(
      column: $table.preferredChannel, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LocalLearningProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalLearningProfilesTable,
    LocalLearningProfile,
    $$LocalLearningProfilesTableFilterComposer,
    $$LocalLearningProfilesTableOrderingComposer,
    $$LocalLearningProfilesTableAnnotationComposer,
    $$LocalLearningProfilesTableCreateCompanionBuilder,
    $$LocalLearningProfilesTableUpdateCompanionBuilder,
    (
      LocalLearningProfile,
      BaseReferences<_$AppDatabase, $LocalLearningProfilesTable,
          LocalLearningProfile>
    ),
    LocalLearningProfile,
    PrefetchHooks Function()> {
  $$LocalLearningProfilesTableTableManager(
      _$AppDatabase db, $LocalLearningProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalLearningProfilesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalLearningProfilesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalLearningProfilesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> answers = const Value.absent(),
            Value<String?> processingStyle = const Value.absent(),
            Value<String?> preferredChannel = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalLearningProfilesCompanion(
            userId: userId,
            answers: answers,
            processingStyle: processingStyle,
            preferredChannel: preferredChannel,
            completedAt: completedAt,
            updatedAt: updatedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            Value<String> answers = const Value.absent(),
            Value<String?> processingStyle = const Value.absent(),
            Value<String?> preferredChannel = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            required DateTime updatedAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalLearningProfilesCompanion.insert(
            userId: userId,
            answers: answers,
            processingStyle: processingStyle,
            preferredChannel: preferredChannel,
            completedAt: completedAt,
            updatedAt: updatedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalLearningProfilesTable,
                        LocalLearningProfile>(table),
                    BaseReferences<_$AppDatabase, $LocalLearningProfilesTable,
                        LocalLearningProfile>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalLearningProfilesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $LocalLearningProfilesTable,
        LocalLearningProfile,
        $$LocalLearningProfilesTableFilterComposer,
        $$LocalLearningProfilesTableOrderingComposer,
        $$LocalLearningProfilesTableAnnotationComposer,
        $$LocalLearningProfilesTableCreateCompanionBuilder,
        $$LocalLearningProfilesTableUpdateCompanionBuilder,
        (
          LocalLearningProfile,
          BaseReferences<_$AppDatabase, $LocalLearningProfilesTable,
              LocalLearningProfile>
        ),
        LocalLearningProfile,
        PrefetchHooks Function()>;
typedef $$LocalStudyGoalsTableCreateCompanionBuilder = LocalStudyGoalsCompanion
    Function({
  required String id,
  required String userId,
  required String title,
  Value<String?> subject,
  Value<String> metricLabel,
  Value<double> targetValue,
  Value<double> currentValue,
  Value<String> achievablePlan,
  Value<String> relevance,
  Value<DateTime?> deadline,
  required DateTime createdAt,
  Value<DateTime?> completedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalStudyGoalsTableUpdateCompanionBuilder = LocalStudyGoalsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> title,
  Value<String?> subject,
  Value<String> metricLabel,
  Value<double> targetValue,
  Value<double> currentValue,
  Value<String> achievablePlan,
  Value<String> relevance,
  Value<DateTime?> deadline,
  Value<DateTime> createdAt,
  Value<DateTime?> completedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

final class $$LocalStudyGoalsTableReferences extends BaseReferences<
    _$AppDatabase, $LocalStudyGoalsTable, LocalStudyGoal> {
  $$LocalStudyGoalsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LocalPlanItemsTable, List<LocalPlanItem>>
      _localPlanItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.localPlanItems,
              aliasName: 'local_study_goals__id__local_plan_items__goal_id');

  $$LocalPlanItemsTableProcessedTableManager get localPlanItemsRefs {
    final manager = $$LocalPlanItemsTableTableManager($_db, $_db.localPlanItems)
        .filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_localPlanItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LocalStudyGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStudyGoalsTable> {
  $$LocalStudyGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metricLabel => $composableBuilder(
      column: $table.metricLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetValue => $composableBuilder(
      column: $table.targetValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentValue => $composableBuilder(
      column: $table.currentValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get achievablePlan => $composableBuilder(
      column: $table.achievablePlan,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relevance => $composableBuilder(
      column: $table.relevance, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  Expression<bool> localPlanItemsRefs(
      Expression<bool> Function($$LocalPlanItemsTableFilterComposer f) f) {
    final $$LocalPlanItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localPlanItems,
        getReferencedColumn: (t) => t.goalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalPlanItemsTableFilterComposer(
              $db: $db,
              $table: $db.localPlanItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalStudyGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStudyGoalsTable> {
  $$LocalStudyGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metricLabel => $composableBuilder(
      column: $table.metricLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetValue => $composableBuilder(
      column: $table.targetValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentValue => $composableBuilder(
      column: $table.currentValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get achievablePlan => $composableBuilder(
      column: $table.achievablePlan,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relevance => $composableBuilder(
      column: $table.relevance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
      column: $table.deadline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$LocalStudyGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStudyGoalsTable> {
  $$LocalStudyGoalsTableAnnotationComposer({
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

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get metricLabel => $composableBuilder(
      column: $table.metricLabel, builder: (column) => column);

  GeneratedColumn<double> get targetValue => $composableBuilder(
      column: $table.targetValue, builder: (column) => column);

  GeneratedColumn<double> get currentValue => $composableBuilder(
      column: $table.currentValue, builder: (column) => column);

  GeneratedColumn<String> get achievablePlan => $composableBuilder(
      column: $table.achievablePlan, builder: (column) => column);

  GeneratedColumn<String> get relevance =>
      $composableBuilder(column: $table.relevance, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  Expression<T> localPlanItemsRefs<T extends Object>(
      Expression<T> Function($$LocalPlanItemsTableAnnotationComposer a) f) {
    final $$LocalPlanItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localPlanItems,
        getReferencedColumn: (t) => t.goalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalPlanItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.localPlanItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalStudyGoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalStudyGoalsTable,
    LocalStudyGoal,
    $$LocalStudyGoalsTableFilterComposer,
    $$LocalStudyGoalsTableOrderingComposer,
    $$LocalStudyGoalsTableAnnotationComposer,
    $$LocalStudyGoalsTableCreateCompanionBuilder,
    $$LocalStudyGoalsTableUpdateCompanionBuilder,
    (LocalStudyGoal, $$LocalStudyGoalsTableReferences),
    LocalStudyGoal,
    PrefetchHooks Function({bool localPlanItemsRefs})> {
  $$LocalStudyGoalsTableTableManager(
      _$AppDatabase db, $LocalStudyGoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStudyGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStudyGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalStudyGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> subject = const Value.absent(),
            Value<String> metricLabel = const Value.absent(),
            Value<double> targetValue = const Value.absent(),
            Value<double> currentValue = const Value.absent(),
            Value<String> achievablePlan = const Value.absent(),
            Value<String> relevance = const Value.absent(),
            Value<DateTime?> deadline = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalStudyGoalsCompanion(
            id: id,
            userId: userId,
            title: title,
            subject: subject,
            metricLabel: metricLabel,
            targetValue: targetValue,
            currentValue: currentValue,
            achievablePlan: achievablePlan,
            relevance: relevance,
            deadline: deadline,
            createdAt: createdAt,
            completedAt: completedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String title,
            Value<String?> subject = const Value.absent(),
            Value<String> metricLabel = const Value.absent(),
            Value<double> targetValue = const Value.absent(),
            Value<double> currentValue = const Value.absent(),
            Value<String> achievablePlan = const Value.absent(),
            Value<String> relevance = const Value.absent(),
            Value<DateTime?> deadline = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> completedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalStudyGoalsCompanion.insert(
            id: id,
            userId: userId,
            title: title,
            subject: subject,
            metricLabel: metricLabel,
            targetValue: targetValue,
            currentValue: currentValue,
            achievablePlan: achievablePlan,
            relevance: relevance,
            deadline: deadline,
            createdAt: createdAt,
            completedAt: completedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalStudyGoalsTable, LocalStudyGoal>(table),
                    $$LocalStudyGoalsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({localPlanItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localPlanItemsRefs) db.localPlanItems
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localPlanItemsRefs)
                    await $_getPrefetchedData<LocalStudyGoal,
                            $LocalStudyGoalsTable, LocalPlanItem>(
                        currentTable: table,
                        referencedTable: $$LocalStudyGoalsTableReferences
                            ._localPlanItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalStudyGoalsTableReferences(db, table, p0)
                                .localPlanItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.goalId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LocalStudyGoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalStudyGoalsTable,
    LocalStudyGoal,
    $$LocalStudyGoalsTableFilterComposer,
    $$LocalStudyGoalsTableOrderingComposer,
    $$LocalStudyGoalsTableAnnotationComposer,
    $$LocalStudyGoalsTableCreateCompanionBuilder,
    $$LocalStudyGoalsTableUpdateCompanionBuilder,
    (LocalStudyGoal, $$LocalStudyGoalsTableReferences),
    LocalStudyGoal,
    PrefetchHooks Function({bool localPlanItemsRefs})>;
typedef $$LocalPlanItemsTableCreateCompanionBuilder = LocalPlanItemsCompanion
    Function({
  required String id,
  required String userId,
  Value<String?> goalId,
  Value<String?> taskId,
  required String title,
  Value<String?> subject,
  required DateTime startDate,
  required DateTime endDate,
  Value<double> progress,
  Value<bool> isMilestone,
  Value<String?> dependsOnId,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalPlanItemsTableUpdateCompanionBuilder = LocalPlanItemsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> goalId,
  Value<String?> taskId,
  Value<String> title,
  Value<String?> subject,
  Value<DateTime> startDate,
  Value<DateTime> endDate,
  Value<double> progress,
  Value<bool> isMilestone,
  Value<String?> dependsOnId,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

final class $$LocalPlanItemsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalPlanItemsTable, LocalPlanItem> {
  $$LocalPlanItemsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalStudyGoalsTable _goalIdTable(_$AppDatabase db) =>
      db.localStudyGoals
          .createAlias('local_plan_items__goal_id__local_study_goals__id');

  $$LocalStudyGoalsTableProcessedTableManager? get goalId {
    final $_column = $_itemColumn<String>('goal_id');
    if ($_column == null) return null;
    final manager =
        $$LocalStudyGoalsTableTableManager($_db, $_db.localStudyGoals)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalPlanItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPlanItemsTable> {
  $$LocalPlanItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskId => $composableBuilder(
      column: $table.taskId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMilestone => $composableBuilder(
      column: $table.isMilestone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dependsOnId => $composableBuilder(
      column: $table.dependsOnId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  $$LocalStudyGoalsTableFilterComposer get goalId {
    final $$LocalStudyGoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.localStudyGoals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalStudyGoalsTableFilterComposer(
              $db: $db,
              $table: $db.localStudyGoals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalPlanItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPlanItemsTable> {
  $$LocalPlanItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskId => $composableBuilder(
      column: $table.taskId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMilestone => $composableBuilder(
      column: $table.isMilestone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dependsOnId => $composableBuilder(
      column: $table.dependsOnId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  $$LocalStudyGoalsTableOrderingComposer get goalId {
    final $$LocalStudyGoalsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.localStudyGoals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalStudyGoalsTableOrderingComposer(
              $db: $db,
              $table: $db.localStudyGoals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalPlanItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPlanItemsTable> {
  $$LocalPlanItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<bool> get isMilestone => $composableBuilder(
      column: $table.isMilestone, builder: (column) => column);

  GeneratedColumn<String> get dependsOnId => $composableBuilder(
      column: $table.dependsOnId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$LocalStudyGoalsTableAnnotationComposer get goalId {
    final $$LocalStudyGoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.localStudyGoals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalStudyGoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.localStudyGoals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalPlanItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPlanItemsTable,
    LocalPlanItem,
    $$LocalPlanItemsTableFilterComposer,
    $$LocalPlanItemsTableOrderingComposer,
    $$LocalPlanItemsTableAnnotationComposer,
    $$LocalPlanItemsTableCreateCompanionBuilder,
    $$LocalPlanItemsTableUpdateCompanionBuilder,
    (LocalPlanItem, $$LocalPlanItemsTableReferences),
    LocalPlanItem,
    PrefetchHooks Function({bool goalId})> {
  $$LocalPlanItemsTableTableManager(
      _$AppDatabase db, $LocalPlanItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlanItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlanItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPlanItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> goalId = const Value.absent(),
            Value<String?> taskId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> subject = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime> endDate = const Value.absent(),
            Value<double> progress = const Value.absent(),
            Value<bool> isMilestone = const Value.absent(),
            Value<String?> dependsOnId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPlanItemsCompanion(
            id: id,
            userId: userId,
            goalId: goalId,
            taskId: taskId,
            title: title,
            subject: subject,
            startDate: startDate,
            endDate: endDate,
            progress: progress,
            isMilestone: isMilestone,
            dependsOnId: dependsOnId,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> goalId = const Value.absent(),
            Value<String?> taskId = const Value.absent(),
            required String title,
            Value<String?> subject = const Value.absent(),
            required DateTime startDate,
            required DateTime endDate,
            Value<double> progress = const Value.absent(),
            Value<bool> isMilestone = const Value.absent(),
            Value<String?> dependsOnId = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPlanItemsCompanion.insert(
            id: id,
            userId: userId,
            goalId: goalId,
            taskId: taskId,
            title: title,
            subject: subject,
            startDate: startDate,
            endDate: endDate,
            progress: progress,
            isMilestone: isMilestone,
            dependsOnId: dependsOnId,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalPlanItemsTable, LocalPlanItem>(table),
                    $$LocalPlanItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (goalId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.goalId,
                    referencedTable:
                        $$LocalPlanItemsTableReferences._goalIdTable(db),
                    referencedColumn:
                        $$LocalPlanItemsTableReferences._goalIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocalPlanItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalPlanItemsTable,
    LocalPlanItem,
    $$LocalPlanItemsTableFilterComposer,
    $$LocalPlanItemsTableOrderingComposer,
    $$LocalPlanItemsTableAnnotationComposer,
    $$LocalPlanItemsTableCreateCompanionBuilder,
    $$LocalPlanItemsTableUpdateCompanionBuilder,
    (LocalPlanItem, $$LocalPlanItemsTableReferences),
    LocalPlanItem,
    PrefetchHooks Function({bool goalId})>;
typedef $$LocalSpeedSamplesTableCreateCompanionBuilder
    = LocalSpeedSamplesCompanion Function({
  required String id,
  required String userId,
  required String activity,
  Value<String?> subject,
  required double units,
  required int durationSeconds,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalSpeedSamplesTableUpdateCompanionBuilder
    = LocalSpeedSamplesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> activity,
  Value<String?> subject,
  Value<double> units,
  Value<int> durationSeconds,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$LocalSpeedSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSpeedSamplesTable> {
  $$LocalSpeedSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activity => $composableBuilder(
      column: $table.activity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get units => $composableBuilder(
      column: $table.units, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$LocalSpeedSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSpeedSamplesTable> {
  $$LocalSpeedSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activity => $composableBuilder(
      column: $table.activity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get units => $composableBuilder(
      column: $table.units, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$LocalSpeedSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSpeedSamplesTable> {
  $$LocalSpeedSamplesTableAnnotationComposer({
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

  GeneratedColumn<String> get activity =>
      $composableBuilder(column: $table.activity, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<double> get units =>
      $composableBuilder(column: $table.units, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LocalSpeedSamplesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalSpeedSamplesTable,
    LocalSpeedSample,
    $$LocalSpeedSamplesTableFilterComposer,
    $$LocalSpeedSamplesTableOrderingComposer,
    $$LocalSpeedSamplesTableAnnotationComposer,
    $$LocalSpeedSamplesTableCreateCompanionBuilder,
    $$LocalSpeedSamplesTableUpdateCompanionBuilder,
    (
      LocalSpeedSample,
      BaseReferences<_$AppDatabase, $LocalSpeedSamplesTable, LocalSpeedSample>
    ),
    LocalSpeedSample,
    PrefetchHooks Function()> {
  $$LocalSpeedSamplesTableTableManager(
      _$AppDatabase db, $LocalSpeedSamplesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSpeedSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSpeedSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSpeedSamplesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> activity = const Value.absent(),
            Value<String?> subject = const Value.absent(),
            Value<double> units = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSpeedSamplesCompanion(
            id: id,
            userId: userId,
            activity: activity,
            subject: subject,
            units: units,
            durationSeconds: durationSeconds,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String activity,
            Value<String?> subject = const Value.absent(),
            required double units,
            required int durationSeconds,
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSpeedSamplesCompanion.insert(
            id: id,
            userId: userId,
            activity: activity,
            subject: subject,
            units: units,
            durationSeconds: durationSeconds,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalSpeedSamplesTable, LocalSpeedSample>(
                        table),
                    BaseReferences<_$AppDatabase, $LocalSpeedSamplesTable,
                        LocalSpeedSample>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalSpeedSamplesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalSpeedSamplesTable,
    LocalSpeedSample,
    $$LocalSpeedSamplesTableFilterComposer,
    $$LocalSpeedSamplesTableOrderingComposer,
    $$LocalSpeedSamplesTableAnnotationComposer,
    $$LocalSpeedSamplesTableCreateCompanionBuilder,
    $$LocalSpeedSamplesTableUpdateCompanionBuilder,
    (
      LocalSpeedSample,
      BaseReferences<_$AppDatabase, $LocalSpeedSamplesTable, LocalSpeedSample>
    ),
    LocalSpeedSample,
    PrefetchHooks Function()>;
typedef $$LocalExamTargetsTableCreateCompanionBuilder
    = LocalExamTargetsCompanion Function({
  required String id,
  required String userId,
  Value<String?> noteId,
  required String title,
  Value<String?> subject,
  Value<double> examWeight,
  Value<double> currentGrade,
  Value<double> reachableGrade,
  Value<double> lengthHours,
  Value<int> difficulty,
  Value<DateTime?> examDate,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalExamTargetsTableUpdateCompanionBuilder
    = LocalExamTargetsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> noteId,
  Value<String> title,
  Value<String?> subject,
  Value<double> examWeight,
  Value<double> currentGrade,
  Value<double> reachableGrade,
  Value<double> lengthHours,
  Value<int> difficulty,
  Value<DateTime?> examDate,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

final class $$LocalExamTargetsTableReferences extends BaseReferences<
    _$AppDatabase, $LocalExamTargetsTable, LocalExamTarget> {
  $$LocalExamTargetsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalNotesTable _noteIdTable(_$AppDatabase db) =>
      db.localNotes.createAlias('local_exam_targets__note_id__local_notes__id');

  $$LocalNotesTableProcessedTableManager? get noteId {
    final $_column = $_itemColumn<String>('note_id');
    if ($_column == null) return null;
    final manager = $$LocalNotesTableTableManager($_db, $_db.localNotes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalExamTargetsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalExamTargetsTable> {
  $$LocalExamTargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get examWeight => $composableBuilder(
      column: $table.examWeight, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentGrade => $composableBuilder(
      column: $table.currentGrade, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get reachableGrade => $composableBuilder(
      column: $table.reachableGrade,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lengthHours => $composableBuilder(
      column: $table.lengthHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get examDate => $composableBuilder(
      column: $table.examDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  $$LocalNotesTableFilterComposer get noteId {
    final $$LocalNotesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableFilterComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalExamTargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalExamTargetsTable> {
  $$LocalExamTargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get examWeight => $composableBuilder(
      column: $table.examWeight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentGrade => $composableBuilder(
      column: $table.currentGrade,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get reachableGrade => $composableBuilder(
      column: $table.reachableGrade,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lengthHours => $composableBuilder(
      column: $table.lengthHours, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get examDate => $composableBuilder(
      column: $table.examDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  $$LocalNotesTableOrderingComposer get noteId {
    final $$LocalNotesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableOrderingComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalExamTargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalExamTargetsTable> {
  $$LocalExamTargetsTableAnnotationComposer({
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

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<double> get examWeight => $composableBuilder(
      column: $table.examWeight, builder: (column) => column);

  GeneratedColumn<double> get currentGrade => $composableBuilder(
      column: $table.currentGrade, builder: (column) => column);

  GeneratedColumn<double> get reachableGrade => $composableBuilder(
      column: $table.reachableGrade, builder: (column) => column);

  GeneratedColumn<double> get lengthHours => $composableBuilder(
      column: $table.lengthHours, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<DateTime> get examDate =>
      $composableBuilder(column: $table.examDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$LocalNotesTableAnnotationComposer get noteId {
    final $$LocalNotesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.localNotes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalNotesTableAnnotationComposer(
              $db: $db,
              $table: $db.localNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalExamTargetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalExamTargetsTable,
    LocalExamTarget,
    $$LocalExamTargetsTableFilterComposer,
    $$LocalExamTargetsTableOrderingComposer,
    $$LocalExamTargetsTableAnnotationComposer,
    $$LocalExamTargetsTableCreateCompanionBuilder,
    $$LocalExamTargetsTableUpdateCompanionBuilder,
    (LocalExamTarget, $$LocalExamTargetsTableReferences),
    LocalExamTarget,
    PrefetchHooks Function({bool noteId})> {
  $$LocalExamTargetsTableTableManager(
      _$AppDatabase db, $LocalExamTargetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalExamTargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalExamTargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalExamTargetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> noteId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> subject = const Value.absent(),
            Value<double> examWeight = const Value.absent(),
            Value<double> currentGrade = const Value.absent(),
            Value<double> reachableGrade = const Value.absent(),
            Value<double> lengthHours = const Value.absent(),
            Value<int> difficulty = const Value.absent(),
            Value<DateTime?> examDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalExamTargetsCompanion(
            id: id,
            userId: userId,
            noteId: noteId,
            title: title,
            subject: subject,
            examWeight: examWeight,
            currentGrade: currentGrade,
            reachableGrade: reachableGrade,
            lengthHours: lengthHours,
            difficulty: difficulty,
            examDate: examDate,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> noteId = const Value.absent(),
            required String title,
            Value<String?> subject = const Value.absent(),
            Value<double> examWeight = const Value.absent(),
            Value<double> currentGrade = const Value.absent(),
            Value<double> reachableGrade = const Value.absent(),
            Value<double> lengthHours = const Value.absent(),
            Value<int> difficulty = const Value.absent(),
            Value<DateTime?> examDate = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalExamTargetsCompanion.insert(
            id: id,
            userId: userId,
            noteId: noteId,
            title: title,
            subject: subject,
            examWeight: examWeight,
            currentGrade: currentGrade,
            reachableGrade: reachableGrade,
            lengthHours: lengthHours,
            difficulty: difficulty,
            examDate: examDate,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalExamTargetsTable, LocalExamTarget>(table),
                    $$LocalExamTargetsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (noteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.noteId,
                    referencedTable:
                        $$LocalExamTargetsTableReferences._noteIdTable(db),
                    referencedColumn:
                        $$LocalExamTargetsTableReferences._noteIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocalExamTargetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalExamTargetsTable,
    LocalExamTarget,
    $$LocalExamTargetsTableFilterComposer,
    $$LocalExamTargetsTableOrderingComposer,
    $$LocalExamTargetsTableAnnotationComposer,
    $$LocalExamTargetsTableCreateCompanionBuilder,
    $$LocalExamTargetsTableUpdateCompanionBuilder,
    (LocalExamTarget, $$LocalExamTargetsTableReferences),
    LocalExamTarget,
    PrefetchHooks Function({bool noteId})>;
typedef $$LocalTasksTableCreateCompanionBuilder = LocalTasksCompanion Function({
  required String id,
  required String userId,
  required String title,
  Value<String> description,
  Value<String> status,
  Value<String> priority,
  Value<DateTime?> dueDate,
  Value<bool> isUrgent,
  Value<bool> isImportant,
  Value<int> position,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalTasksTableUpdateCompanionBuilder = LocalTasksCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> title,
  Value<String> description,
  Value<String> status,
  Value<String> priority,
  Value<DateTime?> dueDate,
  Value<bool> isUrgent,
  Value<bool> isImportant,
  Value<int> position,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$LocalTasksTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTasksTable> {
  $$LocalTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isUrgent => $composableBuilder(
      column: $table.isUrgent, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isImportant => $composableBuilder(
      column: $table.isImportant, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$LocalTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTasksTable> {
  $$LocalTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isUrgent => $composableBuilder(
      column: $table.isUrgent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isImportant => $composableBuilder(
      column: $table.isImportant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$LocalTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTasksTable> {
  $$LocalTasksTableAnnotationComposer({
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
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get isUrgent =>
      $composableBuilder(column: $table.isUrgent, builder: (column) => column);

  GeneratedColumn<bool> get isImportant => $composableBuilder(
      column: $table.isImportant, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LocalTasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalTasksTable,
    LocalTask,
    $$LocalTasksTableFilterComposer,
    $$LocalTasksTableOrderingComposer,
    $$LocalTasksTableAnnotationComposer,
    $$LocalTasksTableCreateCompanionBuilder,
    $$LocalTasksTableUpdateCompanionBuilder,
    (LocalTask, BaseReferences<_$AppDatabase, $LocalTasksTable, LocalTask>),
    LocalTask,
    PrefetchHooks Function()> {
  $$LocalTasksTableTableManager(_$AppDatabase db, $LocalTasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<bool> isUrgent = const Value.absent(),
            Value<bool> isImportant = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTasksCompanion(
            id: id,
            userId: userId,
            title: title,
            description: description,
            status: status,
            priority: priority,
            dueDate: dueDate,
            isUrgent: isUrgent,
            isImportant: isImportant,
            position: position,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String title,
            Value<String> description = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<bool> isUrgent = const Value.absent(),
            Value<bool> isImportant = const Value.absent(),
            Value<int> position = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTasksCompanion.insert(
            id: id,
            userId: userId,
            title: title,
            description: description,
            status: status,
            priority: priority,
            dueDate: dueDate,
            isUrgent: isUrgent,
            isImportant: isImportant,
            position: position,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalTasksTable, LocalTask>(table),
                    BaseReferences<_$AppDatabase, $LocalTasksTable, LocalTask>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalTasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalTasksTable,
    LocalTask,
    $$LocalTasksTableFilterComposer,
    $$LocalTasksTableOrderingComposer,
    $$LocalTasksTableAnnotationComposer,
    $$LocalTasksTableCreateCompanionBuilder,
    $$LocalTasksTableUpdateCompanionBuilder,
    (LocalTask, BaseReferences<_$AppDatabase, $LocalTasksTable, LocalTask>),
    LocalTask,
    PrefetchHooks Function()>;
typedef $$LocalHabitsTableCreateCompanionBuilder = LocalHabitsCompanion
    Function({
  required String id,
  required String userId,
  required String name,
  Value<String> frequency,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<String?> position,
  Value<int> rowid,
});
typedef $$LocalHabitsTableUpdateCompanionBuilder = LocalHabitsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> name,
  Value<String> frequency,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<String?> position,
  Value<int> rowid,
});

final class $$LocalHabitsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalHabitsTable, LocalHabit> {
  $$LocalHabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LocalHabitLogsTable, List<LocalHabitLog>>
      _localHabitLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.localHabitLogs,
              aliasName: 'local_habits__id__local_habit_logs__habit_id');

  $$LocalHabitLogsTableProcessedTableManager get localHabitLogsRefs {
    final manager = $$LocalHabitLogsTableTableManager($_db, $_db.localHabitLogs)
        .filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_localHabitLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LocalHabitsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalHabitsTable> {
  $$LocalHabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  Expression<bool> localHabitLogsRefs(
      Expression<bool> Function($$LocalHabitLogsTableFilterComposer f) f) {
    final $$LocalHabitLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localHabitLogs,
        getReferencedColumn: (t) => t.habitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalHabitLogsTableFilterComposer(
              $db: $db,
              $table: $db.localHabitLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalHabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalHabitsTable> {
  $$LocalHabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));
}

class $$LocalHabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalHabitsTable> {
  $$LocalHabitsTableAnnotationComposer({
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  Expression<T> localHabitLogsRefs<T extends Object>(
      Expression<T> Function($$LocalHabitLogsTableAnnotationComposer a) f) {
    final $$LocalHabitLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localHabitLogs,
        getReferencedColumn: (t) => t.habitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalHabitLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.localHabitLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalHabitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalHabitsTable,
    LocalHabit,
    $$LocalHabitsTableFilterComposer,
    $$LocalHabitsTableOrderingComposer,
    $$LocalHabitsTableAnnotationComposer,
    $$LocalHabitsTableCreateCompanionBuilder,
    $$LocalHabitsTableUpdateCompanionBuilder,
    (LocalHabit, $$LocalHabitsTableReferences),
    LocalHabit,
    PrefetchHooks Function({bool localHabitLogsRefs})> {
  $$LocalHabitsTableTableManager(_$AppDatabase db, $LocalHabitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalHabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalHabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalHabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<String?> position = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalHabitsCompanion(
            id: id,
            userId: userId,
            name: name,
            frequency: frequency,
            createdAt: createdAt,
            isSynced: isSynced,
            position: position,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String name,
            Value<String> frequency = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<String?> position = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalHabitsCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            frequency: frequency,
            createdAt: createdAt,
            isSynced: isSynced,
            position: position,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalHabitsTable, LocalHabit>(table),
                    $$LocalHabitsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({localHabitLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localHabitLogsRefs) db.localHabitLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localHabitLogsRefs)
                    await $_getPrefetchedData<LocalHabit, $LocalHabitsTable,
                            LocalHabitLog>(
                        currentTable: table,
                        referencedTable: $$LocalHabitsTableReferences
                            ._localHabitLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalHabitsTableReferences(db, table, p0)
                                .localHabitLogsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.habitId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LocalHabitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalHabitsTable,
    LocalHabit,
    $$LocalHabitsTableFilterComposer,
    $$LocalHabitsTableOrderingComposer,
    $$LocalHabitsTableAnnotationComposer,
    $$LocalHabitsTableCreateCompanionBuilder,
    $$LocalHabitsTableUpdateCompanionBuilder,
    (LocalHabit, $$LocalHabitsTableReferences),
    LocalHabit,
    PrefetchHooks Function({bool localHabitLogsRefs})>;
typedef $$LocalHabitLogsTableCreateCompanionBuilder = LocalHabitLogsCompanion
    Function({
  required String habitId,
  required String date,
  Value<int> rowid,
});
typedef $$LocalHabitLogsTableUpdateCompanionBuilder = LocalHabitLogsCompanion
    Function({
  Value<String> habitId,
  Value<String> date,
  Value<int> rowid,
});

final class $$LocalHabitLogsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalHabitLogsTable, LocalHabitLog> {
  $$LocalHabitLogsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalHabitsTable _habitIdTable(_$AppDatabase db) => db.localHabits
      .createAlias('local_habit_logs__habit_id__local_habits__id');

  $$LocalHabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$LocalHabitsTableTableManager($_db, $_db.localHabits)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalHabitLogsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalHabitLogsTable> {
  $$LocalHabitLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  $$LocalHabitsTableFilterComposer get habitId {
    final $$LocalHabitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.habitId,
        referencedTable: $db.localHabits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalHabitsTableFilterComposer(
              $db: $db,
              $table: $db.localHabits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalHabitLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalHabitLogsTable> {
  $$LocalHabitLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  $$LocalHabitsTableOrderingComposer get habitId {
    final $$LocalHabitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.habitId,
        referencedTable: $db.localHabits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalHabitsTableOrderingComposer(
              $db: $db,
              $table: $db.localHabits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalHabitLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalHabitLogsTable> {
  $$LocalHabitLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  $$LocalHabitsTableAnnotationComposer get habitId {
    final $$LocalHabitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.habitId,
        referencedTable: $db.localHabits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalHabitsTableAnnotationComposer(
              $db: $db,
              $table: $db.localHabits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalHabitLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalHabitLogsTable,
    LocalHabitLog,
    $$LocalHabitLogsTableFilterComposer,
    $$LocalHabitLogsTableOrderingComposer,
    $$LocalHabitLogsTableAnnotationComposer,
    $$LocalHabitLogsTableCreateCompanionBuilder,
    $$LocalHabitLogsTableUpdateCompanionBuilder,
    (LocalHabitLog, $$LocalHabitLogsTableReferences),
    LocalHabitLog,
    PrefetchHooks Function({bool habitId})> {
  $$LocalHabitLogsTableTableManager(
      _$AppDatabase db, $LocalHabitLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalHabitLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalHabitLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalHabitLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> habitId = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalHabitLogsCompanion(
            habitId: habitId,
            date: date,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String habitId,
            required String date,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalHabitLogsCompanion.insert(
            habitId: habitId,
            date: date,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalHabitLogsTable, LocalHabitLog>(table),
                    $$LocalHabitLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (habitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.habitId,
                    referencedTable:
                        $$LocalHabitLogsTableReferences._habitIdTable(db),
                    referencedColumn:
                        $$LocalHabitLogsTableReferences._habitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocalHabitLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalHabitLogsTable,
    LocalHabitLog,
    $$LocalHabitLogsTableFilterComposer,
    $$LocalHabitLogsTableOrderingComposer,
    $$LocalHabitLogsTableAnnotationComposer,
    $$LocalHabitLogsTableCreateCompanionBuilder,
    $$LocalHabitLogsTableUpdateCompanionBuilder,
    (LocalHabitLog, $$LocalHabitLogsTableReferences),
    LocalHabitLog,
    PrefetchHooks Function({bool habitId})>;
typedef $$LocalPomodoroSessionsTableCreateCompanionBuilder
    = LocalPomodoroSessionsCompanion Function({
  required String id,
  required String userId,
  required DateTime startedAt,
  required int durationSeconds,
  Value<String?> taskId,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalPomodoroSessionsTableUpdateCompanionBuilder
    = LocalPomodoroSessionsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<DateTime> startedAt,
  Value<int> durationSeconds,
  Value<String?> taskId,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$LocalPomodoroSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPomodoroSessionsTable> {
  $$LocalPomodoroSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskId => $composableBuilder(
      column: $table.taskId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$LocalPomodoroSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPomodoroSessionsTable> {
  $$LocalPomodoroSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskId => $composableBuilder(
      column: $table.taskId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$LocalPomodoroSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPomodoroSessionsTable> {
  $$LocalPomodoroSessionsTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LocalPomodoroSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPomodoroSessionsTable,
    LocalPomodoroSession,
    $$LocalPomodoroSessionsTableFilterComposer,
    $$LocalPomodoroSessionsTableOrderingComposer,
    $$LocalPomodoroSessionsTableAnnotationComposer,
    $$LocalPomodoroSessionsTableCreateCompanionBuilder,
    $$LocalPomodoroSessionsTableUpdateCompanionBuilder,
    (
      LocalPomodoroSession,
      BaseReferences<_$AppDatabase, $LocalPomodoroSessionsTable,
          LocalPomodoroSession>
    ),
    LocalPomodoroSession,
    PrefetchHooks Function()> {
  $$LocalPomodoroSessionsTableTableManager(
      _$AppDatabase db, $LocalPomodoroSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPomodoroSessionsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPomodoroSessionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPomodoroSessionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<String?> taskId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPomodoroSessionsCompanion(
            id: id,
            userId: userId,
            startedAt: startedAt,
            durationSeconds: durationSeconds,
            taskId: taskId,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required DateTime startedAt,
            required int durationSeconds,
            Value<String?> taskId = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPomodoroSessionsCompanion.insert(
            id: id,
            userId: userId,
            startedAt: startedAt,
            durationSeconds: durationSeconds,
            taskId: taskId,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalPomodoroSessionsTable,
                        LocalPomodoroSession>(table),
                    BaseReferences<_$AppDatabase, $LocalPomodoroSessionsTable,
                        LocalPomodoroSession>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalPomodoroSessionsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $LocalPomodoroSessionsTable,
        LocalPomodoroSession,
        $$LocalPomodoroSessionsTableFilterComposer,
        $$LocalPomodoroSessionsTableOrderingComposer,
        $$LocalPomodoroSessionsTableAnnotationComposer,
        $$LocalPomodoroSessionsTableCreateCompanionBuilder,
        $$LocalPomodoroSessionsTableUpdateCompanionBuilder,
        (
          LocalPomodoroSession,
          BaseReferences<_$AppDatabase, $LocalPomodoroSessionsTable,
              LocalPomodoroSession>
        ),
        LocalPomodoroSession,
        PrefetchHooks Function()>;
typedef $$SyncQueueEntriesTableCreateCompanionBuilder
    = SyncQueueEntriesCompanion Function({
  Value<int> id,
  required String entityTable,
  required String entityId,
  required String operation,
  required DateTime queuedAt,
  Value<int> attempts,
  Value<String?> lastError,
});
typedef $$SyncQueueEntriesTableUpdateCompanionBuilder
    = SyncQueueEntriesCompanion Function({
  Value<int> id,
  Value<String> entityTable,
  Value<String> entityId,
  Value<String> operation,
  Value<DateTime> queuedAt,
  Value<int> attempts,
  Value<String?> lastError,
});

class $$SyncQueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
      column: $table.queuedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
      column: $table.queuedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueEntriesTable> {
  $$SyncQueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueEntriesTable,
    SyncQueueEntry,
    $$SyncQueueEntriesTableFilterComposer,
    $$SyncQueueEntriesTableOrderingComposer,
    $$SyncQueueEntriesTableAnnotationComposer,
    $$SyncQueueEntriesTableCreateCompanionBuilder,
    $$SyncQueueEntriesTableUpdateCompanionBuilder,
    (
      SyncQueueEntry,
      BaseReferences<_$AppDatabase, $SyncQueueEntriesTable, SyncQueueEntry>
    ),
    SyncQueueEntry,
    PrefetchHooks Function()> {
  $$SyncQueueEntriesTableTableManager(
      _$AppDatabase db, $SyncQueueEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityTable = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<DateTime> queuedAt = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
          }) =>
              SyncQueueEntriesCompanion(
            id: id,
            entityTable: entityTable,
            entityId: entityId,
            operation: operation,
            queuedAt: queuedAt,
            attempts: attempts,
            lastError: lastError,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityTable,
            required String entityId,
            required String operation,
            required DateTime queuedAt,
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
          }) =>
              SyncQueueEntriesCompanion.insert(
            id: id,
            entityTable: entityTable,
            entityId: entityId,
            operation: operation,
            queuedAt: queuedAt,
            attempts: attempts,
            lastError: lastError,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncQueueEntriesTable, SyncQueueEntry>(table),
                    BaseReferences<_$AppDatabase, $SyncQueueEntriesTable,
                        SyncQueueEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueEntriesTable,
    SyncQueueEntry,
    $$SyncQueueEntriesTableFilterComposer,
    $$SyncQueueEntriesTableOrderingComposer,
    $$SyncQueueEntriesTableAnnotationComposer,
    $$SyncQueueEntriesTableCreateCompanionBuilder,
    $$SyncQueueEntriesTableUpdateCompanionBuilder,
    (
      SyncQueueEntry,
      BaseReferences<_$AppDatabase, $SyncQueueEntriesTable, SyncQueueEntry>
    ),
    SyncQueueEntry,
    PrefetchHooks Function()>;
typedef $$SyncCursorsTableCreateCompanionBuilder = SyncCursorsCompanion
    Function({
  required String userId,
  required String remoteTable,
  required String pulledUntil,
  Value<int> rowid,
});
typedef $$SyncCursorsTableUpdateCompanionBuilder = SyncCursorsCompanion
    Function({
  Value<String> userId,
  Value<String> remoteTable,
  Value<String> pulledUntil,
  Value<int> rowid,
});

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteTable => $composableBuilder(
      column: $table.remoteTable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pulledUntil => $composableBuilder(
      column: $table.pulledUntil, builder: (column) => ColumnFilters(column));
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteTable => $composableBuilder(
      column: $table.remoteTable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pulledUntil => $composableBuilder(
      column: $table.pulledUntil, builder: (column) => ColumnOrderings(column));
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get remoteTable => $composableBuilder(
      column: $table.remoteTable, builder: (column) => column);

  GeneratedColumn<String> get pulledUntil => $composableBuilder(
      column: $table.pulledUntil, builder: (column) => column);
}

class $$SyncCursorsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncCursorsTable,
    SyncCursor,
    $$SyncCursorsTableFilterComposer,
    $$SyncCursorsTableOrderingComposer,
    $$SyncCursorsTableAnnotationComposer,
    $$SyncCursorsTableCreateCompanionBuilder,
    $$SyncCursorsTableUpdateCompanionBuilder,
    (SyncCursor, BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>),
    SyncCursor,
    PrefetchHooks Function()> {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> remoteTable = const Value.absent(),
            Value<String> pulledUntil = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncCursorsCompanion(
            userId: userId,
            remoteTable: remoteTable,
            pulledUntil: pulledUntil,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String remoteTable,
            required String pulledUntil,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncCursorsCompanion.insert(
            userId: userId,
            remoteTable: remoteTable,
            pulledUntil: pulledUntil,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncCursorsTable, SyncCursor>(table),
                    BaseReferences<_$AppDatabase, $SyncCursorsTable,
                        SyncCursor>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncCursorsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncCursorsTable,
    SyncCursor,
    $$SyncCursorsTableFilterComposer,
    $$SyncCursorsTableOrderingComposer,
    $$SyncCursorsTableAnnotationComposer,
    $$SyncCursorsTableCreateCompanionBuilder,
    $$SyncCursorsTableUpdateCompanionBuilder,
    (SyncCursor, BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>),
    SyncCursor,
    PrefetchHooks Function()>;
typedef $$LocalPreferencesTableCreateCompanionBuilder
    = LocalPreferencesCompanion Function({
  required String userId,
  Value<String?> settings,
  Value<String?> dashboardLayout,
  Value<int> rowid,
});
typedef $$LocalPreferencesTableUpdateCompanionBuilder
    = LocalPreferencesCompanion Function({
  Value<String> userId,
  Value<String?> settings,
  Value<String?> dashboardLayout,
  Value<int> rowid,
});

class $$LocalPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPreferencesTable> {
  $$LocalPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get settings => $composableBuilder(
      column: $table.settings, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dashboardLayout => $composableBuilder(
      column: $table.dashboardLayout,
      builder: (column) => ColumnFilters(column));
}

class $$LocalPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPreferencesTable> {
  $$LocalPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get settings => $composableBuilder(
      column: $table.settings, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dashboardLayout => $composableBuilder(
      column: $table.dashboardLayout,
      builder: (column) => ColumnOrderings(column));
}

class $$LocalPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPreferencesTable> {
  $$LocalPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get settings =>
      $composableBuilder(column: $table.settings, builder: (column) => column);

  GeneratedColumn<String> get dashboardLayout => $composableBuilder(
      column: $table.dashboardLayout, builder: (column) => column);
}

class $$LocalPreferencesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPreferencesTable,
    LocalPreference,
    $$LocalPreferencesTableFilterComposer,
    $$LocalPreferencesTableOrderingComposer,
    $$LocalPreferencesTableAnnotationComposer,
    $$LocalPreferencesTableCreateCompanionBuilder,
    $$LocalPreferencesTableUpdateCompanionBuilder,
    (
      LocalPreference,
      BaseReferences<_$AppDatabase, $LocalPreferencesTable, LocalPreference>
    ),
    LocalPreference,
    PrefetchHooks Function()> {
  $$LocalPreferencesTableTableManager(
      _$AppDatabase db, $LocalPreferencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String?> settings = const Value.absent(),
            Value<String?> dashboardLayout = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPreferencesCompanion(
            userId: userId,
            settings: settings,
            dashboardLayout: dashboardLayout,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            Value<String?> settings = const Value.absent(),
            Value<String?> dashboardLayout = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPreferencesCompanion.insert(
            userId: userId,
            settings: settings,
            dashboardLayout: dashboardLayout,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalPreferencesTable, LocalPreference>(table),
                    BaseReferences<_$AppDatabase, $LocalPreferencesTable,
                        LocalPreference>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalPreferencesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalPreferencesTable,
    LocalPreference,
    $$LocalPreferencesTableFilterComposer,
    $$LocalPreferencesTableOrderingComposer,
    $$LocalPreferencesTableAnnotationComposer,
    $$LocalPreferencesTableCreateCompanionBuilder,
    $$LocalPreferencesTableUpdateCompanionBuilder,
    (
      LocalPreference,
      BaseReferences<_$AppDatabase, $LocalPreferencesTable, LocalPreference>
    ),
    LocalPreference,
    PrefetchHooks Function()>;
typedef $$LocalFoldersTableCreateCompanionBuilder = LocalFoldersCompanion
    Function({
  required String id,
  required String userId,
  Value<String?> parentId,
  required String name,
  Value<String?> position,
  required DateTime createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalFoldersTableUpdateCompanionBuilder = LocalFoldersCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> parentId,
  Value<String> name,
  Value<String?> position,
  Value<DateTime> createdAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$LocalFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalFoldersTable> {
  $$LocalFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$LocalFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalFoldersTable> {
  $$LocalFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$LocalFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalFoldersTable> {
  $$LocalFoldersTableAnnotationComposer({
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

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$LocalFoldersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalFoldersTable,
    LocalFolder,
    $$LocalFoldersTableFilterComposer,
    $$LocalFoldersTableOrderingComposer,
    $$LocalFoldersTableAnnotationComposer,
    $$LocalFoldersTableCreateCompanionBuilder,
    $$LocalFoldersTableUpdateCompanionBuilder,
    (
      LocalFolder,
      BaseReferences<_$AppDatabase, $LocalFoldersTable, LocalFolder>
    ),
    LocalFolder,
    PrefetchHooks Function()> {
  $$LocalFoldersTableTableManager(_$AppDatabase db, $LocalFoldersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> position = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalFoldersCompanion(
            id: id,
            userId: userId,
            parentId: parentId,
            name: name,
            position: position,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> parentId = const Value.absent(),
            required String name,
            Value<String?> position = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalFoldersCompanion.insert(
            id: id,
            userId: userId,
            parentId: parentId,
            name: name,
            position: position,
            createdAt: createdAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalFoldersTable, LocalFolder>(table),
                    BaseReferences<_$AppDatabase, $LocalFoldersTable,
                        LocalFolder>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalFoldersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalFoldersTable,
    LocalFolder,
    $$LocalFoldersTableFilterComposer,
    $$LocalFoldersTableOrderingComposer,
    $$LocalFoldersTableAnnotationComposer,
    $$LocalFoldersTableCreateCompanionBuilder,
    $$LocalFoldersTableUpdateCompanionBuilder,
    (
      LocalFolder,
      BaseReferences<_$AppDatabase, $LocalFoldersTable, LocalFolder>
    ),
    LocalFolder,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalNotesTableTableManager get localNotes =>
      $$LocalNotesTableTableManager(_db, _db.localNotes);
  $$LocalNoteBlocksTableTableManager get localNoteBlocks =>
      $$LocalNoteBlocksTableTableManager(_db, _db.localNoteBlocks);
  $$LocalNoteLinksTableTableManager get localNoteLinks =>
      $$LocalNoteLinksTableTableManager(_db, _db.localNoteLinks);
  $$LocalFlashcardsTableTableManager get localFlashcards =>
      $$LocalFlashcardsTableTableManager(_db, _db.localFlashcards);
  $$LocalReviewLogsTableTableManager get localReviewLogs =>
      $$LocalReviewLogsTableTableManager(_db, _db.localReviewLogs);
  $$LocalSq3rSessionsTableTableManager get localSq3rSessions =>
      $$LocalSq3rSessionsTableTableManager(_db, _db.localSq3rSessions);
  $$LocalExplanationsTableTableManager get localExplanations =>
      $$LocalExplanationsTableTableManager(_db, _db.localExplanations);
  $$LocalJournalEntriesTableTableManager get localJournalEntries =>
      $$LocalJournalEntriesTableTableManager(_db, _db.localJournalEntries);
  $$LocalReframesTableTableManager get localReframes =>
      $$LocalReframesTableTableManager(_db, _db.localReframes);
  $$LocalWhyChainsTableTableManager get localWhyChains =>
      $$LocalWhyChainsTableTableManager(_db, _db.localWhyChains);
  $$LocalErrorLogsTableTableManager get localErrorLogs =>
      $$LocalErrorLogsTableTableManager(_db, _db.localErrorLogs);
  $$LocalLearningProfilesTableTableManager get localLearningProfiles =>
      $$LocalLearningProfilesTableTableManager(_db, _db.localLearningProfiles);
  $$LocalStudyGoalsTableTableManager get localStudyGoals =>
      $$LocalStudyGoalsTableTableManager(_db, _db.localStudyGoals);
  $$LocalPlanItemsTableTableManager get localPlanItems =>
      $$LocalPlanItemsTableTableManager(_db, _db.localPlanItems);
  $$LocalSpeedSamplesTableTableManager get localSpeedSamples =>
      $$LocalSpeedSamplesTableTableManager(_db, _db.localSpeedSamples);
  $$LocalExamTargetsTableTableManager get localExamTargets =>
      $$LocalExamTargetsTableTableManager(_db, _db.localExamTargets);
  $$LocalTasksTableTableManager get localTasks =>
      $$LocalTasksTableTableManager(_db, _db.localTasks);
  $$LocalHabitsTableTableManager get localHabits =>
      $$LocalHabitsTableTableManager(_db, _db.localHabits);
  $$LocalHabitLogsTableTableManager get localHabitLogs =>
      $$LocalHabitLogsTableTableManager(_db, _db.localHabitLogs);
  $$LocalPomodoroSessionsTableTableManager get localPomodoroSessions =>
      $$LocalPomodoroSessionsTableTableManager(_db, _db.localPomodoroSessions);
  $$SyncQueueEntriesTableTableManager get syncQueueEntries =>
      $$SyncQueueEntriesTableTableManager(_db, _db.syncQueueEntries);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$LocalPreferencesTableTableManager get localPreferences =>
      $$LocalPreferencesTableTableManager(_db, _db.localPreferences);
  $$LocalFoldersTableTableManager get localFolders =>
      $$LocalFoldersTableTableManager(_db, _db.localFolders);
}
