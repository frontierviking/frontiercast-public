import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kKey = 'podcastindex_key';
const _kSecret = 'podcastindex_secret';

/// Podcast Index API credentials, entered in Settings and stored on-device.
/// Empty by default — when unset, Podcast Index search is simply skipped.
class PodcastIndexSettings {
  final String apiKey;
  final String apiSecret;
  const PodcastIndexSettings({this.apiKey = '', this.apiSecret = ''});

  bool get configured => apiKey.isNotEmpty && apiSecret.isNotEmpty;

  PodcastIndexSettings copyWith({String? apiKey, String? apiSecret}) =>
      PodcastIndexSettings(
        apiKey: apiKey ?? this.apiKey,
        apiSecret: apiSecret ?? this.apiSecret,
      );
}

class PodcastIndexSettingsController
    extends AsyncNotifier<PodcastIndexSettings> {
  @override
  Future<PodcastIndexSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return PodcastIndexSettings(
      apiKey: prefs.getString(_kKey) ?? '',
      apiSecret: prefs.getString(_kSecret) ?? '',
    );
  }

  Future<void> setKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, value);
    state = AsyncData(
      (state.value ?? const PodcastIndexSettings()).copyWith(apiKey: value),
    );
  }

  Future<void> setSecret(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSecret, value);
    state = AsyncData(
      (state.value ?? const PodcastIndexSettings()).copyWith(apiSecret: value),
    );
  }
}
