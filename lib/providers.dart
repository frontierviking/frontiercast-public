import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'data/db/database.dart';
import 'data/feed/feed_parser.dart';
import 'data/repositories/podcast_repository.dart';
import 'data/search/itunes_search.dart';
import 'data/transcribe/transcribe_client.dart';
import 'data/transcribe/transcribe_settings.dart';
import 'services/audio_handler.dart';
import 'services/download_controller.dart';
import 'services/playback_controller.dart';
import 'services/playback_settings.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final feedParserProvider = Provider<FeedParser>((ref) => FeedParser());

final itunesSearchProvider = Provider<ItunesSearch>((ref) => ItunesSearch());

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

/// Subscribed podcasts with their unplayed-episode counts (for badges).
final libraryWithCountsProvider =
    StreamProvider<List<({Podcast podcast, int unplayed})>>(
      (ref) => ref.watch(databaseProvider).watchLibraryWithCounts(),
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

final transcribeSettingsProvider =
    AsyncNotifierProvider<TranscribeSettingsController, TranscribeSettings>(
      TranscribeSettingsController.new,
    );

/// The stored transcript for an episode, if any.
final transcriptProvider = StreamProvider.family<Transcript?, int>(
  (ref, episodeId) =>
      ref.watch(databaseProvider).transcriptDao.watchByEpisode(episodeId),
);

/// The up-next queue (joined with podcast), in order.
final queueProvider =
    StreamProvider<List<({Episode episode, Podcast podcast})>>(
      (ref) => ref.watch(databaseProvider).watchQueue(),
    );

/// iTunes search results for a query string.
final searchResultsProvider = FutureProvider.autoDispose
    .family<List<ItunesPodcast>, String>((ref, query) async {
      if (query.trim().isEmpty) return const [];
      return ref.watch(itunesSearchProvider).search(query);
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
