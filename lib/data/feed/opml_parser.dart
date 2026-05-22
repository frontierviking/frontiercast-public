import 'package:xml/xml.dart';

class OpmlEntry {
  final String title;
  final String feedUrl;
  OpmlEntry(this.title, this.feedUrl);
}

/// Parses an OPML subscription export (e.g. from Castbox) into feed entries,
/// de-duplicating by feed URL.
List<OpmlEntry> parseOpml(String xmlString) {
  final doc = XmlDocument.parse(xmlString);
  final entries = <OpmlEntry>[];
  final seen = <String>{};
  for (final outline in doc.findAllElements('outline')) {
    final xmlUrl =
        outline.getAttribute('xmlUrl') ?? outline.getAttribute('xmlurl');
    if (xmlUrl == null || xmlUrl.trim().isEmpty) continue;
    final url = xmlUrl.trim();
    if (!seen.add(url)) continue;
    final title =
        (outline.getAttribute('title') ?? outline.getAttribute('text') ?? url)
            .trim();
    entries.add(OpmlEntry(title, url));
  }
  return entries;
}
