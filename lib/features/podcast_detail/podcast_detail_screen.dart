import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/db/database.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../../util/format.dart';
import '../downloads/download_button.dart';
import '../player/mini_player.dart';
import 'episode_detail_sheet.dart';

class PodcastDetailScreen extends ConsumerWidget {
  final int podcastId;
  const PodcastDetailScreen({super.key, required this.podcastId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podcastAsync = ref.watch(podcastProvider(podcastId));
    final episodesAsync = ref.watch(episodesProvider(podcastId));

    final podcast = podcastAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(podcast?.title ?? 'Podcast'),
        actions: [
          if (podcast != null)
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final link = (podcast.link != null && podcast.link!.isNotEmpty)
                    ? podcast.link!
                    : podcast.feedUrl;
                SharePlus.instance.share(
                  ShareParams(
                    text: '${podcast.title}\n$link',
                    subject: podcast.title,
                  ),
                );
              },
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              final dao = ref.read(databaseProvider).episodeDao;
              if (value == 'played') {
                dao.setAllPlayed(podcastId, true);
              } else if (value == 'unplayed') {
                dao.setAllPlayed(podcastId, false);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'played', child: Text('Mark all as played')),
              PopupMenuItem(
                value: 'unplayed',
                child: Text('Mark all as unplayed'),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(useSafeArea: true),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.read(podcastRepositoryProvider).refresh(podcastId);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
            }
          }
        },
        child: CustomScrollView(
          slivers: [
            if (podcast != null)
              SliverToBoxAdapter(child: _Header(podcast: podcast)),
            episodesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  SliverFillRemaining(child: Center(child: Text('Error: $e'))),
              data: (episodes) {
                if (episodes.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No episodes')),
                  );
                }
                return SliverList.separated(
                  itemCount: episodes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      _EpisodeTile(episode: episodes[i], podcast: podcast),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final Podcast podcast;
  const _Header({required this.podcast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasImage = podcast.imageUrl != null && podcast.imageUrl!.isNotEmpty;

    const subscribeShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
    );
    final subscribeButton = podcast.subscribed
        ? FilledButton.tonalIcon(
            onPressed: () =>
                ref.read(podcastRepositoryProvider).unsubscribe(podcast.id),
            style: FilledButton.styleFrom(
              shape: subscribeShape,
              backgroundColor: const Color(0xFF4D4D4D),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Subscribed'),
          )
        : FilledButton.icon(
            onPressed: () =>
                ref.read(podcastRepositoryProvider).resubscribe(podcast.id),
            style: FilledButton.styleFrom(shape: subscribeShape),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Subscribe'),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Blurred cover band with a clear bottom edge; the subscribe button
        // sits on that edge, flush to the right screen edge.
        Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 26,
                          sigmaY: 26,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: podcast.imageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 250,
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    // Light scrim: keep the cover's colour, just enough for text.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.black.withValues(alpha: 0.50),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 104,
                      height: 104,
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: podcast.imageUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 320,
                              errorWidget: (_, _, _) =>
                                  const Icon(Icons.podcasts, size: 40),
                            )
                          : const ColoredBox(
                              color: Colors.black26,
                              child: Icon(Icons.podcasts, size: 40),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          podcast.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (podcast.author != null &&
                            podcast.author!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              podcast.author!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(right: 0, bottom: 0, child: subscribeButton),
          ],
        ),
        const SizedBox(height: 14),
        if (podcast.description != null && podcast.description!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              stripHtml(podcast.description),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
        ],
        const Divider(height: 1),
      ],
    );
  }
}

class _EpisodeThumb extends StatelessWidget {
  final String? imageUrl;
  final bool unplayed;
  const _EpisodeThumb({required this.imageUrl, required this.unplayed});

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: Colors.black26,
      child: Icon(Icons.podcasts, size: 22),
    );
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 150,
                      placeholder: (_, _) => placeholder,
                      errorWidget: (_, _, _) => placeholder,
                    )
                  : placeholder,
            ),
          ),
          if (unplayed)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: kAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends ConsumerWidget {
  final Episode episode;
  final Podcast? podcast;
  const _EpisodeTile({required this.episode, required this.podcast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCurrent =
        ref.watch(playbackControllerProvider).episode?.id == episode.id;
    final hasTranscript =
        ref.watch(transcribedEpisodeIdsProvider).value?.contains(episode.id) ??
        false;

    final remainingMs = (episode.durationMs != null && episode.positionMs > 0)
        ? episode.durationMs! - episode.positionMs
        : null;
    final inProgress =
        !episode.isPlayed && remainingMs != null && remainingMs > 0;
    final progress = (episode.durationMs != null && episode.durationMs! > 0)
        ? (episode.positionMs / episode.durationMs!).clamp(0.0, 1.0)
        : 0.0;

    final meta = [
      formatDate(episode.pubDate),
      formatDuration(episode.durationMs),
      formatBytes(episode.sizeBytes),
    ].where((s) => s.isNotEmpty).join('  ·  ');

    Widget thumb = _EpisodeThumb(
      imageUrl: episode.imageUrl ?? podcast?.imageUrl,
      unplayed: !episode.isPlayed,
    );
    if (episode.unavailable) {
      // Desaturate the artwork to signal the episode can't be played.
      thumb = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: thumb,
      );
    }

    return InkWell(
      onTap: () =>
          showEpisodeDetailSheet(context, episode: episode, podcast: podcast),
      child: Stack(
        children: [
          if (isCurrent)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(width: 3, child: ColoredBox(color: kAccent)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                thumb,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? scheme.primary
                              : (episode.isPlayed || episode.unavailable
                                    ? theme.disabledColor
                                    : null),
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          meta,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (hasTranscript) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kAccent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.article,
                                size: 13,
                                color: kAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Transcript',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: kAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (episode.unavailable) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Unavailable',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ] else if (episode.isPlayed) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Played',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ] else if (inProgress) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatDuration(remainingMs)} left',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                DownloadButton(episode: episode),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Luminance-weighted matrix that renders an image in greyscale.
const _grayscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];
