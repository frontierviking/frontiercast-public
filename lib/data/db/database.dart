import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models.dart';

part 'database.g.dart';

class Podcasts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get feedUrl => text().unique()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get author => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get link => text().nullable()();
  DateTimeColumn get lastFetched => dateTime().nullable()();
  BoolColumn get subscribed => boolean().withDefault(const Constant(true))();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();
}

@TableIndex(name: 'idx_episodes_podcast', columns: {#podcastId})
@TableIndex(name: 'idx_episodes_guid', columns: {#guid})
class Episodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get podcastId =>
      integer().references(Podcasts, #id, onDelete: KeyAction.cascade)();
  TextColumn get guid => text()();
  TextColumn get title => text()();
  TextColumn get showNotes => text().nullable()();
  TextColumn get audioUrl => text()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get link => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  DateTimeColumn get pubDate => dateTime().nullable()();
  TextColumn get localPath => text().nullable()();
  IntColumn get downloadState =>
      intEnum<DownloadState>().withDefault(const Constant(0))();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  BoolColumn get isPlayed => boolean().withDefault(const Constant(false))();

  /// Set when a playback attempt fails to load the source (e.g. HTTP 404), so
  /// the episode list can grey it out. Cleared on a successful play or when a
  /// feed refresh re-confirms the episode.
  BoolColumn get unavailable => boolean().withDefault(const Constant(false))();

  // A feed item is unique by its guid within a single podcast.
  @override
  List<Set<Column>> get uniqueKeys => [
    {podcastId, guid},
  ];
}

class Transcripts extends Table {
  IntColumn get episodeId =>
      integer().references(Episodes, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text()();
  TextColumn get language => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {episodeId};
}

class QueueItems extends Table {
  IntColumn get episodeId =>
      integer().references(Episodes, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {episodeId};
}

@DriftAccessor(tables: [Podcasts])
class PodcastDao extends DatabaseAccessor<AppDatabase> with _$PodcastDaoMixin {
  PodcastDao(super.db);

  Stream<List<Podcast>> watchAll() =>
      (select(podcasts)
            ..where((t) => t.subscribed.equals(true))
            ..orderBy([(t) => OrderingTerm(expression: t.title)]))
          .watch();

  Future<List<Podcast>> getAll() =>
      (select(podcasts)..where((t) => t.subscribed.equals(true))).get();

  Future<void> setSubscribed(int id, bool subscribed) =>
      (update(podcasts)..where((t) => t.id.equals(id))).write(
        PodcastsCompanion(subscribed: Value(subscribed)),
      );

  Future<void> setSortIndex(int id, int index) =>
      (update(podcasts)..where((t) => t.id.equals(id)))
          .write(PodcastsCompanion(sortIndex: Value(index)));

  Future<void> setSortOrder(List<int> idsInOrder) async {
    await batch((b) {
      for (var i = 0; i < idsInOrder.length; i++) {
        b.update(
          podcasts,
          PodcastsCompanion(sortIndex: Value(i)),
          where: (t) => t.id.equals(idsInOrder[i]),
        );
      }
    });
  }

  Future<Podcast?> getByFeedUrl(String feedUrl) => (select(
    podcasts,
  )..where((t) => t.feedUrl.equals(feedUrl))).getSingleOrNull();

  Future<Podcast?> getById(int id) =>
      (select(podcasts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Podcast?> watchById(int id) =>
      (select(podcasts)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> insertPodcast(PodcastsCompanion entry) =>
      into(podcasts).insert(entry);

  Future<void> updatePodcast(int id, PodcastsCompanion entry) =>
      (update(podcasts)..where((t) => t.id.equals(id))).write(entry);

  Future<void> deletePodcast(int id) =>
      (delete(podcasts)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Episodes])
class EpisodeDao extends DatabaseAccessor<AppDatabase> with _$EpisodeDaoMixin {
  EpisodeDao(super.db);

  Stream<List<Episode>> watchByPodcast(int podcastId) =>
      (select(episodes)
            ..where((t) => t.podcastId.equals(podcastId))
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.pubDate, mode: OrderingMode.desc),
            ]))
          .watch();

  Future<List<Episode>> getByPodcast(int podcastId) =>
      (select(episodes)..where((t) => t.podcastId.equals(podcastId))).get();

  Future<Episode?> getById(int id) =>
      (select(episodes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Episode?> watchById(int id) =>
      (select(episodes)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<void> updatePosition(int id, int positionMs) =>
      (update(episodes)..where((t) => t.id.equals(id))).write(
        EpisodesCompanion(positionMs: Value(positionMs)),
      );

  Future<void> markPlayed(int id) =>
      (update(episodes)..where((t) => t.id.equals(id))).write(
        const EpisodesCompanion(isPlayed: Value(true)),
      );

  Future<void> setPlayed(int id, bool played) =>
      (update(episodes)..where((t) => t.id.equals(id))).write(
        EpisodesCompanion(isPlayed: Value(played)),
      );

  Future<void> setAllPlayed(int podcastId, bool played) =>
      (update(episodes)..where((t) => t.podcastId.equals(podcastId))).write(
        EpisodesCompanion(isPlayed: Value(played)),
      );

  /// Mark every episode of every podcast played/unplayed.
  Future<void> setAllPlayedGlobal(bool played) =>
      update(episodes).write(EpisodesCompanion(isPlayed: Value(played)));

  /// On a fresh subscribe, treat all but the most recent [keepRecent] episodes
  /// as already-played (so only the latest few show as "new"), without touching
  /// episodes the user has started or finished.
  Future<void> markOlderAsPlayed(int podcastId, {int keepRecent = 3}) async {
    final eps =
        await (select(episodes)
              ..where((t) => t.podcastId.equals(podcastId))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.pubDate,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    final toMark = eps
        .skip(keepRecent)
        .where((e) => !e.isPlayed && e.positionMs == 0)
        .map((e) => e.id)
        .toList();
    if (toMark.isEmpty) return;
    await (update(episodes)..where((t) => t.id.isIn(toMark))).write(
      const EpisodesCompanion(isPlayed: Value(true)),
    );
  }

  Future<void> markCompleted(int id) =>
      (update(episodes)..where((t) => t.id.equals(id))).write(
        const EpisodesCompanion(isPlayed: Value(true), positionMs: Value(0)),
      );

  Future<void> setDownloadState(int id, DownloadState downloadState) =>
      (update(episodes)..where((t) => t.id.equals(id))).write(
        EpisodesCompanion(downloadState: Value(downloadState)),
      );

  Future<void> setDownloaded(int id, String localPath) =>
      (update(episodes)..where((t) => t.id.equals(id))).write(
        EpisodesCompanion(
          downloadState: const Value(DownloadState.downloaded),
          localPath: Value(localPath),
        ),
      );

  Future<void> clearDownload(int id) =>
      (update(episodes)..where((t) => t.id.equals(id))).write(
        const EpisodesCompanion(
          downloadState: Value(DownloadState.notDownloaded),
          localPath: Value(null),
        ),
      );

  /// Flags (or clears) an episode whose source failed to load, so the list can
  /// grey it out.
  Future<void> setUnavailable(int id, bool value) =>
      (update(episodes)..where((t) => t.id.equals(id))).write(
        EpisodesCompanion(unavailable: Value(value)),
      );

  /// Inserts new episodes and refreshes feed metadata on existing ones,
  /// without clobbering user state (position, played flag, downloads).
  Future<void> upsertAll(List<EpisodesCompanion> rows) async {
    await batch((b) {
      for (final r in rows) {
        b.insert(
          episodes,
          r,
          onConflict: DoUpdate(
            (_) => EpisodesCompanion(
              title: r.title,
              showNotes: r.showNotes,
              audioUrl: r.audioUrl,
              imageUrl: r.imageUrl,
              link: r.link,
              durationMs: r.durationMs,
              sizeBytes: r.sizeBytes,
              pubDate: r.pubDate,
              // Still in the feed → clear any prior "unavailable" so a refreshed
              // (possibly fixed) URL gets another chance to play.
              unavailable: const Value(false),
            ),
            target: [episodes.podcastId, episodes.guid],
          ),
        );
      }
    });
  }
}

@DriftAccessor(tables: [Transcripts])
class TranscriptDao extends DatabaseAccessor<AppDatabase>
    with _$TranscriptDaoMixin {
  TranscriptDao(super.db);

  Stream<Transcript?> watchByEpisode(int episodeId) => (select(
    transcripts,
  )..where((t) => t.episodeId.equals(episodeId))).watchSingleOrNull();

  Future<Transcript?> getByEpisode(int episodeId) => (select(
    transcripts,
  )..where((t) => t.episodeId.equals(episodeId))).getSingleOrNull();

  /// One stream of every transcribed episode id, so any episode list can show
  /// a per-row "has transcript" badge without spinning up a stream per tile.
  Stream<Set<int>> watchAllEpisodeIds() =>
      select(transcripts).watch().map((rows) => rows.map((t) => t.episodeId).toSet());

  Future<void> upsert(int episodeId, String text, String? language) =>
      into(transcripts).insertOnConflictUpdate(
        TranscriptsCompanion(
          episodeId: Value(episodeId),
          content: Value(text),
          language: Value(language),
          createdAt: Value(DateTime.now()),
        ),
      );
}

@DriftAccessor(tables: [QueueItems])
class QueueDao extends DatabaseAccessor<AppDatabase> with _$QueueDaoMixin {
  QueueDao(super.db);

  Future<void> add(int episodeId) async {
    final all = await select(queueItems).get();
    if (all.any((q) => q.episodeId == episodeId)) return;
    final maxPos = all.isEmpty
        ? -1
        : all.map((q) => q.position).reduce((a, b) => a > b ? a : b);
    await into(queueItems).insert(
      QueueItemsCompanion(
        episodeId: Value(episodeId),
        position: Value(maxPos + 1),
      ),
    );
  }

  Future<void> remove(int episodeId) =>
      (delete(queueItems)..where((t) => t.episodeId.equals(episodeId))).go();

  Future<void> clear() => delete(queueItems).go();

  Future<bool> contains(int episodeId) async =>
      (await (select(
        queueItems,
      )..where((t) => t.episodeId.equals(episodeId))).getSingleOrNull()) !=
      null;

  Future<void> setOrder(List<int> episodeIdsInOrder) async {
    await batch((b) {
      for (var i = 0; i < episodeIdsInOrder.length; i++) {
        b.update(
          queueItems,
          QueueItemsCompanion(position: Value(i)),
          where: (t) => t.episodeId.equals(episodeIdsInOrder[i]),
        );
      }
    });
  }
}

@DriftDatabase(tables: [Podcasts, Episodes, Transcripts, QueueItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  late final PodcastDao podcastDao = PodcastDao(this);
  late final EpisodeDao episodeDao = EpisodeDao(this);
  late final TranscriptDao transcriptDao = TranscriptDao(this);
  late final QueueDao queueDao = QueueDao(this);

  /// Subscribed podcasts with their unplayed count and latest-episode date.
  Stream<List<({Podcast podcast, int unplayed, DateTime? lastEpisode})>>
  watchLibraryWithCounts() {
    final unplayed = episodes.id.count(filter: episodes.isPlayed.equals(false));
    final lastEpisode = episodes.pubDate.max();
    final query =
        select(podcasts).join([
            leftOuterJoin(episodes, episodes.podcastId.equalsExp(podcasts.id)),
          ])
          ..where(podcasts.subscribed.equals(true))
          ..addColumns([unplayed, lastEpisode])
          ..groupBy([podcasts.id])
          ..orderBy([OrderingTerm(expression: podcasts.title)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (
            podcast: row.readTable(podcasts),
            unplayed: row.read(unplayed) ?? 0,
            lastEpisode: row.read(lastEpisode),
          ),
      ],
    );
  }

  /// The up-next queue joined with episode + podcast, in queue order.
  Stream<List<({Episode episode, Podcast podcast})>> watchQueue() {
    final query = select(queueItems).join([
      innerJoin(episodes, episodes.id.equalsExp(queueItems.episodeId)),
      innerJoin(podcasts, podcasts.id.equalsExp(episodes.podcastId)),
    ])..orderBy([OrderingTerm.asc(queueItems.position)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (episode: row.readTable(episodes), podcast: row.readTable(podcasts)),
      ],
    );
  }

  Future<({Episode episode, Podcast podcast})?> firstInQueue() async {
    final query =
        select(queueItems).join([
            innerJoin(episodes, episodes.id.equalsExp(queueItems.episodeId)),
            innerJoin(podcasts, podcasts.id.equalsExp(episodes.podcastId)),
          ])
          ..orderBy([OrderingTerm.asc(queueItems.position)])
          ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (episode: row.readTable(episodes), podcast: row.readTable(podcasts));
  }

  /// Episodes in a given download state, joined with their podcast, newest
  /// first.
  Stream<List<({Episode episode, Podcast podcast})>> _watchEpisodesInState(
    DownloadState downloadState,
  ) {
    final query =
        select(episodes).join([
            innerJoin(podcasts, podcasts.id.equalsExp(episodes.podcastId)),
          ])
          ..where(episodes.downloadState.equalsValue(downloadState))
          ..orderBy([OrderingTerm.desc(episodes.pubDate)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (episode: row.readTable(episodes), podcast: row.readTable(podcasts)),
      ],
    );
  }

  Stream<List<({Episode episode, Podcast podcast})>>
  watchDownloadedWithPodcast() =>
      _watchEpisodesInState(DownloadState.downloaded);

  Stream<List<({Episode episode, Podcast podcast})>>
  watchDownloadingWithPodcast() =>
      _watchEpisodesInState(DownloadState.downloading);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(episodes, episodes.sizeBytes);
      }
      if (from < 3) {
        await m.createTable(transcripts);
      }
      if (from < 4) {
        await m.createTable(queueItems);
      }
      if (from < 5) {
        // Existing subscriptions imported their whole back catalogue as
        // unplayed. Mark all but the latest 3 per podcast as played (only
        // untouched episodes) so unlistened badges are meaningful.
        await customStatement(
          'UPDATE episodes SET is_played = 1 '
          'WHERE position_ms = 0 AND is_played = 0 AND id IN ('
          '  SELECT id FROM ('
          '    SELECT id, ROW_NUMBER() OVER ('
          '      PARTITION BY podcast_id ORDER BY pub_date DESC'
          '    ) AS rn FROM episodes'
          '  ) WHERE rn > 3'
          ')',
        );
      }
      if (from < 6) {
        await m.addColumn(podcasts, podcasts.subscribed);
        await m.addColumn(episodes, episodes.imageUrl);
      }
      if (from < 7) {
        await m.addColumn(podcasts, podcasts.link);
        await m.addColumn(episodes, episodes.link);
      }
      if (from < 8) {
        await m.addColumn(podcasts, podcasts.sortIndex);
        // Seed manual order with insertion order (≈ time added).
        await customStatement('UPDATE podcasts SET sort_index = id');
      }
      if (from < 9) {
        await m.addColumn(episodes, episodes.unavailable);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Filename a restore is staged under. A picked backup can't overwrite the live
/// database while SQLite holds it open (that corrupts it), so restore writes
/// here and the swap happens below, before the database is opened.
const kPendingRestoreFile = 'frontiercast.restore.sqlite';
const kDatabaseFile = 'frontiercast.sqlite';

/// Every SQLite file starts with this 16-byte header. Checking it catches the
/// dangerous cases — a truncated copy, or the user picking the wrong file —
/// before we replace a working database with something unopenable.
Future<bool> _looksLikeSqlite(File f) async {
  try {
    if (await f.length() < 512) return false;
    final head = await f.openRead(0, 16).first;
    return String.fromCharCodes(head) == 'SQLite format 3\x00';
  } catch (_) {
    return false;
  }
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, kDatabaseFile));
    final pending = File(p.join(dir.path, kPendingRestoreFile));
    if (await pending.exists()) {
      if (await _looksLikeSqlite(pending)) {
        // Swap a staged restore into place before anything opens the database.
        // Drop the WAL/SHM sidecars too, or SQLite would replay the old journal
        // over the restored file.
        for (final suffix in const ['-wal', '-shm']) {
          final sidecar = File('${file.path}$suffix');
          if (await sidecar.exists()) await sidecar.delete();
        }
        // Keep the outgoing database rather than deleting it, so a restore that
        // turns out to be bad can be rolled back instead of losing everything.
        final rollback = File('${file.path}.pre-restore');
        if (await rollback.exists()) await rollback.delete();
        if (await file.exists()) await file.rename(rollback.path);
        await pending.rename(file.path);
      } else {
        // A truncated or non-database file would leave the app unopenable if we
        // swapped it in — discard it and keep what's already here.
        await pending.delete();
      }
    }
    return NativeDatabase.createInBackground(file);
  });
}
