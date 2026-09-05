import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../providers.dart';
import 'now_playing_screen.dart';

/// Persistent bottom bar: the single play/pause control whenever an episode is
/// loaded. Tapping it opens the full-screen player.
class MiniPlayer extends ConsumerWidget {
  /// Add bottom padding for the system navigation inset. Needed when the
  /// MiniPlayer is the bottom-most widget (e.g. a screen's bottomNavigationBar);
  /// not needed in HomeShell where the NavigationBar below it absorbs the inset.
  final bool useSafeArea;
  const MiniPlayer({super.key, this.useSafeArea = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackControllerProvider);
    final episode = playback.episode;
    if (episode == null) return const SizedBox.shrink();

    final podcast = playback.podcast;
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(playbackControllerProvider.notifier);

    final playerState = ref.watch(playerStateProvider).value;
    final playing = playerState?.playing ?? false;
    final processing = playerState?.processingState;
    final buffering =
        processing == ProcessingState.loading ||
        processing == ProcessingState.buffering;

    // An episode restored at launch has no live position stream yet — its audio
    // is only opened on the first play — so fall back to the position stored on
    // the episode, or the bar would read zero for something half-listened.
    final posData = ref.watch(positionDataProvider).value;
    final liveDurationMs = posData?.duration.inMilliseconds ?? 0;
    final savedDurationMs = episode.durationMs ?? 0;
    final progress = liveDurationMs > 0
        ? posData!.position.inMilliseconds / liveDurationMs
        : (savedDurationMs > 0 ? episode.positionMs / savedDurationMs : 0.0);

    final bottomInset = useSafeArea ? MediaQuery.paddingOf(context).bottom : 0.0;

    return Material(
      color: scheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
          rootNavigator: true,
        ).push(MaterialPageRoute(builder: (_) => const NowPlayingScreen())),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: Colors.transparent,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8, 6, 8, 6 + bottomInset),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child:
                          (podcast?.imageUrl != null &&
                              podcast!.imageUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: podcast.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) =>
                                  const Icon(Icons.podcasts),
                            )
                          : const Icon(Icons.podcasts),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          episode.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (podcast != null)
                          Text(
                            podcast.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: buffering
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            iconSize: 32,
                            icon: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                            ),
                            onPressed: controller.togglePlayPause,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
