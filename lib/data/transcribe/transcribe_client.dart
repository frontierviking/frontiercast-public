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

  /// Requests a transcript. Long-running: the server downloads and runs Whisper
  /// synchronously, so allow plenty of time.
  Future<String> transcribe({
    required String baseUrl,
    required String token,
    required String audioUrl,
    required String guid,
    String? title,
    String? podcast,
    String? language,
  }) async {
    final http.Response resp;
    try {
      resp = await _client
          .post(
            Uri.parse('${_base(baseUrl)}/transcribe'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'audio_url': audioUrl,
              'guid': guid,
              if (title != null && title.isNotEmpty) 'title': title,
              if (podcast != null && podcast.isNotEmpty) 'podcast': podcast,
              if (language != null && language.isNotEmpty) 'language': language,
            }),
          )
          .timeout(const Duration(minutes: 30));
    } catch (e) {
      throw TranscribeException('Could not reach the transcription server: $e');
    }
    if (resp.statusCode == 401) {
      throw TranscribeException('Unauthorized — check the server token.');
    }
    if (resp.statusCode != 200) {
      throw TranscribeException(
        'Server error ${resp.statusCode}: ${resp.body}',
      );
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final text = (data['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      throw TranscribeException('Empty transcript returned.');
    }
    return text;
  }
}
