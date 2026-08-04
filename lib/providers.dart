import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'data/db/database.dart';
import 'data/feed/feed_parser.dart';
import 'data/repositories/podcast_repository.dart';
import 'data/search/itunes_search.dart';
import 'data/search/podcast_index_search.dart';
import 'data/search/podcast_index_settings.dart';
import 'data/search/podcast_search.dart';
import 'data/transcribe/transcribe_client.dart';
import 'data/transcribe/transcribe_settings.dart';
import 'services/audio_handler.dart';
import 'services/download_controller.dart';
import 'services/library_settings.dart';
import 'services/playback_controller.dart';
import 'services/playback_settings.dart';
import 'services/transcribe_controller.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final feedParserProvider = Provider<FeedParser>((ref) => FeedParser());

final itunesSearchProvider = Provider<ItunesSearch>((ref) => ItunesSearch());

final podcastIndexSearchProvider = Provider<PodcastIndexSearch>(
  (ref) => PodcastIndexSearch(),
);

final podcastIndexSettingsProvider =
    AsyncNotifierProvider<PodcastIndexSettingsController, PodcastIndexSettings>(
      PodcastIndexSettingsController.new,
    );

final podcastRepositoryProvider = Provider<PodcastRepository>(
  (ref) => PodcastRepository(
    ref.watch(databaseProvider),
    ref.watch(feedParserProvider),
  ),
);

/// All subscribed podcasts, reactive to DB changes.
final libraryProvider = StreamProvider<List<Podcast>>(
  (ref) => ref.watch(databaseProvider).podcastDao.watchAll(),
);

/// Subscribed podcasts with unplayed counts + latest-episode date.
final libraryWithCountsProvider =
    StreamProvider<
      List<({Podcast podcast, int unplayed, DateTime? lastEpisode})>
    >((ref) => ref.watch(databaseProvider).watchLibraryWithCounts());

final librarySortProvider =
    AsyncNotifierProvider<LibrarySortController, LibrarySort>(
      LibrarySortController.new,
    );

/// A single podcast by id (for the detail header).
final podcastProvider = StreamProvider.family<Podcast?, int>(
  (ref, id) => ref.watch(databaseProvider).podcastDao.watchById(id),
);

/// Episodes for a podcast, newest first.
final episodesProvider = StreamProvider.family<List<Episode>, int>(
  (ref, podcastId) =>
      ref.watch(databaseProvider).episodeDao.watchByPodcast(podcastId),
);

/// A single episode by id, reactive (played flag, saved position).
final episodeProvider = StreamProvider.family<Episode?, int>(
  (ref, id) => ref.watch(databaseProvider).episodeDao.watchById(id),
);

/// Active downloads: episodeId -> progress (0..1).
final downloadControllerProvider =
    NotifierProvider<DownloadController, Map<int, double>>(
      DownloadController.new,
    );

/// All downloaded episodes (joined with podcast), newest first.
final downloadedProvider =
    StreamProvider<List<({Episode episode, Podcast podcast})>>(
      (ref) => ref.watch(databaseProvider).watchDownloadedWithPodcast(),
    );

/// Episodes currently downloading (joined with podcast).
final downloadingProvider =
    StreamProvider<List<({Episode episode, Podcast podcast})>>(
      (ref) => ref.watch(databaseProvider).watchDownloadingWithPodcast(),
    );

// --- Transcription (Phase 5) ---

final transcribeClientProvider = Provider<TranscribeClient>(
  (ref) => TranscribeClient(),
);

/// Simple mutable holder (Riverpod 3 dropped StateProvider).
class _Holder<T> extends Notifier<T> {
  final T _initial;
  _Holder(this._initial);
  @override
  T build() => _initial;
  @override
  set state(T value) => super.state = value;
}

/// Last transcription failure, surfaced as a one-shot snackbar. The timestamp
/// makes each error distinct so a listener can detect new ones.
final transcribeErrorProvider =
    NotifierProvider<_Holder<({String message, DateTime at})?>,
        ({String message, DateTime at})?>(
      () => _Holder(null),
    );

