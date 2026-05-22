// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
mixin _$PodcastDaoMixin on DatabaseAccessor<AppDatabase> {
  $PodcastsTable get podcasts => attachedDatabase.podcasts;
  PodcastDaoManager get managers => PodcastDaoManager(this);
}

class PodcastDaoManager {
  final _$PodcastDaoMixin _db;
  PodcastDaoManager(this._db);
  $$PodcastsTableTableManager get podcasts =>
      $$PodcastsTableTableManager(_db.attachedDatabase, _db.podcasts);
}

mixin _$EpisodeDaoMixin on DatabaseAccessor<AppDatabase> {
  $PodcastsTable get podcasts => attachedDatabase.podcasts;
  $EpisodesTable get episodes => attachedDatabase.episodes;
  EpisodeDaoManager get managers => EpisodeDaoManager(this);
}

class EpisodeDaoManager {
  final _$EpisodeDaoMixin _db;
  EpisodeDaoManager(this._db);
  $$PodcastsTableTableManager get podcasts =>
      $$PodcastsTableTableManager(_db.attachedDatabase, _db.podcasts);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db.attachedDatabase, _db.episodes);
}

mixin _$TranscriptDaoMixin on DatabaseAccessor<AppDatabase> {
  $PodcastsTable get podcasts => attachedDatabase.podcasts;
  $EpisodesTable get episodes => attachedDatabase.episodes;
  $TranscriptsTable get transcripts => attachedDatabase.transcripts;
  TranscriptDaoManager get managers => TranscriptDaoManager(this);
}

class TranscriptDaoManager {
  final _$TranscriptDaoMixin _db;
  TranscriptDaoManager(this._db);
  $$PodcastsTableTableManager get podcasts =>
      $$PodcastsTableTableManager(_db.attachedDatabase, _db.podcasts);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db.attachedDatabase, _db.episodes);
  $$TranscriptsTableTableManager get transcripts =>
      $$TranscriptsTableTableManager(_db.attachedDatabase, _db.transcripts);
}

mixin _$QueueDaoMixin on DatabaseAccessor<AppDatabase> {
  $PodcastsTable get podcasts => attachedDatabase.podcasts;
  $EpisodesTable get episodes => attachedDatabase.episodes;
  $QueueItemsTable get queueItems => attachedDatabase.queueItems;
  QueueDaoManager get managers => QueueDaoManager(this);
}

class QueueDaoManager {
  final _$QueueDaoMixin _db;
  QueueDaoManager(this._db);
  $$PodcastsTableTableManager get podcasts =>
      $$PodcastsTableTableManager(_db.attachedDatabase, _db.podcasts);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db.attachedDatabase, _db.episodes);
  $$QueueItemsTableTableManager get queueItems =>
      $$QueueItemsTableTableManager(_db.attachedDatabase, _db.queueItems);
}

