import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../podcast_detail/podcast_detail_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryWithCountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: library.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          if (all.isEmpty) return const _EmptyLibrary();
          final q = _query.trim().toLowerCase();
          final podcasts = q.isEmpty
              ? all
              : all
                    .where((p) => p.podcast.title.toLowerCase().contains(q))
                    .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: SearchBar(
                  controller: _controller,
                  hintText: 'Filter library',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: podcasts.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: Text('No matches'),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 14,
                            ),
                        itemCount: podcasts.length,
                        itemBuilder: (context, i) => _PodcastTile(
                          podcast: podcasts[i].podcast,
                          unplayed: podcasts[i].unplayed,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PodcastTile extends StatelessWidget {
  final Podcast podcast;
  final int unplayed;
  const _PodcastTile({required this.podcast, this.unplayed = 0});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PodcastDetailScreen(podcastId: podcast.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _Artwork(url: podcast.imageUrl),
                  ),
                ),
                if (unplayed > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: _UnplayedBadge(count: unplayed),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Flexible(
            child: Text(
              podcast.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final String? url;
  const _Artwork({this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.podcasts, size: 40),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      // Decode at grid size so 90+ covers stay in the memory cache instead of
      // being evicted and re-decoded (the "reloading" flash) on every rebuild.
      memCacheWidth: 240,
      fadeInDuration: Duration.zero,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class _UnplayedBadge extends StatelessWidget {
  final int count;
  const _UnplayedBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 18),
      decoration: BoxDecoration(
        color: kAccent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black26, width: 0.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_music_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'No subscriptions yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Use Search to find podcasts, or import your Castbox '
              'subscriptions from Settings.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
