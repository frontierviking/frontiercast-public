import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/feed/feed_parser.dart';
import '../../data/search/podcast_search.dart';
import '../../providers.dart';

/// True when the text is an absolute http(s) URL — treated as a feed address
/// to subscribe to directly, covering podcasts not in the iTunes catalog.
bool _looksLikeFeedUrl(String s) {
  final u = Uri.tryParse(s.trim());
  return u != null &&
      (u.scheme == 'http' || u.scheme == 'https') &&
      u.host.isNotEmpty;
}

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
              hintText: 'Search, or paste an RSS feed URL',
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
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Search the iTunes catalog, or paste an RSS feed URL '
                        'to add a podcast that isn’t listed (e.g. a '
                        'members-only feed).',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _looksLikeFeedUrl(_query)
                ? _FeedUrlResult(key: ValueKey(_query), url: _query.trim())
                : _Results(query: _query),
          ),
        ],
      ),
    );
  }
}

/// Previews a pasted feed URL (fetch + parse) and lets the user subscribe to
/// it directly — the universal fallback for podcasts not in iTunes.
class _FeedUrlResult extends ConsumerStatefulWidget {
  final String url;
  const _FeedUrlResult({super.key, required this.url});

  @override
  ConsumerState<_FeedUrlResult> createState() => _FeedUrlResultState();
}

class _FeedUrlResultState extends ConsumerState<_FeedUrlResult> {
  late final Future<ParsedFeed> _future = ref
      .read(feedParserProvider)
      .fetchAndParse(widget.url);
  bool _busy = false;

  Future<void> _subscribe(String title) async {
    setState(() => _busy = true);
    try {
      await ref.read(podcastRepositoryProvider).subscribeByFeedUrl(widget.url);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Subscribed to $title')));
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
    final subscribed = ref
        .watch(subscribedFeedUrlsProvider)
        .contains(widget.url);
    return FutureBuilder<ParsedFeed>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Looking up feed…'),
                ],
              ),
            ),
          );
        }
        if (snap.hasError || snap.data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Couldn’t load this feed. Check the URL.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.url,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }
        final feed = snap.data!;
        final art = feed.imageUrl;
        return ListView(
          children: [
            ListTile(
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
                feed.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                feed.author ?? widget.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: _busy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : subscribed
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Subscribe',
                      onPressed: () => _subscribe(feed.title),
                    ),
            ),
          ],
        );
      },
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
  final PodcastSearchResult podcast;
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