class $PodcastsTable extends Podcasts with TableInfo<$PodcastsTable, Podcast> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PodcastsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedUrlMeta = const VerificationMeta(
    'feedUrl',
  );
  @override
  late final GeneratedColumn<String> feedUrl = GeneratedColumn<String>(
    'feed_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _lastFetchedMeta = const VerificationMeta(
    'lastFetched',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetched = GeneratedColumn<DateTime>(
    'last_fetched',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subscribedMeta = const VerificationMeta(
    'subscribed',
  );
  @override
  late final GeneratedColumn<bool> subscribed = GeneratedColumn<bool>(
    'subscribed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("subscribed" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    feedUrl,
    imageUrl,
    author,
    description,
    lastFetched,
    subscribed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'podcasts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Podcast> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('feed_url')) {
      context.handle(
        _feedUrlMeta,
        feedUrl.isAcceptableOrUnknown(data['feed_url']!, _feedUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_feedUrlMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
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
    if (data.containsKey('last_fetched')) {
      context.handle(
        _lastFetchedMeta,
        lastFetched.isAcceptableOrUnknown(
          data['last_fetched']!,
          _lastFetchedMeta,
        ),
      );
    }
    if (data.containsKey('subscribed')) {
      context.handle(
        _subscribedMeta,
        subscribed.isAcceptableOrUnknown(data['subscribed']!, _subscribedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Podcast map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Podcast(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      feedUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_url'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      lastFetched: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetched'],
      ),
      subscribed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}subscribed'],
      )!,
    );
  }

  @override
  $PodcastsTable createAlias(String alias) {
    return $PodcastsTable(attachedDatabase, alias);
  }
}

class Podcast extends DataClass implements Insertable<Podcast> {
  final int id;
  final String title;
  final String feedUrl;
  final String? imageUrl;
  final String? author;
  final String? description;
  final DateTime? lastFetched;
  final bool subscribed;
  const Podcast({
    required this.id,
    required this.title,
    required this.feedUrl,
    this.imageUrl,
    this.author,
    this.description,
    this.lastFetched,
    required this.subscribed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['feed_url'] = Variable<String>(feedUrl);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || lastFetched != null) {
      map['last_fetched'] = Variable<DateTime>(lastFetched);
    }
    map['subscribed'] = Variable<bool>(subscribed);
    return map;
  }

  PodcastsCompanion toCompanion(bool nullToAbsent) {
    return PodcastsCompanion(
      id: Value(id),
      title: Value(title),
      feedUrl: Value(feedUrl),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      lastFetched: lastFetched == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetched),
      subscribed: Value(subscribed),
    );
  }

  factory Podcast.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Podcast(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      feedUrl: serializer.fromJson<String>(json['feedUrl']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      author: serializer.fromJson<String?>(json['author']),
      description: serializer.fromJson<String?>(json['description']),
      lastFetched: serializer.fromJson<DateTime?>(json['lastFetched']),
      subscribed: serializer.fromJson<bool>(json['subscribed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'feedUrl': serializer.toJson<String>(feedUrl),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'author': serializer.toJson<String?>(author),
      'description': serializer.toJson<String?>(description),
      'lastFetched': serializer.toJson<DateTime?>(lastFetched),
      'subscribed': serializer.toJson<bool>(subscribed),
    };
  }

  Podcast copyWith({
    int? id,
    String? title,
    String? feedUrl,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> author = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<DateTime?> lastFetched = const Value.absent(),
    bool? subscribed,
  }) => Podcast(
    id: id ?? this.id,
    title: title ?? this.title,
    feedUrl: feedUrl ?? this.feedUrl,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    author: author.present ? author.value : this.author,
    description: description.present ? description.value : this.description,
    lastFetched: lastFetched.present ? lastFetched.value : this.lastFetched,
    subscribed: subscribed ?? this.subscribed,
  );
  Podcast copyWithCompanion(PodcastsCompanion data) {
    return Podcast(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      feedUrl: data.feedUrl.present ? data.feedUrl.value : this.feedUrl,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      author: data.author.present ? data.author.value : this.author,
      description: data.description.present
          ? data.description.value
          : this.description,
      lastFetched: data.lastFetched.present
          ? data.lastFetched.value
          : this.lastFetched,
      subscribed: data.subscribed.present
          ? data.subscribed.value
          : this.subscribed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Podcast(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('author: $author, ')
          ..write('description: $description, ')
          ..write('lastFetched: $lastFetched, ')
          ..write('subscribed: $subscribed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    feedUrl,
    imageUrl,
    author,
    description,
    lastFetched,
    subscribed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Podcast &&
          other.id == this.id &&
          other.title == this.title &&
          other.feedUrl == this.feedUrl &&
          other.imageUrl == this.imageUrl &&
          other.author == this.author &&
          other.description == this.description &&
          other.lastFetched == this.lastFetched &&
          other.subscribed == this.subscribed);
}

class PodcastsCompanion extends UpdateCompanion<Podcast> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> feedUrl;
  final Value<String?> imageUrl;
  final Value<String?> author;
  final Value<String?> description;
  final Value<DateTime?> lastFetched;
  final Value<bool> subscribed;
  const PodcastsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.feedUrl = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.author = const Value.absent(),
    this.description = const Value.absent(),
    this.lastFetched = const Value.absent(),
    this.subscribed = const Value.absent(),
  });
  PodcastsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String feedUrl,
    this.imageUrl = const Value.absent(),
    this.author = const Value.absent(),
    this.description = const Value.absent(),
    this.lastFetched = const Value.absent(),
    this.subscribed = const Value.absent(),
  }) : title = Value(title),
       feedUrl = Value(feedUrl);
  static Insertable<Podcast> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? feedUrl,
    Expression<String>? imageUrl,
    Expression<String>? author,
    Expression<String>? description,
    Expression<DateTime>? lastFetched,
    Expression<bool>? subscribed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (feedUrl != null) 'feed_url': feedUrl,
      if (imageUrl != null) 'image_url': imageUrl,
      if (author != null) 'author': author,
      if (description != null) 'description': description,
      if (lastFetched != null) 'last_fetched': lastFetched,
      if (subscribed != null) 'subscribed': subscribed,
    });
  }

  PodcastsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? feedUrl,
    Value<String?>? imageUrl,
    Value<String?>? author,
    Value<String?>? description,
    Value<DateTime?>? lastFetched,
    Value<bool>? subscribed,
  }) {
    return PodcastsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      feedUrl: feedUrl ?? this.feedUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      description: description ?? this.description,
      lastFetched: lastFetched ?? this.lastFetched,
      subscribed: subscribed ?? this.subscribed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (feedUrl.present) {
      map['feed_url'] = Variable<String>(feedUrl.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (lastFetched.present) {
      map['last_fetched'] = Variable<DateTime>(lastFetched.value);
    }
    if (subscribed.present) {
      map['subscribed'] = Variable<bool>(subscribed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PodcastsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('author: $author, ')
          ..write('description: $description, ')
          ..write('lastFetched: $lastFetched, ')
          ..write('subscribed: $subscribed')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes with TableInfo<$EpisodesTable, Episode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _podcastIdMeta = const VerificationMeta(
    'podcastId',
  );
  @override
  late final GeneratedColumn<int> podcastId = GeneratedColumn<int>(
    'podcast_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES podcasts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
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
  static const VerificationMeta _showNotesMeta = const VerificationMeta(
    'showNotes',
  );
  @override
  late final GeneratedColumn<String> showNotes = GeneratedColumn<String>(
    'show_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pubDateMeta = const VerificationMeta(
    'pubDate',
  );
  @override
  late final GeneratedColumn<DateTime> pubDate = GeneratedColumn<DateTime>(
    'pub_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DownloadState, int>
  downloadState = GeneratedColumn<int>(
    'download_state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  ).withConverter<DownloadState>($EpisodesTable.$converterdownloadState);
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isPlayedMeta = const VerificationMeta(
    'isPlayed',
  );
  @override
  late final GeneratedColumn<bool> isPlayed = GeneratedColumn<bool>(
    'is_played',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_played" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    podcastId,
    guid,
    title,
    showNotes,
    audioUrl,
    imageUrl,
    durationMs,
    sizeBytes,
    pubDate,
    localPath,
    downloadState,
    positionMs,
    isPlayed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Episode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('podcast_id')) {
      context.handle(
        _podcastIdMeta,
        podcastId.isAcceptableOrUnknown(data['podcast_id']!, _podcastIdMeta),
      );
    } else if (isInserting) {
      context.missing(_podcastIdMeta);
    }
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    } else if (isInserting) {
      context.missing(_guidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('show_notes')) {
      context.handle(
        _showNotesMeta,
        showNotes.isAcceptableOrUnknown(data['show_notes']!, _showNotesMeta),
      );
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_audioUrlMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('pub_date')) {
      context.handle(
        _pubDateMeta,
        pubDate.isAcceptableOrUnknown(data['pub_date']!, _pubDateMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('is_played')) {
      context.handle(
        _isPlayedMeta,
        isPlayed.isAcceptableOrUnknown(data['is_played']!, _isPlayedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {podcastId, guid},
  ];
  @override
  Episode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Episode(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      podcastId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}podcast_id'],
      )!,
      guid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guid'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      showNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}show_notes'],
      ),
      audioUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_url'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      pubDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pub_date'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      downloadState: $EpisodesTable.$converterdownloadState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}download_state'],
        )!,
      ),
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      isPlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_played'],
      )!,
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DownloadState, int, int> $converterdownloadState =
      const EnumIndexConverter<DownloadState>(DownloadState.values);
}

class Episode extends DataClass implements Insertable<Episode> {
  final int id;
  final int podcastId;
  final String guid;
  final String title;
  final String? showNotes;
  final String audioUrl;
  final String? imageUrl;
  final int? durationMs;
  final int? sizeBytes;
  final DateTime? pubDate;
  final String? localPath;
  final DownloadState downloadState;
  final int positionMs;
  final bool isPlayed;
  const Episode({
    required this.id,
    required this.podcastId,
    required this.guid,
    required this.title,
    this.showNotes,
    required this.audioUrl,
    this.imageUrl,
    this.durationMs,
    this.sizeBytes,
    this.pubDate,
    this.localPath,
    required this.downloadState,
    required this.positionMs,
    required this.isPlayed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['podcast_id'] = Variable<int>(podcastId);
    map['guid'] = Variable<String>(guid);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || showNotes != null) {
      map['show_notes'] = Variable<String>(showNotes);
    }
    map['audio_url'] = Variable<String>(audioUrl);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || pubDate != null) {
      map['pub_date'] = Variable<DateTime>(pubDate);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    {
      map['download_state'] = Variable<int>(
        $EpisodesTable.$converterdownloadState.toSql(downloadState),
      );
    }
    map['position_ms'] = Variable<int>(positionMs);
    map['is_played'] = Variable<bool>(isPlayed);
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      podcastId: Value(podcastId),
      guid: Value(guid),
      title: Value(title),
      showNotes: showNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(showNotes),
      audioUrl: Value(audioUrl),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      pubDate: pubDate == null && nullToAbsent
          ? const Value.absent()
          : Value(pubDate),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      downloadState: Value(downloadState),
      positionMs: Value(positionMs),
      isPlayed: Value(isPlayed),
    );
  }

  factory Episode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Episode(
      id: serializer.fromJson<int>(json['id']),
      podcastId: serializer.fromJson<int>(json['podcastId']),
      guid: serializer.fromJson<String>(json['guid']),
      title: serializer.fromJson<String>(json['title']),
      showNotes: serializer.fromJson<String?>(json['showNotes']),
      audioUrl: serializer.fromJson<String>(json['audioUrl']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      pubDate: serializer.fromJson<DateTime?>(json['pubDate']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      downloadState: $EpisodesTable.$converterdownloadState.fromJson(
        serializer.fromJson<int>(json['downloadState']),
      ),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      isPlayed: serializer.fromJson<bool>(json['isPlayed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'podcastId': serializer.toJson<int>(podcastId),
      'guid': serializer.toJson<String>(guid),
      'title': serializer.toJson<String>(title),
      'showNotes': serializer.toJson<String?>(showNotes),
      'audioUrl': serializer.toJson<String>(audioUrl),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'durationMs': serializer.toJson<int?>(durationMs),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'pubDate': serializer.toJson<DateTime?>(pubDate),
      'localPath': serializer.toJson<String?>(localPath),
      'downloadState': serializer.toJson<int>(
        $EpisodesTable.$converterdownloadState.toJson(downloadState),
      ),
      'positionMs': serializer.toJson<int>(positionMs),
      'isPlayed': serializer.toJson<bool>(isPlayed),
    };
  }

  Episode copyWith({
    int? id,
    int? podcastId,
    String? guid,
    String? title,
    Value<String?> showNotes = const Value.absent(),
    String? audioUrl,
    Value<String?> imageUrl = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    Value<DateTime?> pubDate = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    DownloadState? downloadState,
    int? positionMs,
    bool? isPlayed,
  }) => Episode(
    id: id ?? this.id,
    podcastId: podcastId ?? this.podcastId,
    guid: guid ?? this.guid,
    title: title ?? this.title,
    showNotes: showNotes.present ? showNotes.value : this.showNotes,
    audioUrl: audioUrl ?? this.audioUrl,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    pubDate: pubDate.present ? pubDate.value : this.pubDate,
    localPath: localPath.present ? localPath.value : this.localPath,
    downloadState: downloadState ?? this.downloadState,
    positionMs: positionMs ?? this.positionMs,
    isPlayed: isPlayed ?? this.isPlayed,
  );
  Episode copyWithCompanion(EpisodesCompanion data) {
    return Episode(
      id: data.id.present ? data.id.value : this.id,
      podcastId: data.podcastId.present ? data.podcastId.value : this.podcastId,
      guid: data.guid.present ? data.guid.value : this.guid,
      title: data.title.present ? data.title.value : this.title,
      showNotes: data.showNotes.present ? data.showNotes.value : this.showNotes,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      pubDate: data.pubDate.present ? data.pubDate.value : this.pubDate,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      downloadState: data.downloadState.present
          ? data.downloadState.value
          : this.downloadState,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      isPlayed: data.isPlayed.present ? data.isPlayed.value : this.isPlayed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Episode(')
          ..write('id: $id, ')
          ..write('podcastId: $podcastId, ')
          ..write('guid: $guid, ')
          ..write('title: $title, ')
          ..write('showNotes: $showNotes, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('pubDate: $pubDate, ')
          ..write('localPath: $localPath, ')
          ..write('downloadState: $downloadState, ')
          ..write('positionMs: $positionMs, ')
          ..write('isPlayed: $isPlayed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    podcastId,
    guid,
    title,
    showNotes,
    audioUrl,
    imageUrl,
    durationMs,
    sizeBytes,
    pubDate,
    localPath,
    downloadState,
    positionMs,
    isPlayed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Episode &&
          other.id == this.id &&
          other.podcastId == this.podcastId &&
          other.guid == this.guid &&
          other.title == this.title &&
          other.showNotes == this.showNotes &&
          other.audioUrl == this.audioUrl &&
          other.imageUrl == this.imageUrl &&
          other.durationMs == this.durationMs &&
          other.sizeBytes == this.sizeBytes &&
          other.pubDate == this.pubDate &&
          other.localPath == this.localPath &&
          other.downloadState == this.downloadState &&
          other.positionMs == this.positionMs &&
          other.isPlayed == this.isPlayed);
}

class EpisodesCompanion extends UpdateCompanion<Episode> {
  final Value<int> id;
  final Value<int> podcastId;
  final Value<String> guid;
  final Value<String> title;
  final Value<String?> showNotes;
  final Value<String> audioUrl;
  final Value<String?> imageUrl;
  final Value<int?> durationMs;
  final Value<int?> sizeBytes;
  final Value<DateTime?> pubDate;
  final Value<String?> localPath;
  final Value<DownloadState> downloadState;
  final Value<int> positionMs;
  final Value<bool> isPlayed;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.podcastId = const Value.absent(),
    this.guid = const Value.absent(),
    this.title = const Value.absent(),
    this.showNotes = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.localPath = const Value.absent(),
    this.downloadState = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.isPlayed = const Value.absent(),
  });
  EpisodesCompanion.insert({
    this.id = const Value.absent(),
    required int podcastId,
    required String guid,
    required String title,
    this.showNotes = const Value.absent(),
    required String audioUrl,
    this.imageUrl = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.localPath = const Value.absent(),
    this.downloadState = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.isPlayed = const Value.absent(),
  }) : podcastId = Value(podcastId),
       guid = Value(guid),
       title = Value(title),
       audioUrl = Value(audioUrl);
  static Insertable<Episode> custom({
    Expression<int>? id,
    Expression<int>? podcastId,
    Expression<String>? guid,
    Expression<String>? title,
    Expression<String>? showNotes,
    Expression<String>? audioUrl,
    Expression<String>? imageUrl,
    Expression<int>? durationMs,
    Expression<int>? sizeBytes,
    Expression<DateTime>? pubDate,
    Expression<String>? localPath,
    Expression<int>? downloadState,
    Expression<int>? positionMs,
    Expression<bool>? isPlayed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (podcastId != null) 'podcast_id': podcastId,
      if (guid != null) 'guid': guid,
      if (title != null) 'title': title,
      if (showNotes != null) 'show_notes': showNotes,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (imageUrl != null) 'image_url': imageUrl,
      if (durationMs != null) 'duration_ms': durationMs,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (pubDate != null) 'pub_date': pubDate,
      if (localPath != null) 'local_path': localPath,
      if (downloadState != null) 'download_state': downloadState,
      if (positionMs != null) 'position_ms': positionMs,
      if (isPlayed != null) 'is_played': isPlayed,
    });
  }

  EpisodesCompanion copyWith({
    Value<int>? id,
    Value<int>? podcastId,
    Value<String>? guid,
    Value<String>? title,
    Value<String?>? showNotes,
    Value<String>? audioUrl,
    Value<String?>? imageUrl,
    Value<int?>? durationMs,
    Value<int?>? sizeBytes,
    Value<DateTime?>? pubDate,
    Value<String?>? localPath,
    Value<DownloadState>? downloadState,
    Value<int>? positionMs,
    Value<bool>? isPlayed,
  }) {
    return EpisodesCompanion(
      id: id ?? this.id,
      podcastId: podcastId ?? this.podcastId,
      guid: guid ?? this.guid,
      title: title ?? this.title,
      showNotes: showNotes ?? this.showNotes,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      pubDate: pubDate ?? this.pubDate,
      localPath: localPath ?? this.localPath,
      downloadState: downloadState ?? this.downloadState,
      positionMs: positionMs ?? this.positionMs,
      isPlayed: isPlayed ?? this.isPlayed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (podcastId.present) {
      map['podcast_id'] = Variable<int>(podcastId.value);
    }
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (showNotes.present) {
      map['show_notes'] = Variable<String>(showNotes.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (pubDate.present) {
      map['pub_date'] = Variable<DateTime>(pubDate.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (downloadState.present) {
      map['download_state'] = Variable<int>(
        $EpisodesTable.$converterdownloadState.toSql(downloadState.value),
      );
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (isPlayed.present) {
      map['is_played'] = Variable<bool>(isPlayed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('podcastId: $podcastId, ')
          ..write('guid: $guid, ')
          ..write('title: $title, ')
          ..write('showNotes: $showNotes, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('pubDate: $pubDate, ')
          ..write('localPath: $localPath, ')
          ..write('downloadState: $downloadState, ')
          ..write('positionMs: $positionMs, ')
          ..write('isPlayed: $isPlayed')
          ..write(')'))
        .toString();
  }
}

class $TranscriptsTable extends Transcripts
    with TableInfo<$TranscriptsTable, Transcript> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranscriptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _episodeIdMeta = const VerificationMeta(
    'episodeId',
  );
  @override
  late final GeneratedColumn<int> episodeId = GeneratedColumn<int>(
    'episode_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES episodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
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
  @override
  List<GeneratedColumn> get $columns => [
    episodeId,
    content,
    language,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transcripts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transcript> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {episodeId};
  @override
  Transcript map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transcript(
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TranscriptsTable createAlias(String alias) {
    return $TranscriptsTable(attachedDatabase, alias);
  }
}

class Transcript extends DataClass implements Insertable<Transcript> {
  final int episodeId;
  final String content;
  final String? language;
  final DateTime createdAt;
  const Transcript({
    required this.episodeId,
    required this.content,
    this.language,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['episode_id'] = Variable<int>(episodeId);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TranscriptsCompanion toCompanion(bool nullToAbsent) {
    return TranscriptsCompanion(
      episodeId: Value(episodeId),
      content: Value(content),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      createdAt: Value(createdAt),
    );
  }

  factory Transcript.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transcript(
      episodeId: serializer.fromJson<int>(json['episodeId']),
      content: serializer.fromJson<String>(json['content']),
      language: serializer.fromJson<String?>(json['language']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'episodeId': serializer.toJson<int>(episodeId),
      'content': serializer.toJson<String>(content),
      'language': serializer.toJson<String?>(language),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Transcript copyWith({
    int? episodeId,
    String? content,
    Value<String?> language = const Value.absent(),
    DateTime? createdAt,
  }) => Transcript(
    episodeId: episodeId ?? this.episodeId,
    content: content ?? this.content,
    language: language.present ? language.value : this.language,
    createdAt: createdAt ?? this.createdAt,
  );
  Transcript copyWithCompanion(TranscriptsCompanion data) {
    return Transcript(
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      content: data.content.present ? data.content.value : this.content,
      language: data.language.present ? data.language.value : this.language,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transcript(')
          ..write('episodeId: $episodeId, ')
          ..write('content: $content, ')
          ..write('language: $language, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(episodeId, content, language, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transcript &&
          other.episodeId == this.episodeId &&
          other.content == this.content &&
          other.language == this.language &&
          other.createdAt == this.createdAt);
}

class TranscriptsCompanion extends UpdateCompanion<Transcript> {
  final Value<int> episodeId;
  final Value<String> content;
  final Value<String?> language;
  final Value<DateTime> createdAt;
  const TranscriptsCompanion({
    this.episodeId = const Value.absent(),
    this.content = const Value.absent(),
    this.language = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TranscriptsCompanion.insert({
    this.episodeId = const Value.absent(),
    required String content,
    this.language = const Value.absent(),
    required DateTime createdAt,
  }) : content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<Transcript> custom({
    Expression<int>? episodeId,
    Expression<String>? content,
    Expression<String>? language,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (episodeId != null) 'episode_id': episodeId,
      if (content != null) 'content': content,
      if (language != null) 'language': language,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TranscriptsCompanion copyWith({
    Value<int>? episodeId,
    Value<String>? content,
    Value<String?>? language,
    Value<DateTime>? createdAt,
  }) {
    return TranscriptsCompanion(
      episodeId: episodeId ?? this.episodeId,
      content: content ?? this.content,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (episodeId.present) {
      map['episode_id'] = Variable<int>(episodeId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptsCompanion(')
          ..write('episodeId: $episodeId, ')
          ..write('content: $content, ')
          ..write('language: $language, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $QueueItemsTable extends QueueItems
    with TableInfo<$QueueItemsTable, QueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _episodeIdMeta = const VerificationMeta(
    'episodeId',
  );
  @override
  late final GeneratedColumn<int> episodeId = GeneratedColumn<int>(
    'episode_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES episodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [episodeId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {episodeId};
  @override
  QueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueItem(
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $QueueItemsTable createAlias(String alias) {
    return $QueueItemsTable(attachedDatabase, alias);
  }
}

class QueueItem extends DataClass implements Insertable<QueueItem> {
  final int episodeId;
  final int position;
  const QueueItem({required this.episodeId, required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['episode_id'] = Variable<int>(episodeId);
    map['position'] = Variable<int>(position);
    return map;
  }

  QueueItemsCompanion toCompanion(bool nullToAbsent) {
    return QueueItemsCompanion(
      episodeId: Value(episodeId),
      position: Value(position),
    );
  }

  factory QueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueItem(
      episodeId: serializer.fromJson<int>(json['episodeId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'episodeId': serializer.toJson<int>(episodeId),
      'position': serializer.toJson<int>(position),
    };
  }

  QueueItem copyWith({int? episodeId, int? position}) => QueueItem(
    episodeId: episodeId ?? this.episodeId,
    position: position ?? this.position,
  );
  QueueItem copyWithCompanion(QueueItemsCompanion data) {
    return QueueItem(
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueItem(')
          ..write('episodeId: $episodeId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(episodeId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueItem &&
          other.episodeId == this.episodeId &&
          other.position == this.position);
}

class QueueItemsCompanion extends UpdateCompanion<QueueItem> {
  final Value<int> episodeId;
  final Value<int> position;
  const QueueItemsCompanion({
    this.episodeId = const Value.absent(),
    this.position = const Value.absent(),
  });
  QueueItemsCompanion.insert({
    this.episodeId = const Value.absent(),
    required int position,
  }) : position = Value(position);
  static Insertable<QueueItem> custom({
    Expression<int>? episodeId,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (episodeId != null) 'episode_id': episodeId,
      if (position != null) 'position': position,
    });
  }

  QueueItemsCompanion copyWith({Value<int>? episodeId, Value<int>? position}) {
    return QueueItemsCompanion(
      episodeId: episodeId ?? this.episodeId,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (episodeId.present) {
      map['episode_id'] = Variable<int>(episodeId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueItemsCompanion(')
          ..write('episodeId: $episodeId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PodcastsTable podcasts = $PodcastsTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $TranscriptsTable transcripts = $TranscriptsTable(this);
  late final $QueueItemsTable queueItems = $QueueItemsTable(this);
  late final Index idxEpisodesPodcast = Index(
    'idx_episodes_podcast',
    'CREATE INDEX idx_episodes_podcast ON episodes (podcast_id)',
  );
  late final Index idxEpisodesGuid = Index(
    'idx_episodes_guid',
    'CREATE INDEX idx_episodes_guid ON episodes (guid)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    podcasts,
    episodes,
    transcripts,
    queueItems,
    idxEpisodesPodcast,
    idxEpisodesGuid,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'podcasts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('episodes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'episodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transcripts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'episodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('queue_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PodcastsTableCreateCompanionBuilder =
    PodcastsCompanion Function({
      Value<int> id,
      required String title,
      required String feedUrl,
      Value<String?> imageUrl,
      Value<String?> author,
      Value<String?> description,
      Value<DateTime?> lastFetched,
      Value<bool> subscribed,
    });
typedef $$PodcastsTableUpdateCompanionBuilder =
    PodcastsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> feedUrl,
      Value<String?> imageUrl,
      Value<String?> author,
      Value<String?> description,
      Value<DateTime?> lastFetched,
      Value<bool> subscribed,
    });

final class $$PodcastsTableReferences
    extends BaseReferences<_$AppDatabase, $PodcastsTable, Podcast> {
  $$PodcastsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EpisodesTable, List<Episode>> _episodesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.episodes,
    aliasName: $_aliasNameGenerator(db.podcasts.id, db.episodes.podcastId),
  );

  $$EpisodesTableProcessedTableManager get episodesRefs {
    final manager = $$EpisodesTableTableManager(
      $_db,
      $_db.episodes,
    ).filter((f) => f.podcastId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_episodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PodcastsTableFilterComposer
    extends Composer<_$AppDatabase, $PodcastsTable> {
  $$PodcastsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetched => $composableBuilder(
    column: $table.lastFetched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get subscribed => $composableBuilder(
    column: $table.subscribed,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> episodesRefs(
    Expression<bool> Function($$EpisodesTableFilterComposer f) f,
  ) {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.podcastId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableFilterComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PodcastsTableOrderingComposer
    extends Composer<_$AppDatabase, $PodcastsTable> {
  $$PodcastsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetched => $composableBuilder(
    column: $table.lastFetched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get subscribed => $composableBuilder(
    column: $table.subscribed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PodcastsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PodcastsTable> {
  $$PodcastsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get feedUrl =>
      $composableBuilder(column: $table.feedUrl, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastFetched => $composableBuilder(
    column: $table.lastFetched,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get subscribed => $composableBuilder(
    column: $table.subscribed,
    builder: (column) => column,
  );

  Expression<T> episodesRefs<T extends Object>(
    Expression<T> Function($$EpisodesTableAnnotationComposer a) f,
  ) {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.podcastId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableAnnotationComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PodcastsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PodcastsTable,
          Podcast,
          $$PodcastsTableFilterComposer,
          $$PodcastsTableOrderingComposer,
          $$PodcastsTableAnnotationComposer,
          $$PodcastsTableCreateCompanionBuilder,
          $$PodcastsTableUpdateCompanionBuilder,
          (Podcast, $$PodcastsTableReferences),
          Podcast,
          PrefetchHooks Function({bool episodesRefs})
        > {
  $$PodcastsTableTableManager(_$AppDatabase db, $PodcastsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PodcastsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PodcastsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PodcastsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> feedUrl = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime?> lastFetched = const Value.absent(),
                Value<bool> subscribed = const Value.absent(),
              }) => PodcastsCompanion(
                id: id,
                title: title,
                feedUrl: feedUrl,
                imageUrl: imageUrl,
                author: author,
                description: description,
                lastFetched: lastFetched,
                subscribed: subscribed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String feedUrl,
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime?> lastFetched = const Value.absent(),
                Value<bool> subscribed = const Value.absent(),
              }) => PodcastsCompanion.insert(
                id: id,
                title: title,
                feedUrl: feedUrl,
                imageUrl: imageUrl,
                author: author,
                description: description,
                lastFetched: lastFetched,
                subscribed: subscribed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PodcastsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({episodesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (episodesRefs) db.episodes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (episodesRefs)
                    await $_getPrefetchedData<Podcast, $PodcastsTable, Episode>(
                      currentTable: table,
                      referencedTable: $$PodcastsTableReferences
                          ._episodesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PodcastsTableReferences(db, table, p0).episodesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.podcastId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PodcastsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PodcastsTable,
      Podcast,
      $$PodcastsTableFilterComposer,
      $$PodcastsTableOrderingComposer,
      $$PodcastsTableAnnotationComposer,
      $$PodcastsTableCreateCompanionBuilder,
      $$PodcastsTableUpdateCompanionBuilder,
      (Podcast, $$PodcastsTableReferences),
      Podcast,
      PrefetchHooks Function({bool episodesRefs})
    >;
typedef $$EpisodesTableCreateCompanionBuilder =
    EpisodesCompanion Function({
      Value<int> id,
      required int podcastId,
      required String guid,
      required String title,
      Value<String?> showNotes,
      required String audioUrl,
      Value<String?> imageUrl,
      Value<int?> durationMs,
      Value<int?> sizeBytes,
      Value<DateTime?> pubDate,
      Value<String?> localPath,
      Value<DownloadState> downloadState,
      Value<int> positionMs,
      Value<bool> isPlayed,
    });
typedef $$EpisodesTableUpdateCompanionBuilder =
    EpisodesCompanion Function({
      Value<int> id,
      Value<int> podcastId,
      Value<String> guid,
      Value<String> title,
      Value<String?> showNotes,
      Value<String> audioUrl,
      Value<String?> imageUrl,
      Value<int?> durationMs,
      Value<int?> sizeBytes,
      Value<DateTime?> pubDate,
      Value<String?> localPath,
      Value<DownloadState> downloadState,
      Value<int> positionMs,
      Value<bool> isPlayed,
    });

final class $$EpisodesTableReferences
    extends BaseReferences<_$AppDatabase, $EpisodesTable, Episode> {
  $$EpisodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PodcastsTable _podcastIdTable(_$AppDatabase db) => db.podcasts
      .createAlias($_aliasNameGenerator(db.episodes.podcastId, db.podcasts.id));

  $$PodcastsTableProcessedTableManager get podcastId {
    final $_column = $_itemColumn<int>('podcast_id')!;

    final manager = $$PodcastsTableTableManager(
      $_db,
      $_db.podcasts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_podcastIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TranscriptsTable, List<Transcript>>
  _transcriptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transcripts,
    aliasName: $_aliasNameGenerator(db.episodes.id, db.transcripts.episodeId),
  );

  $$TranscriptsTableProcessedTableManager get transcriptsRefs {
    final manager = $$TranscriptsTableTableManager(
      $_db,
      $_db.transcripts,
    ).filter((f) => f.episodeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transcriptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$QueueItemsTable, List<QueueItem>>
  _queueItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.queueItems,
    aliasName: $_aliasNameGenerator(db.episodes.id, db.queueItems.episodeId),
  );

  $$QueueItemsTableProcessedTableManager get queueItemsRefs {
    final manager = $$QueueItemsTableTableManager(
      $_db,
      $_db.queueItems,
    ).filter((f) => f.episodeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_queueItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
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

  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get showNotes => $composableBuilder(
    column: $table.showNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pubDate => $composableBuilder(
    column: $table.pubDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DownloadState, DownloadState, int>
  get downloadState => $composableBuilder(
    column: $table.downloadState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPlayed => $composableBuilder(
    column: $table.isPlayed,
    builder: (column) => ColumnFilters(column),
  );

  $$PodcastsTableFilterComposer get podcastId {
    final $$PodcastsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.podcastId,
      referencedTable: $db.podcasts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PodcastsTableFilterComposer(
            $db: $db,
            $table: $db.podcasts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transcriptsRefs(
    Expression<bool> Function($$TranscriptsTableFilterComposer f) f,
  ) {
    final $$TranscriptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transcripts,
      getReferencedColumn: (t) => t.episodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranscriptsTableFilterComposer(
            $db: $db,
            $table: $db.transcripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> queueItemsRefs(
    Expression<bool> Function($$QueueItemsTableFilterComposer f) f,
  ) {
    final $$QueueItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.queueItems,
      getReferencedColumn: (t) => t.episodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QueueItemsTableFilterComposer(
            $db: $db,
            $table: $db.queueItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
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

  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get showNotes => $composableBuilder(
    column: $table.showNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pubDate => $composableBuilder(
    column: $table.pubDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadState => $composableBuilder(
    column: $table.downloadState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPlayed => $composableBuilder(
    column: $table.isPlayed,
    builder: (column) => ColumnOrderings(column),
  );

  $$PodcastsTableOrderingComposer get podcastId {
    final $$PodcastsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.podcastId,
      referencedTable: $db.podcasts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PodcastsTableOrderingComposer(
            $db: $db,
            $table: $db.podcasts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get showNotes =>
      $composableBuilder(column: $table.showNotes, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get pubDate =>
      $composableBuilder(column: $table.pubDate, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadState, int> get downloadState =>
      $composableBuilder(
        column: $table.downloadState,
        builder: (column) => column,
      );

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPlayed =>
      $composableBuilder(column: $table.isPlayed, builder: (column) => column);

  $$PodcastsTableAnnotationComposer get podcastId {
    final $$PodcastsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.podcastId,
      referencedTable: $db.podcasts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PodcastsTableAnnotationComposer(
            $db: $db,
            $table: $db.podcasts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transcriptsRefs<T extends Object>(
    Expression<T> Function($$TranscriptsTableAnnotationComposer a) f,
  ) {
    final $$TranscriptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transcripts,
      getReferencedColumn: (t) => t.episodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TranscriptsTableAnnotationComposer(
            $db: $db,
            $table: $db.transcripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> queueItemsRefs<T extends Object>(
    Expression<T> Function($$QueueItemsTableAnnotationComposer a) f,
  ) {
    final $$QueueItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.queueItems,
      getReferencedColumn: (t) => t.episodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QueueItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.queueItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EpisodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodesTable,
          Episode,
          $$EpisodesTableFilterComposer,
          $$EpisodesTableOrderingComposer,
          $$EpisodesTableAnnotationComposer,
          $$EpisodesTableCreateCompanionBuilder,
          $$EpisodesTableUpdateCompanionBuilder,
          (Episode, $$EpisodesTableReferences),
          Episode,
          PrefetchHooks Function({
            bool podcastId,
            bool transcriptsRefs,
            bool queueItemsRefs,
          })
        > {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> podcastId = const Value.absent(),
                Value<String> guid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> showNotes = const Value.absent(),
                Value<String> audioUrl = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<DateTime?> pubDate = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<DownloadState> downloadState = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<bool> isPlayed = const Value.absent(),
              }) => EpisodesCompanion(
                id: id,
                podcastId: podcastId,
                guid: guid,
                title: title,
                showNotes: showNotes,
                audioUrl: audioUrl,
                imageUrl: imageUrl,
                durationMs: durationMs,
                sizeBytes: sizeBytes,
                pubDate: pubDate,
                localPath: localPath,
                downloadState: downloadState,
                positionMs: positionMs,
                isPlayed: isPlayed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int podcastId,
                required String guid,
                required String title,
                Value<String?> showNotes = const Value.absent(),
                required String audioUrl,
                Value<String?> imageUrl = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<DateTime?> pubDate = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<DownloadState> downloadState = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<bool> isPlayed = const Value.absent(),
              }) => EpisodesCompanion.insert(
                id: id,
                podcastId: podcastId,
                guid: guid,
                title: title,
                showNotes: showNotes,
                audioUrl: audioUrl,
                imageUrl: imageUrl,
                durationMs: durationMs,
                sizeBytes: sizeBytes,
                pubDate: pubDate,
                localPath: localPath,
                downloadState: downloadState,
                positionMs: positionMs,
                isPlayed: isPlayed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EpisodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                podcastId = false,
                transcriptsRefs = false,
                queueItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transcriptsRefs) db.transcripts,
                    if (queueItemsRefs) db.queueItems,
                  ],
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
                        if (podcastId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.podcastId,
                                    referencedTable: $$EpisodesTableReferences
                                        ._podcastIdTable(db),
                                    referencedColumn: $$EpisodesTableReferences
                                        ._podcastIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transcriptsRefs)
                        await $_getPrefetchedData<
                          Episode,
                          $EpisodesTable,
                          Transcript
                        >(
                          currentTable: table,
                          referencedTable: $$EpisodesTableReferences
                              ._transcriptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EpisodesTableReferences(
                                db,
                                table,
                                p0,
                              ).transcriptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.episodeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (queueItemsRefs)
                        await $_getPrefetchedData<
                          Episode,
                          $EpisodesTable,
                          QueueItem
                        >(
                          currentTable: table,
                          referencedTable: $$EpisodesTableReferences
                              ._queueItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EpisodesTableReferences(
                                db,
                                table,
                                p0,
                              ).queueItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.episodeId == item.id,
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

typedef $$EpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodesTable,
      Episode,
      $$EpisodesTableFilterComposer,
      $$EpisodesTableOrderingComposer,
      $$EpisodesTableAnnotationComposer,
      $$EpisodesTableCreateCompanionBuilder,
      $$EpisodesTableUpdateCompanionBuilder,
      (Episode, $$EpisodesTableReferences),
      Episode,
      PrefetchHooks Function({
        bool podcastId,
        bool transcriptsRefs,
        bool queueItemsRefs,
      })
    >;
typedef $$TranscriptsTableCreateCompanionBuilder =
    TranscriptsCompanion Function({
      Value<int> episodeId,
      required String content,
      Value<String?> language,
      required DateTime createdAt,
    });
typedef $$TranscriptsTableUpdateCompanionBuilder =
    TranscriptsCompanion Function({
      Value<int> episodeId,
      Value<String> content,
      Value<String?> language,
      Value<DateTime> createdAt,
    });

final class $$TranscriptsTableReferences
    extends BaseReferences<_$AppDatabase, $TranscriptsTable, Transcript> {
  $$TranscriptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EpisodesTable _episodeIdTable(_$AppDatabase db) =>
      db.episodes.createAlias(
        $_aliasNameGenerator(db.transcripts.episodeId, db.episodes.id),
      );

  $$EpisodesTableProcessedTableManager get episodeId {
    final $_column = $_itemColumn<int>('episode_id')!;

    final manager = $$EpisodesTableTableManager(
      $_db,
      $_db.episodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_episodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TranscriptsTableFilterComposer
    extends Composer<_$AppDatabase, $TranscriptsTable> {
  $$TranscriptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EpisodesTableFilterComposer get episodeId {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.episodeId,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableFilterComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TranscriptsTableOrderingComposer
    extends Composer<_$AppDatabase, $TranscriptsTable> {
  $$TranscriptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EpisodesTableOrderingComposer get episodeId {
    final $$EpisodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.episodeId,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableOrderingComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TranscriptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranscriptsTable> {
  $$TranscriptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EpisodesTableAnnotationComposer get episodeId {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.episodeId,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableAnnotationComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TranscriptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranscriptsTable,
          Transcript,
          $$TranscriptsTableFilterComposer,
          $$TranscriptsTableOrderingComposer,
          $$TranscriptsTableAnnotationComposer,
          $$TranscriptsTableCreateCompanionBuilder,
          $$TranscriptsTableUpdateCompanionBuilder,
          (Transcript, $$TranscriptsTableReferences),
          Transcript,
          PrefetchHooks Function({bool episodeId})
        > {
  $$TranscriptsTableTableManager(_$AppDatabase db, $TranscriptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranscriptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranscriptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranscriptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> episodeId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TranscriptsCompanion(
                episodeId: episodeId,
                content: content,
                language: language,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> episodeId = const Value.absent(),
                required String content,
                Value<String?> language = const Value.absent(),
                required DateTime createdAt,
              }) => TranscriptsCompanion.insert(
                episodeId: episodeId,
                content: content,
                language: language,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TranscriptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({episodeId = false}) {
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
                    if (episodeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.episodeId,
                                referencedTable: $$TranscriptsTableReferences
                                    ._episodeIdTable(db),
                                referencedColumn: $$TranscriptsTableReferences
                                    ._episodeIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$TranscriptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranscriptsTable,
      Transcript,
      $$TranscriptsTableFilterComposer,
      $$TranscriptsTableOrderingComposer,
      $$TranscriptsTableAnnotationComposer,
      $$TranscriptsTableCreateCompanionBuilder,
      $$TranscriptsTableUpdateCompanionBuilder,
      (Transcript, $$TranscriptsTableReferences),
      Transcript,
      PrefetchHooks Function({bool episodeId})
    >;
typedef $$QueueItemsTableCreateCompanionBuilder =
    QueueItemsCompanion Function({Value<int> episodeId, required int position});
typedef $$QueueItemsTableUpdateCompanionBuilder =
    QueueItemsCompanion Function({Value<int> episodeId, Value<int> position});

final class $$QueueItemsTableReferences
    extends BaseReferences<_$AppDatabase, $QueueItemsTable, QueueItem> {
  $$QueueItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EpisodesTable _episodeIdTable(_$AppDatabase db) =>
      db.episodes.createAlias(
        $_aliasNameGenerator(db.queueItems.episodeId, db.episodes.id),
      );

  $$EpisodesTableProcessedTableManager get episodeId {
    final $_column = $_itemColumn<int>('episode_id')!;

    final manager = $$EpisodesTableTableManager(
      $_db,
      $_db.episodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_episodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QueueItemsTableFilterComposer
    extends Composer<_$AppDatabase, $QueueItemsTable> {
  $$QueueItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$EpisodesTableFilterComposer get episodeId {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.episodeId,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableFilterComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueueItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $QueueItemsTable> {
  $$QueueItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$EpisodesTableOrderingComposer get episodeId {
    final $$EpisodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.episodeId,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableOrderingComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueueItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueueItemsTable> {
  $$QueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$EpisodesTableAnnotationComposer get episodeId {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.episodeId,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableAnnotationComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueueItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueueItemsTable,
          QueueItem,
          $$QueueItemsTableFilterComposer,
          $$QueueItemsTableOrderingComposer,
          $$QueueItemsTableAnnotationComposer,
          $$QueueItemsTableCreateCompanionBuilder,
          $$QueueItemsTableUpdateCompanionBuilder,
          (QueueItem, $$QueueItemsTableReferences),
          QueueItem,
          PrefetchHooks Function({bool episodeId})
        > {
  $$QueueItemsTableTableManager(_$AppDatabase db, $QueueItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> episodeId = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) =>
                  QueueItemsCompanion(episodeId: episodeId, position: position),
          createCompanionCallback:
              ({
                Value<int> episodeId = const Value.absent(),
                required int position,
              }) => QueueItemsCompanion.insert(
                episodeId: episodeId,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QueueItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({episodeId = false}) {
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
                    if (episodeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.episodeId,
                                referencedTable: $$QueueItemsTableReferences
                                    ._episodeIdTable(db),
                                referencedColumn: $$QueueItemsTableReferences
                                    ._episodeIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$QueueItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueueItemsTable,
      QueueItem,
      $$QueueItemsTableFilterComposer,
      $$QueueItemsTableOrderingComposer,
      $$QueueItemsTableAnnotationComposer,
      $$QueueItemsTableCreateCompanionBuilder,
      $$QueueItemsTableUpdateCompanionBuilder,
      (QueueItem, $$QueueItemsTableReferences),
      QueueItem,
      PrefetchHooks Function({bool episodeId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PodcastsTableTableManager get podcasts =>
      $$PodcastsTableTableManager(_db, _db.podcasts);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
  $$TranscriptsTableTableManager get transcripts =>
      $$TranscriptsTableTableManager(_db, _db.transcripts);
  $$QueueItemsTableTableManager get queueItems =>
      $$QueueItemsTableTableManager(_db, _db.queueItems);
}
