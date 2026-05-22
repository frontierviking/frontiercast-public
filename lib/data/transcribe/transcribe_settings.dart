import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUrlKey = 'transcribe_url';
const _kTokenKey = 'transcribe_token';

/// Defaults point at the Mac over Tailscale; both are editable in Settings.
const defaultTranscribeUrl = 'http://192.168.1.50:8765';
const defaultTranscribeToken =
    'change-me';

class TranscribeSettings {
  final String url;
  final String token;
  const TranscribeSettings({required this.url, required this.token});

  TranscribeSettings copyWith({String? url, String? token}) =>
      TranscribeSettings(url: url ?? this.url, token: token ?? this.token);
}

class TranscribeSettingsController extends AsyncNotifier<TranscribeSettings> {
  static const _fallback = TranscribeSettings(
    url: defaultTranscribeUrl,
    token: defaultTranscribeToken,
  );

  @override
  Future<TranscribeSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return TranscribeSettings(
      url: prefs.getString(_kUrlKey) ?? defaultTranscribeUrl,
      token: prefs.getString(_kTokenKey) ?? defaultTranscribeToken,
    );
  }

  Future<void> setUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUrlKey, url);
    state = AsyncData((state.value ?? _fallback).copyWith(url: url));
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
    state = AsyncData((state.value ?? _fallback).copyWith(token: token));
  }
}
