import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../providers.dart';
import '../../services/transcribe_controller.dart';
import '../../theme.dart';
import '../../util/format.dart';
import '../podcast_detail/episode_detail_sheet.dart';
import 'download_button.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadingAsync = ref.watch(downloadingProvider);
    final downloadedAsync = ref.watch(downloadedProvider);
    final progressMap = ref.watch(downloadControllerProvider);
    final transcribing = ref.watch(transcribeControllerProvider).values.toList();

    final downloading = downloadingAsync.value ?? const [];
    final downloaded = downloadedAsync.value ?? const [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: Builder(
        builder: (context) {
          if (downloadingAsync.isLoading &&
              downloadedAsync.isLoading &&
              downloading.isEmpty &&
              downloaded.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (downloading.isEmpty &&
              downloaded.isEmpty &&
              transcribing.isEmpty) {
            return _EmptyDownloads(theme: theme);
          }

          final totalBytes = downloaded.fold<int>(
            0,
            (sum, it) => sum + (it.episode.sizeBytes ?? 0),
          );
          final sizeLabel = formatBytes(totalBytes);

          return CustomScrollView(
            slivers: [
              if (transcribing.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    'Transcribing (${transcribing.length})',
                  ),
                ),
                SliverList.separated(
                  itemCount: transcribing.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _TranscribingRow(job: transcribing[i]),
                ),
              ],
              if (downloading.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader('Downloading (${downloading.length})'),
                ),
                SliverList.separated(
                  itemCount: downloading.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _DownloadingRow(
                    episode: downloading[i].episode,
                    podcast: downloading[i].podcast,
                    progress: progressMap[downloading[i].episode.id],
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: _SectionHeader(
                  downloaded.isEmpty
                      ? 'Downloaded'
                      : 'Downloaded · ${downloaded.length}'
                            '${sizeLabel.isNotEmpty ? '  ·  $sizeLabel' : ''}',
                ),
              ),
              if (downloaded.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Nothing downloaded yet')),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: downloaded.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _DownloadedRow(
                    episode: downloaded[i].episode,
                    podcast: downloaded[i].podcast,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final String? url;
  const _Artwork({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 52,
        height: 52,
        child: (url != null && url!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const Icon(Icons.podcasts),
              )
            : const Icon(Icons.podcasts),
      ),
    );
  }
}

class _TranscribingRow extends ConsumerWidget {
  final TranscribeJob job;
  const _TranscribingRow({required this.job});

  ({String label, double? value}) _status() => switch (job.stage) {
    'queued' => (label: 'Queued', value: 0),
    'downloading' => (
      label: job.progress > 0
          ? 'Downloading ${(job.progress * 100).round()}%'
          : 'Downloading…',
      value: job.progress > 0 ? job.progress : null,
    ),
    'transcribing' => (
      label: 'Transcribing ${(job.progress * 100).round()}%',
      value: job.progress > 0 ? job.progress : null,
    ),
    'waiting' => (label: 'Finishing on Mac…', value: null),
    _ => (label: 'Starting…', value: null),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = _status();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          _Artwork(url: job.podcast?.imageUrl ?? job.episode.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.article_outlined, size: 13, color: kAccent),
                    const SizedBox(width: 4),
                    Text(
                      s.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: kAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: s.value,
                    minHeight: 5,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: job.isQueued ? 'Remove from queue' : 'Cancel',
            icon: const Icon(Icons.close),
            onPressed: () => ref
                .read(transcribeControllerProvider.notifier)
                .cancel(job.episode.id),
          ),
        ],
      ),
    );
  }
}

class _DownloadingRow extends StatelessWidget {
  final Episode episode;
  final Podcast podcast;
  final double? progress;

  const _DownloadingRow({
    required this.episode,
    required this.podcast,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          _Artwork(url: podcast.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  podcast.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      progress != null
                          ? '${(progress! * 100).round()}%'
                          : 'starting…',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          DownloadButton(episode: episode),
        ],
      ),
    );
  }
}

class _DownloadedRow extends ConsumerWidget {
  final Episode episode;
  final Podcast podcast;

  const _DownloadedRow({required this.episode, required this.podcast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.read(downloadControllerProvider.notifier);
    return Dismissible(
      key: ValueKey('downloaded-${episode.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) async {
        await downloads.delete(episode);
        if (!context.mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Removed "${episode.title}"'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => downloads.download(episode),
              ),
            ),
          );
      },
      child: ListTile(
        leading: _Artwork(url: podcast.imageUrl),
        title: Text(
          episode.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            podcast.title,
            formatBytes(episode.sizeBytes),
          ].where((s) => s.isNotEmpty).join('  ·  '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => showEpisodeDetailSheet(
          context,
          episode: episode,
          podcast: podcast,
        ),
        trailing: DownloadButton(episode: episode),
      ),
    );
  }
}

class _EmptyDownloads extends StatelessWidget {
  final ThemeData theme;
  const _EmptyDownloads({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_for_offline_outlined, size: 64),
            const SizedBox(height: 16),
            Text('No downloads yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tap the download icon on any episode to save it for '
              'offline listening.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
