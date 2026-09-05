import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/database.dart';
import '../domain/models.dart';
import '../providers.dart';
import 'audio_handler.dart';
import 'playback_settings.dart';

/// Snapshot of position-related values for the scrubber.
class PositionData {
  final Duration position;
  final Duration buffered;
  final Duration duration;
  const PositionData(this.position, this.buffered, this.duration);
}

const _unset = Object();

/// The episode the mini player should come back to after a restart.
const _kLastEpisodeKey = 'last_episode_id';

class PlaybackState {
  final Episode? episode;
  final Podcast? podcast;

  /// When set, playback auto-pauses at this time (sleep timer).
  final DateTime? sleepEnd;

  /// When true, playback stops at the end of the current episode.
  final bool sleepAtEnd;

  /// Most recent playback failure, used to surface a one-shot snackbar.
  /// The timestamp makes each error distinct so listeners can detect new ones.
  final ({String message, DateTime at})? lastError;

  const PlaybackState({
    this.episode,
    this.podcast,
    this.sleepEnd,
    this.sleepAtEnd = false,
    this.lastError,
  });

  bool get sleepActive => sleepEnd != null || sleepAtEnd;

  PlaybackState copyWith({
    Episode? episode,
    Podcast? podcast,
    Object? sleepEnd = _unset,
    bool? sleepAtEnd,
    Object? lastError = _unset,
  }) {
    return PlaybackState(
      episode: episode ?? this.episode,
      podcast: podcast ?? this.podcast,
      sleepEnd: identical(sleepEnd, _unset)
          ? this.sleepEnd
          : sleepEnd as DateTime?,
      sleepAtEnd: sleepAtEnd ?? this.sleepAtEnd,
      lastError: identical(lastError, _unset)
          ? this.lastError
          : lastError as ({String message, DateTime at})?,
    );
  }
}

class PlaybackController extends Notifier<PlaybackState> {
  PodcastAudioHandler get _handler => ref.read(audioHandlerProvider);
  AudioPlayer get _player => ref.read(audioPlayerProvider);
  AppDatabase get _db => ref.read(databaseProvider);

  int _lastSavedSec = -1000;
  bool _marked = false;
  bool _recovering = false;

  /// Whether the audio source for [PlaybackState.episode] is actually loaded
  /// into the player. False after [restoreLastEpisode], which puts an episode
  /// in the bar without paying to open its audio at launch.
  bool _prepared = false;
  Timer? _sleepTimer;
  StreamSubscription<Episode?>? _episodeSub;

