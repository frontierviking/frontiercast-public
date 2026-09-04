import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/db/database.dart';

/// Moving to a new phone, or keeping a safety copy.
///
/// The app has no cloud sync — everything lives in one SQLite file on the
/// device — so a phone swap needs either a full database copy (keeps played
/// state, positions, transcripts and the manual library order) or an OPML file
/// (subscriptions only, but readable by any podcast app).
class BackupService {
  final AppDatabase db;
  BackupService(this.db);

  String _stamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  /// Writes a consistent snapshot of the whole database to a shareable file.
  ///
  /// Uses `VACUUM INTO` rather than copying the file: the live database has
  /// WAL sidecars holding committed pages, so a raw copy can be missing recent
  /// writes. VACUUM INTO produces one self-contained, consistent file.
  Future<File> exportDatabase() async {
    final dir = await getTemporaryDirectory();
    final out = File(p.join(dir.path, 'frontiercast-backup-${_stamp()}.sqlite'));
    if (await out.exists()) await out.delete();
    // Path is interpolated into SQL, so escape single quotes.
    final escaped = out.path.replaceAll("'", "''");
    await db.customStatement("VACUUM INTO '$escaped'");
    return out;
  }

  /// Stages a picked backup to be swapped in on next launch. Returns the
  /// staged file. The caller must tell the user to restart the app — the swap
  /// happens in the database's open path, before SQLite touches anything.
  Future<File> stageRestore(File picked) async {
    final dir = await getApplicationDocumentsDirectory();
    final staged = File(p.join(dir.path, kPendingRestoreFile));
    await picked.copy(staged.path);
    return staged;
  }

  /// Writes the current subscriptions as an OPML file.
  Future<File> exportOpml() async {
    final podcasts = await db.podcastDao.getAll();
    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<opml version="2.0">')
      ..writeln('  <head><title>FrontierCast subscriptions</title></head>')
      ..writeln('  <body>');
    for (final pod in podcasts) {
      final title = _xmlAttr(pod.title);
      final feed = _xmlAttr(pod.feedUrl);
      final site = _xmlAttr(pod.link ?? pod.feedUrl);
      buf.writeln(
        '    <outline text="$title" title="$title" type="rss" '
        'xmlUrl="$feed" htmlUrl="$site" />',
      );
    }
    buf
      ..writeln('  </body>')
      ..writeln('</opml>');

    final dir = await getTemporaryDirectory();
    final out = File(p.join(dir.path, 'frontiercast-subscriptions-${_stamp()}.opml'));
    await out.writeAsString(buf.toString());
    return out;
  }

  /// Counts for the confirmation UI.
  Future<({int podcasts, int episodes, int transcripts})> stats() async {
    Future<int> count(String table) async {
      final row = await db
          .customSelect('SELECT COUNT(*) AS c FROM $table')
          .getSingle();
      return row.read<int>('c');
    }

    final subs = await db.podcastDao.getAll();
    return (
      podcasts: subs.length,
      episodes: await count('episodes'),
      transcripts: await count('transcripts'),
    );
  }
}

String _xmlAttr(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
