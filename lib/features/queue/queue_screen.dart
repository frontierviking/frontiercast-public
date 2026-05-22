import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueProvider).value ?? const [];
    final db = ref.read(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Up Next'),
        actions: [
          if (queue.isNotEmpty)
            IconButton(
              tooltip: 'Clear queue',
              icon: const Icon(Icons.clear_all),
              onPressed: () => db.queueDao.clear(),
            ),
        ],
      ),
      body: queue.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Queue is empty.\nAdd episodes with "Add to queue".',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ReorderableListView.builder(
              itemCount: queue.length,
              onReorderItem: (fromIndex, toIndex) {
                final ids = queue.map((q) => q.episode.id).toList();
                final id = ids.removeAt(fromIndex);
                ids.insert(toIndex, id);
                db.queueDao.setOrder(ids);
              },
              itemBuilder: (context, i) {
                final episode = queue[i].episode;
                final podcast = queue[i].podcast;
                return ListTile(
                  key: ValueKey(episode.id),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child:
                          (podcast.imageUrl != null &&
                              podcast.imageUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: podcast.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) =>
                                  const Icon(Icons.podcasts),
                            )
                          : const Icon(Icons.podcasts),
                    ),
                  ),
                  title: Text(
                    episode.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    podcast.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    ref
                        .read(playbackControllerProvider.notifier)
                        .playEpisode(episode, podcast)
                        .catchError((_) {});
                    db.queueDao.remove(episode.id);
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.close),
                        onPressed: () => db.queueDao.remove(episode.id),
                      ),
                      ReorderableDragStartListener(
                        index: i,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8, left: 4),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
