import 'package:dart_rss/dart_rss.dart';
import 'package:http/http.dart' as http;

class ParsedEpisode {
  final String guid;
  final String title;
  final String? showNotes;
  final String audioUrl;
  final String? imageUrl;
  final String? link;
  final int? durationMs;
  final int? sizeBytes;
  final DateTime? pubDate;

  ParsedEpisode({
    required this.guid,
    required this.title,
    this.showNotes,
    required this.audioUrl,
    this.imageUrl,
    this.link,
    this.durationMs,
    this.sizeBytes,
    this.pubDate,
  });
}

class ParsedFeed {
  final String title;
  final String? imageUrl;
  final String? author;
  final String? description;
  final String? link;
  final List<ParsedEpisode> episodes;

  ParsedFeed({
    required this.title,
    this.imageUrl,
    this.author,
    this.description,
    this.link,
    required this.episodes,
  });
}

class FeedException implements Exception {
  final String message;
  FeedException(this.message);
  @override
  String toString() => message;
}

/// Fetches and parses an RSS podcast feed (iTunes/podcast namespaces included).
class FeedParser {
  final http.Client _client;
  FeedParser([http.Client? client]) : _client = client ?? http.Client();

  Future<ParsedFeed> fetchAndParse(String feedUrl) async {
    final http.Response resp;
    try {
      resp = await _client
          .get(
            Uri.parse(feedUrl),
            headers: const {'User-Agent': 'FrontierCast/1.0 (+podcast)'},
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw FeedException('Network error: $e');
    }
    if (resp.statusCode != 200) {
      throw FeedException('HTTP ${resp.statusCode} fetching feed');
    }

    final RssFeed feed;
    try {
      feed = RssFeed.parse(resp.body);
    } catch (e) {
      throw FeedException('Could not parse feed: $e');
    }

    final episodes = <ParsedEpisode>[];
    for (final item in feed.items) {
      final audioUrl = item.enclosure?.url;
      if (audioUrl == null || audioUrl.isEmpty) continue; // not playable
      final guid = (item.guid != null && item.guid!.isNotEmpty)
          ? item.guid!
          : audioUrl;
      final length = item.enclosure?.length;
      episodes.add(
        ParsedEpisode(
          guid: guid,
          title: item.title?.trim() ?? '(untitled)',
          showNotes:
              item.content?.value ?? item.description ?? item.itunes?.summary,
          audioUrl: audioUrl,
          imageUrl: _episodeImage(item),
          link: item.link,
          durationMs: item.itunes?.duration?.inMilliseconds,
          sizeBytes: (length != null && length > 0) ? length : null,
          pubDate: _parseDate(item.pubDate),
        ),
      );
    }

    return ParsedFeed(
      title: feed.title?.trim().isNotEmpty == true
          ? feed.title!.trim()
          : feedUrl,
      imageUrl: feed.itunes?.image?.href ?? feed.image?.url,
      author: feed.itunes?.author ?? feed.author,
      description: feed.description ?? feed.itunes?.summary,
      link: feed.link,
      episodes: episodes,
    );
  }
}

const _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

String? _episodeImage(RssItem item) {
  final itunes = item.itunes?.image?.href;
  if (itunes != null && itunes.isNotEmpty) return itunes;
  final media = item.media;
  if (media != null) {
    for (final t in media.thumbnails) {
      if (t.url != null && t.url!.isNotEmpty) return t.url;
    }
    for (final c in media.contents) {
      if (c.medium == 'image' && c.url != null && c.url!.isNotEmpty) {
        return c.url;
      }
    }
  }
  return null;
}

DateTime? _parseDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim();
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso.toLocal();
  return _parseRfc822(s);
}

/// Parses RFC-822 dates like "Wed, 15 May 2026 14:13:13 +0000".
DateTime? _parseRfc822(String input) {
  var s = input;
  final comma = s.indexOf(',');
  if (comma != -1) s = s.substring(comma + 1).trim();
  final parts = s.split(RegExp(r'\s+'));
  if (parts.length < 4) return null;
  final day = int.tryParse(parts[0]);
  final month =
      _months[parts[1].toLowerCase().substring(
        0,
        parts[1].length < 3 ? parts[1].length : 3,
      )];
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  final time = parts[3].split(':');
  final hour = int.tryParse(time[0]) ?? 0;
  final minute = time.length > 1 ? int.tryParse(time[1]) ?? 0 : 0;
  final second = time.length > 2 ? int.tryParse(time[2]) ?? 0 : 0;
  final offset = parts.length >= 5 ? _parseTz(parts[4]) : Duration.zero;
  final utc = DateTime.utc(
    year,
    month,
    day,
    hour,
    minute,
    second,
  ).subtract(offset);
  return utc.toLocal();
}

Duration _parseTz(String tz) {
  switch (tz.toUpperCase()) {
    case 'GMT':
    case 'UT':
    case 'UTC':
    case 'Z':
      return Duration.zero;
    case 'EST':
      return const Duration(hours: -5);
    case 'EDT':
      return const Duration(hours: -4);
    case 'CST':
      return const Duration(hours: -6);
    case 'CDT':
      return const Duration(hours: -5);
    case 'MST':
      return const Duration(hours: -7);
    case 'MDT':
      return const Duration(hours: -6);
    case 'PST':
      return const Duration(hours: -8);
    case 'PDT':
      return const Duration(hours: -7);
  }
  final m = RegExp(r'^([+-])(\d{2}):?(\d{2})$').firstMatch(tz);
  if (m != null) {
    final sign = m.group(1) == '-' ? -1 : 1;
    final h = int.parse(m.group(2)!);
    final mm = int.parse(m.group(3)!);
    return Duration(hours: sign * h, minutes: sign * mm);
  }
  return Duration.zero;
}
