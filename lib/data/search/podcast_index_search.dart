import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'podcast_search.dart';

/// Client over the Podcast Index API (https://podcastindex.org).
///
/// Auth is per-request: the Authorization header is the SHA-1 of
/// (apiKey + apiSecret + unixSeconds), sent alongside the key and timestamp.
class PodcastIndexSearch {
  final http.Client _client;
  PodcastIndexSearch([http.Client? client]) : _client = client ?? http.Client();

  Future<List<PodcastSearchResult>> search(
    String term, {
    required String apiKey,
    required String apiSecret,
    int limit = 25,
  }) async {
    final q = term.trim();
    if (q.isEmpty || apiKey.isEmpty || apiSecret.isEmpty) return [];

    final authDate = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final authHeader = sha1
        .convert(utf8.encode('$apiKey$apiSecret$authDate'))
        .toString();

    final uri = Uri.https('api.podcastindex.org', '/api/1.0/search/byterm', {
      'q': q,
      'max': '$limit',
    });
    final resp = await _client
        .get(
          uri,
          headers: {
            'User-Agent': 'FrontierCast/1.0',
            'X-Auth-Date': authDate,
            'X-Auth-Key': apiKey,
            'Authorization': authHeader,
          },
        )
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) {
      throw Exception('Podcast Index search failed: HTTP ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final feeds = (data['feeds'] as List?) ?? const [];
    return feeds
        .cast<Map<String, dynamic>>()
        .map(
          (m) => PodcastSearchResult(
            title: (m['title'] ?? '') as String,
            author: m['author'] as String?,
            feedUrl: (m['url'] ?? '') as String,
            artworkUrl: (m['artwork'] ?? m['image']) as String?,
          ),
        )
        .where((p) => p.feedUrl.isNotEmpty)
        .toList();
  }
}