  @override
  PlaybackState build() {
    final posSub = _player.positionStream.listen(_onPosition);
    final stateSub = _player.playerStateStream.listen(_onPlayerState);
    // Surface playback errors (e.g. a dropped network stream) so we can recover
    // instead of leaving the player wedged and unable to resume.
    final errSub = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace _) => _onPlayerError(e),
    );
    _applySkipSettings(ref.read(playbackSettingsProvider).value);
    ref.listen(
      playbackSettingsProvider,
      (_, next) => _applySkipSettings(next.value),
    );
    ref.onDispose(() {
      posSub.cancel();
      stateSub.cancel();
      errSub.cancel();
      _episodeSub?.cancel();
      _sleepTimer?.cancel();
    });
    return const PlaybackState();
  }

  void _applySkipSettings(PlaybackSettings? settings) {
    if (settings == null) return;
    _handler.skipForwardInterval = Duration(seconds: settings.forwardSeconds);
    _handler.skipBackwardInterval =
        Duration(seconds: settings.backwardSeconds);
  }

  // --- Sleep timer ---

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(duration, () {
      _handler.pause();
      _savePosition(force: true);
      state = state.copyWith(sleepEnd: null, sleepAtEnd: false);
    });
    state = state.copyWith(
      sleepEnd: DateTime.now().add(duration),
      sleepAtEnd: false,
    );
  }

  void setSleepAtEndOfEpisode() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    state = state.copyWith(sleepEnd: null, sleepAtEnd: true);
  }

  void cancelSleep() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    state = state.copyWith(sleepEnd: null, sleepAtEnd: false);
  }

  Future<void> playEpisode(Episode episode, Podcast podcast) async {
    // Only a shortcut when the source is genuinely loaded — after a restore the
    // episode is in the bar but the player is empty, and play() would no-op.
    if (_prepared && state.episode?.id == episode.id) {
      await _player.play();
      return;
    }
    // Re-read the row so a download that finished after this Episode object was
    // captured is honoured — play the local file rather than streaming.
    final fresh = await _db.episodeDao.getById(episode.id) ?? episode;
    _marked = fresh.isPlayed;
    _lastSavedSec = -1000;
    _recovering = false;
    state = state.copyWith(episode: fresh, podcast: podcast);
    _watchEpisode(fresh.id);
    try {
      await _handler.loadAndPlay(
        item: _mediaItem(fresh, podcast),
        uri: _sourceFor(fresh),
        initialPosition: Duration(milliseconds: fresh.positionMs),
      );
      _prepared = true;
      _handler.onPlayUnprepared = null;
      unawaited(_rememberLastEpisode(fresh.id));
    } catch (e) {
      _prepared = false;
      // The episode is cleared from state below, so the stale lazy-load
      // closure must go with it.
      _handler.onPlayUnprepared = null;
      _episodeSub?.cancel();
      // A dead source (404 etc.) marks the episode unavailable so the list can
      // grey it out. Don't penalise plain connectivity failures — those are
      // transient and would wrongly grey everything while offline.
      if (!_isNetworkError(e)) {
        await _db.episodeDao.setUnavailable(fresh.id, true);
      }
      // Load errors (e.g. HTTP 404 on the audio URL) come through here rather
      // than the runtime playbackEventStream, so we surface them ourselves.
      state = PlaybackState(
        lastError: (
          message: _friendlyPlaybackError(e),
          at: DateTime.now(),
        ),
      );
      rethrow;
    }
  }

  Future<void> _rememberLastEpisode(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastEpisodeKey, id);
    } catch (_) {
      // Only costs us the mini player on next launch.
    }
  }

  /// Puts the last-played episode back in the mini player at startup.
  ///
  /// Playback state is in memory, and this process gets killed often — so an
  /// episode you paused was simply gone from the bottom bar on the next launch,
  /// leaving no way back to it but hunting through the library. This restores
  /// the bar only: the audio source is opened lazily on the first play, so
  /// launching stays cheap and a streamed episode doesn't start buffering (or
  /// raise a media notification) just because the app opened.
  Future<void> restoreLastEpisode() async {
    if (state.episode != null) return; // something is already loaded
    int? id;
    try {
      final prefs = await SharedPreferences.getInstance();
      id = prefs.getInt(_kLastEpisodeKey);
    } catch (_) {
      return;
    }
    if (id == null) return;
    final episode = await _db.episodeDao.getById(id);
    if (episode == null) return;
    final podcast = await _db.podcastDao.getById(episode.podcastId);
    if (podcast == null) return;
    _prepared = false;
    _marked = episode.isPlayed;
    state = state.copyWith(episode: episode, podcast: podcast);
    // Route a headset/notification/car play button through the same lazy load
    // the in-app button uses, rather than into an empty player.
    _handler.onPlayUnprepared = () => playEpisode(episode, podcast);
    _watchEpisode(episode.id);
  }

  /// Best available source: the downloaded file when present, else the stream.
  Uri _sourceFor(Episode e) =>
      _isLocal(e) ? Uri.file(e.localPath!) : Uri.parse(e.audioUrl);

  bool _isLocal(Episode e) {
    final p = e.localPath;
    return e.downloadState == DownloadState.downloaded &&
        p != null &&
        File(p).existsSync();
  }

  /// Keeps [state.episode] live (so the Now Playing download button reflects
  /// reality) and, if the file finishes downloading mid-stream, swaps playback
  /// over to the local file at the current position.
  void _watchEpisode(int id) {
    _episodeSub?.cancel();
    _episodeSub = _db.episodeDao.watchById(id).listen(_onEpisodeChanged);
  }

  Future<void> _onEpisodeChanged(Episode? e) async {
    final current = state.episode;
    final podcast = state.podcast;
    if (e == null || current == null || current.id != e.id || podcast == null) {
      return;
    }
    final wasStreaming = !_isLocal(current);
    state = state.copyWith(episode: e);
    // Nothing to swap if the source was never opened (restored at launch): the
    // lazy load on first play picks up the downloaded file by itself, and
    // swapping here would seek to the empty player's position — i.e. back to
    // zero, throwing away where the user actually was.
    if (wasStreaming && _isLocal(e) && _prepared) {
      final resume = _player.playing;
      final at = _player.position;
      try {
        await _handler.setSource(
          item: _mediaItem(e, podcast),
          uri: Uri.file(e.localPath!),
          initialPosition: at,
          play: resume,
        );
      } catch (_) {
        // Keep the existing (streaming) source if the swap fails.
      }
    }
  }

  /// On a playback error: surface a friendly message to the UI, then reload
  /// the best source at the last saved position so the user can resume. The
  /// reload is guarded to a single attempt to avoid retry loops, but the error
  /// is always reported so the snackbar fires.
  Future<void> _onPlayerError(Object error) async {
    final episode = state.episode;
    final podcast = state.podcast;
    if (episode == null || podcast == null) return;
    state = state.copyWith(
      lastError: (message: _friendlyPlaybackError(error), at: DateTime.now()),
    );
    if (_recovering) return;
    _recovering = true;
    final fresh = await _db.episodeDao.getById(episode.id) ?? episode;
    try {
      await _handler.setSource(
        item: _mediaItem(fresh, podcast),
        uri: _sourceFor(fresh),
        initialPosition: Duration(milliseconds: fresh.positionMs),
        play: false,
      );
    } catch (_) {
      // Leave the player as-is; the user can re-trigger playback.
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _handler.pause();
      await _savePosition(force: true);
      return;
    }
    // Restored from a previous run: nothing is loaded yet, so open the source
    // now (from its saved position) instead of calling play() into an empty
    // player, which would silently do nothing.
    final episode = state.episode;
    final podcast = state.podcast;
    if (!_prepared && episode != null && podcast != null) {
      await playEpisode(episode, podcast);
      return;
    }
    await _handler.play();
  }

  Future<void> seek(Duration position) => _handler.seek(position);

  Future<void> skipForward() => _handler.fastForward();

  Future<void> skipBackward() => _handler.rewind();

  Future<void> setSpeed(double speed) => _handler.setSpeed(speed);

  MediaItem _mediaItem(Episode e, Podcast p) => MediaItem(
    id: e.id.toString(),
    album: p.title,
    title: e.title,
    artUri: (e.imageUrl != null && e.imageUrl!.isNotEmpty)
        ? Uri.tryParse(e.imageUrl!)
        : (p.imageUrl != null && p.imageUrl!.isNotEmpty)
        ? Uri.tryParse(p.imageUrl!)
        : null,
    duration: e.durationMs != null
        ? Duration(milliseconds: e.durationMs!)
        : null,
  );

  void _onPosition(Duration pos) {
    final episode = state.episode;
    if (episode == null) return;

    if (_player.playing && pos.inSeconds - _lastSavedSec >= 5) {
      _savePosition();
    }

    final dur = _player.duration;
    if (!_marked &&
        dur != null &&
        dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds * 0.95) {
      _marked = true;
      _db.episodeDao.markPlayed(episode.id);
    }
  }

  void _onPlayerState(PlayerState ps) {
    // Player is healthy again — allow a future error to be recovered and clear
    // any stale "unavailable" flag now that this episode loaded fine.
    if (ps.processingState == ProcessingState.ready) {
      _recovering = false;
      final ep = state.episode;
      if (ep != null && ep.unavailable) {
        _db.episodeDao.setUnavailable(ep.id, false);
      }
    }
    if (ps.processingState == ProcessingState.completed) {
      _handleCompletion();
    }
  }

  Future<void> _handleCompletion() async {
    final episode = state.episode;
    if (episode == null) return;
    // A dropped network stream can surface as a premature "completed". If we
    // ended well short of the known duration, treat it as a stall: recover at
    // the saved position instead of marking the episode played.
    final dur = _player.duration;
    final pos = _player.position;
    if (dur != null &&
        dur.inSeconds > 0 &&
        pos < dur * 0.98 &&
        (dur - pos).inSeconds > 15) {
      await _onPlayerError('premature completion');
      return;
    }
    await _db.episodeDao.markCompleted(episode.id);
    // "Sleep at end of episode" stops here regardless of the queue.
    if (state.sleepAtEnd) {
      state = state.copyWith(sleepAtEnd: false);
      await _player.pause();
      await _player.seek(Duration.zero);
      return;
    }
    final next = await _db.firstInQueue();
    if (next != null) {
      await _db.queueDao.remove(next.episode.id);
      await playEpisode(next.episode, next.podcast);
    } else {
      await _player.pause();
      await _player.seek(Duration.zero);
    }
  }

  Future<void> _savePosition({bool force = false}) async {
    final episode = state.episode;
    if (episode == null) return;
    final ms = _player.position.inMilliseconds;
    _lastSavedSec = _player.position.inSeconds;
    await _db.episodeDao.updatePosition(episode.id, ms);
  }
}

