/// A podcast search hit from any source (iTunes, Podcast Index, …).
class PodcastSearchResult {
  final String title;
  final String? author;
  final String feedUrl;
  final String? artworkUrl;

  const PodcastSearchResult({
    required this.title,
    this.author,
    required this.feedUrl,
    this.artworkUrl,
  });
}
