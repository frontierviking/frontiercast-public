import 'dart:convert';

import 'package:http/http.dart' as http;

class TranscribeException implements Exception {
  final String message;
  TranscribeException(this.message);
  @override
  String toString() => message;
}

/// Client for the Mac transcription server (reached over Tailscale/LAN).
class TranscribeClient {
  final http.Client _client;
  TranscribeClient([http.Client? client]) : _client = client ?? http.Client();

  String _base(String baseUrl) => baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  Future<bool> health(String baseUrl) async {
    try {
      final resp = await _client
          .get(Uri.parse('${_base(baseUrl)}/health'))
          .timeout(const Duration(seconds: 8));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Requests a transcript. The server streams NDJSON progress lines while it
  /// downloads and runs Whisper, then a final line with the text. [onProgress]
  /// receives the transcription fraction (0..1) as it advances.
  Future<String> transcribe({
    required String baseUrl,
    required String token,
    required String audioUrl,
    required String guid,
    String? title,
    String? podcast,
    String? language,
    void Function(String stage, double progress)? onProgress,
  }) async {
    final request = http.Request(
      'POST',
      Uri.parse('${_base(baseUrl)}/transcribe'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'audio_url': audioUrl,
      'guid': guid,
      if (title != null && title.isNotEmpty) 'title': title,
      if (podcast != null && podcast.isNotEmpty) 'podcast': podcast,
      if (language != null && language.isNotEmpty) 'language': language,
    });

    final http.StreamedResponse resp;
    try {
      resp = await _client.send(request).timeout(const Duration(minutes: 3));
    } catch (e) {
      throw TranscribeException('Could not reach the transcription server: $e');
    }
    if (resp.statusCode == 401) {
      throw TranscribeException('Unauthorized — check the server token.');
    }
    if (resp.statusCode != 200) {
      final body = await resp.stream.bytesToString();
      throw TranscribeException('Server error ${resp.statusCode}: $body');
    }

    String? text;
    String? error;
    final lines = resp.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final Map<String, dynamic> obj;
      try {
        obj = jsonDecode(trimmed) as Map<String, dynamic>;
      } catch (_) {
        continue; // ignore any non-JSON keepalive noise
      }
      if (obj['error'] != null) {
        error = obj['error'].toString();
        break;
      }
      if (obj['done'] == true) {
        text = (obj['text'] as String?)?.trim() ?? '';
        break;
      }
      final stage = obj['stage'];
      if (stage == 'downloading' || stage == 'transcribing') {
        final p = obj['progress'];
        onProgress?.call(
          stage as String,
          p is num ? p.toDouble().clamp(0.0, 1.0) : 0.0,
        );
      }
    }

    if (error != null) throw TranscribeException(error);
    if (text == null || text.isEmpty) {
      throw TranscribeException('Empty transcript returned.');
    }
    return text;
  }
}
