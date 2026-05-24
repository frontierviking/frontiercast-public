import 'dart:convert';

import 'package:http/http.dart' as http;

import 'podcast_search.dart';

/// Thin client over the public iTunes Search API (no key required).
class ItunesSearch {
  final http.Client _client;
  ItunesSearch([http.Client? client]) : _client = client ?? http.Client();

  Future<List<PodcastSearchResult>> search(String term, {int limit = 25}) async {
    final q = term.trim();
    if (q.isEmpty) return [];
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': q,
      'media': 'podcast',
      'entity': 'podcast',
      'limit': '$limit',
    });
    final resp = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) {
      throw Exception('iTunes search failed: HTTP ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? const [];
    return results
        .cast<Map<String, dynamic>>()
        .map(
          (m) => PodcastSearchResult(
            title: (m['collectionName'] ?? m['trackName'] ?? '') as String,
            author: m['artistName'] as String?,
            feedUrl: (m['feedUrl'] ?? '') as String,
            artworkUrl:
                (m['artworkUrl600'] ?? m['artworkUrl100'] ?? m['artworkUrl60'])
                    as String?,
          ),
        )
        .where((p) => p.feedUrl.isNotEmpty)
        .toList();
  }
}
