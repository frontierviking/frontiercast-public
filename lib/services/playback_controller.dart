import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

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

class PlaybackState {
  final Episode? episode;
  final Podcast? podcast;

  /// When set, playback auto-pauses at this time (sleep timer).
  final DateTime? sleepEnd;

  /// When true, playback stops at the end of the current episode.
  final bool sleepAtEnd;

  const PlaybackState({
    this.episode,
    this.podcast,
    this.sleepEnd,
    this.sleepAtEnd = false,
  });

  bool get sleepActive => sleepEnd != null || sleepAtEnd;

  PlaybackState copyWith({
    Episode? episode,
    Podcast? podcast,
    Object? sleepEnd = _unset,
    bool? sleepAtEnd,
  }) {
    return PlaybackState(
      episode: episode ?? this.episode,
      podcast: podcast ?? this.podcast,
      sleepEnd: identical(sleepEnd, _unset)
          ? this.sleepEnd
          : sleepEnd as DateTime?,
      sleepAtEnd: sleepAtEnd ?? this.sleepAtEnd,
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
    if (state.episode?.id == episode.id) {
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
    } catch (_) {
      _episodeSub?.cancel();
      state = const PlaybackState();
      rethrow;
    }
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
    if (wasStreaming && _isLocal(e)) {
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

  /// On a playback error, reload the best source at the last saved position so
  /// the user can resume. Guarded to a single attempt to avoid retry loops.
  Future<void> _onPlayerError(Object error) async {
    final episode = state.episode;
    final podcast = state.podcast;
    if (episode == null || podcast == null || _recovering) return;
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
    } else {
      await _handler.play();
    }
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
    // Player is healthy again — allow a future error to be recovered.
    if (ps.processingState == ProcessingState.ready) _recovering = false;
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
