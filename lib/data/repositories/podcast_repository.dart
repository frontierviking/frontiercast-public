import 'package:drift/drift.dart' show Value;

import '../db/database.dart';
import '../feed/feed_parser.dart';
import '../feed/opml_parser.dart';

class ImportResult {
  final int succeeded;
  final int failed;
  final List<String> errors;
  ImportResult(this.succeeded, this.failed, this.errors);

  int get total => succeeded + failed;
}

typedef ProgressCallback = void Function(int done, int total);

/// Orchestrates subscribing, refreshing and importing podcasts: fetches/parses
/// feeds and persists podcasts + episodes into drift.
class PodcastRepository {
  final AppDatabase db;
  final FeedParser feedParser;

  PodcastRepository(this.db, this.feedParser);

  /// Subscribes to (or refreshes) a feed. Returns the local podcast id.
  Future<int> subscribeByFeedUrl(String feedUrl) async {
    final parsed = await feedParser.fetchAndParse(feedUrl);
    final existing = await db.podcastDao.getByFeedUrl(feedUrl);
    final companion = PodcastsCompanion(
      title: Value(parsed.title),
      feedUrl: Value(feedUrl),
      imageUrl: Value(parsed.imageUrl),
      author: Value(parsed.author),
      description: Value(parsed.description),
      lastFetched: Value(DateTime.now()),
      subscribed: const Value(true),
    );

    final int podcastId;
    final bool isNew = existing == null;
    if (isNew) {
      podcastId = await db.podcastDao.insertPodcast(companion);
    } else {
      podcastId = existing.id;
      await db.podcastDao.updatePodcast(podcastId, companion);
    }
    await _upsertEpisodes(podcastId, parsed);
    if (isNew) {
      // Only the latest few episodes count as "new" on a fresh subscribe.
      await db.episodeDao.markOlderAsPlayed(podcastId);
    }
    return podcastId;
  }

  Future<void> refresh(int podcastId) async {
    final podcast = await db.podcastDao.getById(podcastId);
    if (podcast == null) return;
    final parsed = await feedParser.fetchAndParse(podcast.feedUrl);
    await db.podcastDao.updatePodcast(
      podcastId,
      PodcastsCompanion(
        title: Value(parsed.title),
        imageUrl: Value(parsed.imageUrl),
        author: Value(parsed.author),
        description: Value(parsed.description),
        lastFetched: Value(DateTime.now()),
      ),
    );
    await _upsertEpisodes(podcastId, parsed);
  }

  /// Unsubscribe keeps the data (and lets the user re-subscribe in place);
  /// it just hides the podcast from the library.
  Future<void> unsubscribe(int podcastId) =>
      db.podcastDao.setSubscribed(podcastId, false);

  Future<void> resubscribe(int podcastId) =>
      db.podcastDao.setSubscribed(podcastId, true);

  Future<void> _upsertEpisodes(int podcastId, ParsedFeed parsed) async {
    final rows = parsed.episodes
        .map(
          (e) => EpisodesCompanion(
            podcastId: Value(podcastId),
            guid: Value(e.guid),
            title: Value(e.title),
            showNotes: Value(e.showNotes),
            audioUrl: Value(e.audioUrl),
            imageUrl: Value(e.imageUrl),
            durationMs: Value(e.durationMs),
            sizeBytes: Value(e.sizeBytes),
            pubDate: Value(e.pubDate),
          ),
        )
        .toList();
    await db.episodeDao.upsertAll(rows);
  }

  /// Bulk-subscribes every feed in an OPML export, fetching feeds with limited
  /// concurrency so a large import doesn't open dozens of sockets at once.
  Future<ImportResult> importOpml(
    String xmlString, {
    ProgressCallback? onProgress,
    int concurrency = 4,
  }) async {
    final entries = parseOpml(xmlString);
    final queue = List.of(entries);
    var succeeded = 0;
    var failed = 0;
    var done = 0;
    final errors = <String>[];

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final entry = queue.removeLast();
        try {
          await subscribeByFeedUrl(entry.feedUrl);
          succeeded++;
        } catch (e) {
          failed++;
          errors.add('${entry.title}: $e');
        } finally {
          done++;
          onProgress?.call(done, entries.length);
        }
      }
    }

    await Future.wait([for (var i = 0; i < concurrency; i++) worker()]);
    return ImportResult(succeeded, failed, errors);
  }

  Future<ImportResult> refreshAll({
    ProgressCallback? onProgress,
    int concurrency = 4,
  }) async {
    final all = await db.podcastDao.getAll();
    final queue = List.of(all);
    var succeeded = 0;
    var failed = 0;
    var done = 0;
    final errors = <String>[];

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final podcast = queue.removeLast();
        try {
          await refresh(podcast.id);
          succeeded++;
        } catch (e) {
          failed++;
          errors.add('${podcast.title}: $e');
        } finally {
          done++;
          onProgress?.call(done, all.length);
        }
      }
    }

    await Future.wait([for (var i = 0; i < concurrency; i++) worker()]);
    return ImportResult(succeeded, failed, errors);
  }
}
