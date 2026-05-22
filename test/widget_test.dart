import 'package:flutter_test/flutter_test.dart';

import 'package:frontiercast/data/feed/opml_parser.dart';

void main() {
  test('parseOpml extracts and de-duplicates feed URLs', () {
    const xml = '''
<opml version="2.0">
  <body>
    <outline text="A" title="A" type="rss" xmlUrl="https://example.com/a.xml" />
    <outline text="B" title="B" type="rss" xmlUrl="https://example.com/b.xml" />
    <outline text="A dup" title="A dup" type="rss" xmlUrl="https://example.com/a.xml" />
  </body>
</opml>
''';
    final entries = parseOpml(xml);
    expect(entries.length, 2);
    expect(entries.first.feedUrl, 'https://example.com/a.xml');
    expect(entries.first.title, 'A');
  });
}
