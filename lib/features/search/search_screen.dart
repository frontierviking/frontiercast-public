import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/search/itunes_search.dart';
import '../../providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) => setState(() => _query = value.trim());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBar(
              controller: _controller,
              hintText: 'Search podcasts',
              leading: const Icon(Icons.search),
              trailing: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _submit('');
                    },
                  ),
              ],
              onSubmitted: _submit,
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? const Center(child: Text('Search the iTunes catalog'))
                : _Results(query: _query),
          ),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  final String query;
  const _Results({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider(query));
    final subscribed = ref.watch(subscribedFeedUrlsProvider);

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Search failed: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No results'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => _ResultTile(
            podcast: items[i],
            isSubscribed: subscribed.contains(items[i].feedUrl),
          ),
        );
      },
    );
  }
}

class _ResultTile extends ConsumerStatefulWidget {
  final ItunesPodcast podcast;
  final bool isSubscribed;
  const _ResultTile({required this.podcast, required this.isSubscribed});

  @override
  ConsumerState<_ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends ConsumerState<_ResultTile> {
  bool _busy = false;

  Future<void> _subscribe() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(podcastRepositoryProvider)
          .subscribeByFeedUrl(widget.podcast.feedUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscribed to ${widget.podcast.title}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final art = widget.podcast.artworkUrl;
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: (art != null && art.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: art,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const Icon(Icons.podcasts),
                )
              : const Icon(Icons.podcasts),
        ),
      ),
      title: Text(
        widget.podcast.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: widget.podcast.author != null
          ? Text(
              widget.podcast.author!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: _busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.isSubscribed
          ? const Icon(Icons.check_circle, color: Colors.green)
          : IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Subscribe',
              onPressed: _subscribe,
            ),
    );
  }
}
