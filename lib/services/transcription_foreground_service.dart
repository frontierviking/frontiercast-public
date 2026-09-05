import 'package:flutter/services.dart';

/// Holds an Android foreground service open while the transcription queue runs.
///
/// A transcription takes minutes to hours and the phone has to keep an HTTP
/// stream open throughout. Backgrounded without a foreground service, it
/// doesn't survive — Samsung's Freecess freezes the app seconds after it loses
/// focus and Android kills it soon after, which was wiping jobs mid-run with no
/// error and nothing to resume.
///
/// Failures here are deliberately swallowed: losing the service means the job
/// is killable again, not that it can't run.
class TranscriptionForegroundService {
  static const _channel = MethodChannel('com.martin.frontiercast/transcription');

  const TranscriptionForegroundService();

  Future<void> start(String text) => _invoke('start', {'text': text});

  Future<void> stop() => _invoke('stop', null);

  Future<void> _invoke(String method, Map<String, Object?>? args) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Not Android (or an engine without the channel) — nothing to hold.
    } on PlatformException {
      // Service refused to start; the queue carries on unprotected.
    }
  }
}
