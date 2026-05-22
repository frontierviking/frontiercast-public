import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kForward = 'skip_forward_seconds';
const _kBackward = 'skip_backward_seconds';

const skipSecondOptions = [10, 15, 30, 45, 60];

class PlaybackSettings {
  final int forwardSeconds;
  final int backwardSeconds;
  const PlaybackSettings({
    this.forwardSeconds = 30,
    this.backwardSeconds = 30,
  });

  PlaybackSettings copyWith({int? forwardSeconds, int? backwardSeconds}) =>
      PlaybackSettings(
        forwardSeconds: forwardSeconds ?? this.forwardSeconds,
        backwardSeconds: backwardSeconds ?? this.backwardSeconds,
      );
}

class PlaybackSettingsController extends AsyncNotifier<PlaybackSettings> {
  static const _fallback = PlaybackSettings();

  @override
  Future<PlaybackSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return PlaybackSettings(
      forwardSeconds: prefs.getInt(_kForward) ?? 30,
      backwardSeconds: prefs.getInt(_kBackward) ?? 30,
    );
  }

  Future<void> setForward(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kForward, seconds);
    state = AsyncData(
      (state.value ?? _fallback).copyWith(forwardSeconds: seconds),
    );
  }

  Future<void> setBackward(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBackward, seconds);
    state = AsyncData(
      (state.value ?? _fallback).copyWith(backwardSeconds: seconds),
    );
  }
}
