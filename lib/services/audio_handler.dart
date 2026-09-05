import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// audio_service handler wrapping a single just_audio player, exposing
/// rewind / play-pause / fast-forward on the lock screen and notification.
class PodcastAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();

  // Configurable skip intervals (used by both in-app and lock-screen controls).
  Duration skipForwardInterval = const Duration(seconds: 30);
  Duration skipBackwardInterval = const Duration(seconds: 30);

  PodcastAudioHandler() {
    _broadcastState();
    // Keep the MediaItem duration in sync with the resolved stream duration so
    // the notification scrubber and SeekHandler bounds are correct.
    player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null && item.duration != duration) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });
  }

  Future<void> loadAndPlay({
    required MediaItem item,
    required Uri uri,
    required Duration initialPosition,
  }) => setSource(item: item, uri: uri, initialPosition: initialPosition, play: true);

  /// Sets (or swaps) the audio source at [initialPosition], optionally starting
  /// playback. Used both for first load and for switching a streaming episode
  /// over to its local file once the download finishes.
  Future<void> setSource({
    required MediaItem item,
    required Uri uri,
    required Duration initialPosition,
    required bool play,
  }) async {
    mediaItem.add(item);
    await player.setAudioSource(
      AudioSource.uri(uri, tag: item),
      initialPosition: initialPosition,
    );
    if (play) await player.play();
  }

  void _broadcastState() {
    // onError keeps this subscription alive across transient playback errors
    // (e.g. a dropped network stream) so lock-screen state keeps updating.
    player.playbackEventStream.listen((event) {
      final playing = player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.rewind,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.fastForward,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: _processingState[player.processingState]!,
          playing: playing,
          updatePosition: player.position,
          bufferedPosition: player.bufferedPosition,
          speed: player.speed,
        ),
      );
    }, onError: (Object _, StackTrace _) {});
  }

  static const _processingState = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  /// Set while an episode is showing in the UI but its audio hasn't been opened
  /// yet — the state [PlaybackController.restoreLastEpisode] leaves behind at
  /// launch. Without this, a headset button, the notification, or a car control
  /// would call [play] straight into an empty player and silently do nothing,
  /// even though the app looks ready to resume. Cleared once a source loads.
  Future<void> Function()? onPlayUnprepared;

  @override
  Future<void> play() async {
    final loadFirst = onPlayUnprepared;
    if (loadFirst != null) {
      await loadFirst();
      return;
    }
    await player.play();
  }

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> fastForward() => _seekBy(skipForwardInterval);

  @override
  Future<void> rewind() => _seekBy(-skipBackwardInterval);

  Future<void> _seekBy(Duration delta) {
    var target = player.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    final dur = player.duration;
    if (dur != null && target > dur) target = dur;
    return player.seek(target);
  }

  @override
  Future<void> setSpeed(double speed) => player.setSpeed(speed);

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }
}
