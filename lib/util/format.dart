String formatDuration(int? ms) {
  if (ms == null || ms <= 0) return '';
  final totalSeconds = ms ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

final _htmlTagRe = RegExp(r'<[^>]*>');
final _spacesRe = RegExp(r'[ \t]+');
final _blankLinesRe = RegExp(r'\n\s*\n\s*\n+');

/// Strips HTML tags and decodes common entities so feed descriptions /
/// show notes render as readable plain text.
String stripHtml(String? html) {
  if (html == null || html.isEmpty) return '';
  var s = html
      .replaceAll('</p>', '\n\n')
      .replaceAll('<br>', '\n')
      .replaceAll('<br/>', '\n')
      .replaceAll('<br />', '\n');
  s = s.replaceAll(_htmlTagRe, '');
  s = s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&hellip;', '…')
      .replaceAll('&mdash;', '—')
      .replaceAll('&ndash;', '–');
  s = s.replaceAll(_spacesRe, ' ');
  s = s.replaceAll(_blankLinesRe, '\n\n');
  return s.trim();
}

String formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var u = 0;
  while (size >= 1024 && u < units.length - 1) {
    size /= 1024;
    u++;
  }
  final value = (size >= 100 || u == 0)
      ? size.toStringAsFixed(0)
      : size.toStringAsFixed(1);
  return '$value ${units[u]}';
}

/// Formats a duration as a clock: m:ss, or h:mm:ss when an hour or longer.
String formatClock(Duration d) {
  final neg = d.isNegative;
  final v = d.abs();
  final h = v.inHours;
  final m = v.inMinutes % 60;
  final s = v.inSeconds % 60;
  final ss = s.toString().padLeft(2, '0');
  final base = h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
  return neg ? '-$base' : base;
}

String formatDate(DateTime? date) {
  if (date == null) return '';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
