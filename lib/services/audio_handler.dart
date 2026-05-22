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
  }) async {
    mediaItem.add(item);
    await player.setAudioSource(
      AudioSource.uri(uri, tag: item),
      initialPosition: initialPosition,
    );
    await player.play();
  }

  void _broadcastState() {
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
    });
  }

  static const _processingState = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  @override
  Future<void> play() => player.play();

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
