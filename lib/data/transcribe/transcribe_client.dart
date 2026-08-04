import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class TranscribeException implements Exception {
  final String message;
  TranscribeException(this.message);
  @override
  String toString() => message;
}

/// The streaming connection ended (or dropped) before a final transcript
/// arrived. The server keeps working and caches the result, so the caller
/// should poll [TranscribeClient.pollTranscript] rather than treat this as a
/// hard failure.
class TranscribeInterrupted implements Exception {
  const TranscribeInterrupted();
  @override
  String toString() => 'Transcription connection interrupted';
}

/// Client for the Mac transcription server (reached over Tailscale/LAN).
class TranscribeClient {
  final http.Client _client;
  TranscribeClient([http.Client? client]) : _client = client ?? http.Client();

  String _base(String baseUrl) => baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  Future<bool> health(String baseUrl, {Duration? timeout}) async {
    try {
      final resp = await _client
          .get(Uri.parse('${_base(baseUrl)}/health'))
          .timeout(timeout ?? const Duration(seconds: 8));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Scans the phone's own /24 for a host answering /health on [port].
  ///
  /// Home routers hand out new addresses whenever they re-lease, which silently
  /// breaks a hardcoded LAN IP; Android also won't resolve the Mac's `.local`
  /// mDNS name. Sweeping the subnet finds the Mac wherever it landed. Returns
  /// the base URL (e.g. `http://192.168.1.22:8765`) or null if nothing answers.
  Future<String?> discoverOnLan({int port = 8765}) async {
    final prefixes = <String>{};
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final parts = addr.address.split('.');
          if (parts.length == 4 && !addr.isLoopback) {
            prefixes.add('${parts[0]}.${parts[1]}.${parts[2]}');
          }
        }
      }
    } catch (_) {
      return null;
    }

    for (final prefix in prefixes) {
      // Probe the whole subnet concurrently with a short timeout; the first
      // host that answers /health is the server.
      final probes = <Future<String?>>[];
      for (var host = 1; host < 255; host++) {
        final url = 'http://$prefix.$host:$port';
        probes.add(
          health(url, timeout: const Duration(milliseconds: 900))
              .then((ok) => ok ? url : null)
              .catchError((_) => null),
        );
      }
      final results = await Future.wait(probes);
      final found = results.firstWhere((r) => r != null, orElse: () => null);
      if (found != null) return found;
    }
    return null;
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
    final uri = Uri.parse('${_base(baseUrl)}/transcribe');
    final body = jsonEncode({
      'audio_url': audioUrl,
      'guid': guid,
      if (title != null && title.isNotEmpty) 'title': title,
      if (podcast != null && podcast.isNotEmpty) 'podcast': podcast,
      if (language != null && language.isNotEmpty) 'language': language,
    });

    // Retry the initial connection a few times with backoff so a brief network
    // drop (e.g. Tailscale re-routing) doesn't fail the whole job. A fresh
    // Request is needed each attempt — a sent one can't be re-finalized.
    http.StreamedResponse? resp;
    Object? lastError;
    for (var attempt = 0; attempt < 3 && resp == null; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(seconds: 2 * attempt));
      }
      final request = http.Request('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Content-Type'] = 'application/json'
        ..body = body;
      try {
        resp = await _client.send(request).timeout(const Duration(minutes: 3));
      } catch (e) {
        lastError = e;
      }
    }
    if (resp == null) {
      throw TranscribeException(
        'Could not reach the transcription server: $lastError',
      );
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
    // The stream ended without a `done` line — the connection dropped mid-run
    // (common on mobile for long episodes). The server keeps going and caches
    // the result, so signal the caller to poll rather than fail outright.
    if (text == null) throw const TranscribeInterrupted();
    if (text.isEmpty) throw TranscribeException('Empty transcript returned.');
    return text;
  }

  /// Polls for a completed transcript without starting a new run. Returns the
  /// transcript text if the server has it cached, or null if not ready yet.
  Future<String?> pollTranscript({
    required String baseUrl,
    required String token,
    required String guid,
    String? title,
    String? podcast,
  }) async {
    final uri = Uri.parse('${_base(baseUrl)}/transcript').replace(
      queryParameters: {
        'guid': guid,
        if (title != null && title.isNotEmpty) 'title': title,
        if (podcast != null && podcast.isNotEmpty) 'podcast': podcast,
      },
    );
    final resp = await _client
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    if (data['ready'] == true) {
      final text = (data['text'] as String?)?.trim() ?? '';
      return text.isEmpty ? null : text;
    }
    return null;
  }
}
