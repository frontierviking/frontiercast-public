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
  Timer? _sleepTimer;

  @override
  PlaybackState build() {
    final posSub = _player.positionStream.listen(_onPosition);
    final stateSub = _player.playerStateStream.listen(_onPlayerState);
    _applySkipSettings(ref.read(playbackSettingsProvider).value);
    ref.listen(
      playbackSettingsProvider,
      (_, next) => _applySkipSettings(next.value),
    );
    ref.onDispose(() {
      posSub.cancel();
      stateSub.cancel();
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
    _marked = episode.isPlayed;
    _lastSavedSec = -1000;
    state = state.copyWith(episode: episode, podcast: podcast);
    final localPath = episode.localPath;
    final useLocal =
        episode.downloadState == DownloadState.downloaded &&
        localPath != null &&
        File(localPath).existsSync();
    try {
      await _handler.loadAndPlay(
        item: _mediaItem(episode, podcast),
        uri: useLocal ? Uri.file(localPath) : Uri.parse(episode.audioUrl),
        initialPosition: Duration(milliseconds: episode.positionMs),
      );
    } catch (_) {
      state = const PlaybackState();
      rethrow;
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
    if (ps.processingState == ProcessingState.completed) {
      _handleCompletion();
    }
  }

  Future<void> _handleCompletion() async {
    final episode = state.episode;
    if (episode != null) {
      await _db.episodeDao.markCompleted(episode.id);
    }
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
