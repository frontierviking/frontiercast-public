import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/db/database.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../../util/format.dart';
import '../downloads/download_button.dart';
import '../player/now_playing_screen.dart';
import '../transcript/transcript_screen.dart';

Future<void> showEpisodeDetailSheet(
  BuildContext context, {
  required Episode episode,
  required Podcast? podcast,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) =>
        EpisodeDetailSheet(initialEpisode: episode, podcast: podcast),
  );
}

class EpisodeDetailSheet extends ConsumerWidget {
  final Episode initialEpisode;
  final Podcast? podcast;

  const EpisodeDetailSheet({
    super.key,
    required this.initialEpisode,
    required this.podcast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode =
        ref.watch(episodeProvider(initialEpisode.id)).value ?? initialEpisode;
    final theme = Theme.of(context);
    final notes = stripHtml(episode.showNotes);

    final remainingMs = (episode.durationMs != null && episode.positionMs > 0)
        ? episode.durationMs! - episode.positionMs
        : null;
    final meta = <Widget>[
      if (episode.pubDate != null)
        _MetaPill(
          icon: Icons.event_outlined,
          label: formatDate(episode.pubDate),
        ),
      if (formatDuration(episode.durationMs).isNotEmpty)
        _MetaPill(
          icon: Icons.schedule_outlined,
          label: formatDuration(episode.durationMs),
        ),
      if (formatBytes(episode.sizeBytes).isNotEmpty)
        _MetaPill(
          icon: Icons.sd_storage_outlined,
          label: formatBytes(episode.sizeBytes),
        ),
    ];

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child:
                        (podcast?.imageUrl != null &&
                            podcast!.imageUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: podcast!.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) =>
                                const Icon(Icons.podcasts),
                          )
                        : const ColoredBox(
                            color: Colors.black26,
                            child: Icon(Icons.podcasts),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (podcast != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          podcast!.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (meta.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Wrap(spacing: 8, runSpacing: 8, children: meta),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 16, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: episode.isPlayed
                      ? 'Mark as unplayed'
                      : 'Mark as played',
                  onPressed: () => ref
                      .read(databaseProvider)
                      .episodeDao
                      .setPlayed(episode.id, !episode.isPlayed),
                  icon: Icon(
                    episode.isPlayed
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                  ),
                ),
                IconButton(
                  tooltip: 'Transcript',
                  onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TranscriptScreen(episode: episode, podcast: podcast),
                      ),
                    );
                  },
                  icon: Icon(
                    ref.watch(transcriptProvider(episode.id)).value != null
                        ? Icons.article
                        : Icons.article_outlined,
                  ),
                ),
                IconButton(
                  tooltip: 'Share',
                  onPressed: () {
                    final link =
                        (episode.link != null && episode.link!.isNotEmpty)
                        ? episode.link!
                        : episode.audioUrl;
                    SharePlus.instance.share(
                      ShareParams(
                        text: '${episode.title}\n$link',
                        subject: episode.title,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined),
                ),
                DownloadButton(episode: episode),
                Builder(
                  builder: (context) {
                    final queued =
                        ref
                            .watch(queueProvider)
                            .value
                            ?.any((q) => q.episode.id == episode.id) ??
                        false;
                    return IconButton(
                      tooltip: queued ? 'Remove from queue' : 'Add to queue',
                      onPressed: () async {
                        final dao = ref.read(databaseProvider).queueDao;
                        if (queued) {
                          await dao.remove(episode.id);
                        } else {
                          await dao.add(episode.id);
                        }
                      },
                      icon: Icon(
                        queued ? Icons.playlist_add_check : Icons.playlist_add,
                        color: queued ? kAccent : null,
                      ),
                    );
                  },
                ),
                const Spacer(),
                // Big circular play arrow → start (or resume) and open the
                // Now Playing screen directly.
                Material(
                  color: kAccent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: podcast == null
                        ? null
                        : () {
                            final nav = Navigator.of(context);
                            nav.pop();
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => const NowPlayingScreen(),
                              ),
                            );
                            ref
                                .read(playbackControllerProvider.notifier)
                                .playEpisode(episode, podcast!)
                                .catchError((_) {});
                          },
                    child: const Padding(
                      padding: EdgeInsets.all(13),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (remainingMs != null && remainingMs > 0 && !episode.isPlayed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${formatDuration(remainingMs)} left',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Text(
                      'No description',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Scrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: SelectableText(
                        notes,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
