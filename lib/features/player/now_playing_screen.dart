import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../providers.dart';
import '../../services/playback_controller.dart';
import '../../util/format.dart';
import '../downloads/download_button.dart';
import '../queue/queue_screen.dart';
import '../transcript/transcript_screen.dart';
import 'skip_seconds_dialog.dart';

const _speeds = [0.8, 1.0, 1.2, 1.5, 1.75, 2.0];

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackControllerProvider);
    final episode = playback.episode;
    final podcast = playback.podcast;

    if (episode == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Nothing playing')),
      );
    }

    final posData =
        ref.watch(positionDataProvider).value ??
        const PositionData(Duration.zero, Duration.zero, Duration.zero);
    final controller = ref.read(playbackControllerProvider.notifier);

    final artUrl = (episode.imageUrl != null && episode.imageUrl!.isNotEmpty)
        ? episode.imageUrl
        : podcast?.imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          DownloadButton(episode: episode),
          IconButton(
            tooltip: 'Transcript',
            icon: Icon(
              ref.watch(transcriptProvider(episode.id)).value != null
                  ? Icons.article
                  : Icons.article_outlined,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    TranscriptScreen(episode: episode, podcast: podcast),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Up next',
            icon: const Icon(Icons.queue_music),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const QueueScreen())),
          ),
          _SleepButton(sleepActive: playback.sleepActive),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: (artUrl != null && artUrl.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: artUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              const Icon(Icons.podcasts, size: 96),
                        )
                      : const ColoredBox(
                          color: Colors.black26,
                          child: Icon(Icons.podcasts, size: 96),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                episode.title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (podcast != null) ...[
                const SizedBox(height: 4),
                Text(
                  podcast.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              _Scrubber(
                posData: posData,
                dragValue: _dragValue,
                onChanged: (v) => setState(() => _dragValue = v),
                onChangeEnd: (v) {
                  controller.seek(Duration(milliseconds: v.round()));
                  setState(() => _dragValue = null);
                },
              ),
              const SizedBox(height: 8),
              _Controls(controller: controller),
              const SizedBox(height: 8),
              _SpeedButton(controller: controller),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Scrubber extends StatelessWidget {
  final PositionData posData;
  final double? dragValue;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _Scrubber({
    required this.posData,
    required this.dragValue,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final maxMs = posData.duration.inMilliseconds.toDouble();
    final posMs = posData.position.inMilliseconds.toDouble().clamp(
      0.0,
      maxMs <= 0 ? 0.0 : maxMs,
    );
    final value = dragValue ?? posMs;
    final remaining = posData.duration - posData.position;

    return Column(
      children: [
        Slider(
          min: 0,
          max: maxMs <= 0 ? 1 : maxMs,
          value: maxMs <= 0 ? 0 : value.clamp(0.0, maxMs),
          onChanged: maxMs <= 0 ? null : onChanged,
          onChangeEnd: maxMs <= 0 ? null : onChangeEnd,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatClock(
                  Duration(milliseconds: (dragValue ?? posMs).round()),
                ),
              ),
              Text(
                formatClock(remaining.isNegative ? Duration.zero : remaining),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Controls extends ConsumerWidget {
  final PlaybackController controller;
  const _Controls({required this.controller});

  static IconData _rewindIcon(int s) => switch (s) {
    5 => Icons.replay_5,
    10 => Icons.replay_10,
    30 => Icons.replay_30,
    _ => Icons.fast_rewind,
  };

  static IconData _forwardIcon(int s) => switch (s) {
    5 => Icons.forward_5,
    10 => Icons.forward_10,
    30 => Icons.forward_30,
    _ => Icons.fast_forward,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider).value;
    final playing = playerState?.playing ?? false;
    final processing = playerState?.processingState;
    final buffering =
        processing == ProcessingState.loading ||
        processing == ProcessingState.buffering;
    final skip = ref.watch(playbackSettingsProvider).value;
    final backSecs = skip?.backwardSeconds ?? 30;
    final fwdSecs = skip?.forwardSeconds ?? 30;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SkipButton(
          icon: _rewindIcon(backSecs),
          seconds: backSecs,
          onSkip: controller.skipBackward,
          onChoose: () =>
              _chooseSkip(context, ref, forward: false, current: backSecs),
        ),
        SizedBox(
          width: 72,
          height: 72,
          child: buffering
              ? const Center(child: CircularProgressIndicator())
              : IconButton(
                  iconSize: 64,
                  icon: Icon(
                    playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  onPressed: controller.togglePlayPause,
                ),
        ),
        _SkipButton(
          icon: _forwardIcon(fwdSecs),
          seconds: fwdSecs,
          onSkip: controller.skipForward,
          onChoose: () =>
              _chooseSkip(context, ref, forward: true, current: fwdSecs),
        ),
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  final IconData icon;
  final int seconds;
  final VoidCallback onSkip;
  final VoidCallback onChoose;
  const _SkipButton({
    required this.icon,
    required this.seconds,
    required this.onSkip,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onSkip,
      onLongPress: onChoose,
      radius: 38,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38),
            const SizedBox(height: 2),
            Text('${seconds}s', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

Future<void> _chooseSkip(
  BuildContext context,
  WidgetRef ref, {
  required bool forward,
  required int current,
}) async {
  final picked = await showSkipSecondsDialog(
    context,
    title: forward ? 'Skip forward' : 'Skip backward',
    current: current,
  );
  if (picked == null) return;
  final controller = ref.read(playbackSettingsProvider.notifier);
  if (forward) {
    await controller.setForward(picked);
  } else {
    await controller.setBackward(picked);
  }
}

class _SpeedButton extends ConsumerWidget {
  final PlaybackController controller;
  const _SpeedButton({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audioPlayerProvider);
    return StreamBuilder<double>(
      stream: player.speedStream,
      initialData: player.speed,
      builder: (context, snapshot) {
        final speed = snapshot.data ?? 1.0;
        return PopupMenuButton<double>(
          initialValue: speed,
          onSelected: controller.setSpeed,
          itemBuilder: (_) => [
            for (final s in _speeds)
              PopupMenuItem(value: s, child: Text('${s}x')),
          ],
          child: Chip(
            avatar: const Icon(Icons.speed, size: 18),
            label: Text('${speed}x'),
          ),
        );
      },
    );
  }
}

class _SleepButton extends ConsumerWidget {
  final bool sleepActive;
  const _SleepButton({required this.sleepActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playbackControllerProvider.notifier);
    return PopupMenuButton<int>(
      tooltip: 'Sleep timer',
      icon: Icon(sleepActive ? Icons.bedtime : Icons.bedtime_outlined),
      onSelected: (v) {
        final String message;
        if (v == 0) {
          controller.cancelSleep();
          message = 'Sleep timer off';
        } else if (v == -1) {
          controller.setSleepAtEndOfEpisode();
          message = 'Will stop at end of episode';
        } else {
          controller.setSleepTimer(Duration(minutes: v));
          message = 'Sleep timer: $v min';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
      itemBuilder: (_) => [
        if (sleepActive) const PopupMenuItem(value: 0, child: Text('Turn off')),
        for (final m in const [5, 15, 30, 45, 60])
          PopupMenuItem(value: m, child: Text('$m minutes')),
        const PopupMenuItem(value: -1, child: Text('End of episode')),
      ],
    );
  }
}