/// Which route the last transcription actually connected over ('Wi-Fi / LAN'
/// or 'Tailscale'), for display in the transcript view. Null until one runs.
final transcribeRouteInUseProvider =
    NotifierProvider<_Holder<String?>, String?>(() => _Holder(null));

/// Transcription queue: episode id -> job (episode, podcast, stage, progress).
/// Insertion-ordered, so its values are the queue order (first non-queued
/// entry is the one currently running).
final transcribeControllerProvider =
    NotifierProvider<TranscribeController, Map<int, TranscribeJob>>(
      TranscribeController.new,
    );

final transcribeSettingsProvider =
    AsyncNotifierProvider<TranscribeSettingsController, TranscribeSettings>(
      TranscribeSettingsController.new,
    );

/// The stored transcript for an episode, if any.
final transcriptProvider = StreamProvider.family<Transcript?, int>(
  (ref, episodeId) =>
      ref.watch(databaseProvider).transcriptDao.watchByEpisode(episodeId),
);

/// The set of episode ids that have a stored transcript. Used by episode lists
/// to show a per-row "has transcript" badge without one stream per tile.
final transcribedEpisodeIdsProvider = StreamProvider<Set<int>>(
  (ref) => ref.watch(databaseProvider).transcriptDao.watchAllEpisodeIds(),
);

/// The up-next queue (joined with podcast), in order.
final queueProvider =
    StreamProvider<List<({Episode episode, Podcast podcast})>>(
      (ref) => ref.watch(databaseProvider).watchQueue(),
    );

/// Podcast search results for a query string, merged from iTunes and (when
/// API credentials are configured) Podcast Index. A failure in one source is
/// ignored so the other still returns results; hits are de-duplicated by feed.
final searchResultsProvider = FutureProvider.autoDispose
    .family<List<PodcastSearchResult>, String>((ref, query) async {
      final q = query.trim();
      if (q.isEmpty) return const [];
      final itunes = ref.watch(itunesSearchProvider);
      final pi = ref.watch(podcastIndexSearchProvider);
      final piSettings = ref.watch(podcastIndexSettingsProvider).value;

      final futures = <Future<List<PodcastSearchResult>>>[
        itunes.search(q).catchError((Object _) => <PodcastSearchResult>[]),
        if (piSettings != null && piSettings.configured)
          pi
              .search(
                q,
                apiKey: piSettings.apiKey,
                apiSecret: piSettings.apiSecret,
              )
              .catchError((Object _) => <PodcastSearchResult>[]),
      ];
      final lists = await Future.wait(futures);

      final seen = <String>{};
      final merged = <PodcastSearchResult>[];
      for (final list in lists) {
        for (final r in list) {
          final key = r.feedUrl.trim().toLowerCase().replaceAll(
            RegExp(r'/+$'),
            '',
          );
          if (seen.add(key)) merged.add(r);
        }
      }
      return merged;
    });

/// Set of subscribed feed URLs, used to mark search results already in library.
final subscribedFeedUrlsProvider = Provider<Set<String>>((ref) {
  final podcasts = ref.watch(libraryProvider).value ?? const [];
  return podcasts.map((p) => p.feedUrl).toSet();
});

// --- Playback ---

/// Set once in main() via override after AudioService.init().
final audioHandlerProvider = Provider<PodcastAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main()');
});

final audioPlayerProvider = Provider<AudioPlayer>(
  (ref) => ref.watch(audioHandlerProvider).player,
);

final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackState>(PlaybackController.new);

final playbackSettingsProvider =
    AsyncNotifierProvider<PlaybackSettingsController, PlaybackSettings>(
      PlaybackSettingsController.new,
    );

final playerStateProvider = StreamProvider<PlayerState>(
  (ref) => ref.watch(audioPlayerProvider).playerStateStream,
);

final positionDataProvider = StreamProvider<PositionData>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.positionStream.map(
    (pos) => PositionData(
      pos,
      player.bufferedPosition,
      player.duration ?? Duration.zero,
    ),
  );
});