/// True when an error looks like transient connectivity rather than a dead
/// source — used to avoid greying out episodes just because the user is offline.
bool _isNetworkError(Object error) {
  final s = error.toString();
  return s.contains('SocketException') ||
      s.contains('Failed host lookup') ||
      s.contains('Unable to connect') ||
      s.contains('Network is unreachable');
}

/// Best-effort mapping of a player exception to a user-readable message.
String _friendlyPlaybackError(Object error) {
  final s = error.toString();
  final httpCode = RegExp(r'Response code:?\s*(\d{3})').firstMatch(s);
  if (httpCode != null) {
    final code = httpCode.group(1)!;
    if (code == '404') {
      return 'Episode unavailable (HTTP 404). The publisher may have removed it.';
    }
    if (code == '403') return 'Episode unavailable (HTTP 403 — forbidden).';
    return 'Server error (HTTP $code).';
  }
  if (s.contains('SocketException') ||
      s.contains('Failed host lookup') ||
      s.contains('Unable to connect') ||
      s.contains('Network is unreachable')) {
    return 'Network error — check your connection.';
  }
  if (s.contains('UnrecognizedInputFormatException') ||
      s.contains('Unsupported format')) {
    return "Couldn't play this episode (unsupported audio format).";
  }
  // just_audio's PlayerException for a failed load reads "(0) Source error"
  // and doesn't expose the underlying HTTP status, so we give a useful
  // explanation rather than echoing the cryptic message. A dead URL (the
  // common cause) deserves a plain-language hint.
  if (s.contains('Source error') || s.contains('PlayerException')) {
    return 'Episode unavailable — the audio file couldn’t be loaded. '
        'The publisher may have removed or moved it.';
  }
  return "Couldn't play this episode.";
}
