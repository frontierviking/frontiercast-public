import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/transcribe/transcribe_client.dart';
import '../data/transcribe/transcribe_settings.dart';
import '../providers.dart';

/// No configured transcription address answered a health check. [tried] holds
/// the human labels of the routes attempted ('Wi-Fi / LAN', 'Tailscale').
class _NoEndpointReachable implements Exception {
  final List<String> tried;
  const _NoEndpointReachable(this.tried);
}

/// Turns a transcription failure into a message that says what to fix.
String _transcribeErrorMessage(Object e) {
  if (e is _NoEndpointReachable) {
    if (e.tried.isEmpty) {
      return 'No transcription server address configured — set one in '
          'Settings → Transcription.';
    }
    final routes = e.tried.join(' and ');
    if (e.tried.length > 1) {
      return "Can't reach your Mac on $routes. Check Tailscale is connected "
          "(or that you're on home Wi-Fi and the server is running).";
    }
    if (e.tried.first == 'Tailscale') {
      return "Can't reach your Mac over Tailscale — Tailscale looks down. "
          'Reconnect it on your phone, or switch to Wi-Fi/LAN in Settings.';
    }
    return "Can't reach your Mac over Wi-Fi / LAN — check you're on home "
        'Wi-Fi and the server is running, or switch to Tailscale in Settings.';
  }
  final s = e.toString();
  if (s.contains('Unauthorized')) {
    return 'Transcription server rejected the token — check it in Settings.';
  }
  if (s.contains('Could not reach the transcription server')) {
    return "Can't reach the transcription server. If you're away from home, "
        'Tailscale needs to be connected.';
  }
  if (s.contains('Empty transcript')) {
    return 'The server returned an empty transcript — try again.';
  }
  return 'Transcription failed: $s';
}

/// A queued or in-flight transcription job.
class TranscribeJob {
  final Episode episode;
  final Podcast? podcast;

  /// 'queued' | 'starting' | 'downloading' | 'transcribing' | 'waiting'.
  /// 'queued'  — waiting its turn behind other jobs.
  /// 'waiting' — the streaming connection dropped and we're polling the server
  ///             for the result it's still finishing in the background.
  final String stage;

  /// Fraction (0..1) within the current stage; 0 means "no progress yet".
  final double progress;

  const TranscribeJob({
    required this.episode,
    required this.podcast,
    required this.stage,
    required this.progress,
  });

  bool get isQueued => stage == 'queued';

  TranscribeJob copyWith({String? stage, double? progress}) => TranscribeJob(
    episode: episode,
    podcast: podcast,
    stage: stage ?? this.stage,
    progress: progress ?? this.progress,
  );
}

/// Runs transcriptions through a single sequential queue: the Mac transcribes
/// one episode at a time (Whisper needs the whole GPU), so the app sends one
/// request at a time rather than piling up connections. The state map is
/// insertion-ordered, so its values read out as the queue order — the first
/// non-queued entry is the one currently running. Any screen (Downloads, Now
/// Playing, the episode sheet, the transcript screen) can watch it for status.
class TranscribeController extends Notifier<Map<int, TranscribeJob>> {
  final List<int> _pending = [];
  bool _running = false;

  @override
  Map<int, TranscribeJob> build() => {};

  bool isTranscribing(int episodeId) => state.containsKey(episodeId);

  TranscribeJob? jobFor(int episodeId) => state[episodeId];

  /// Enqueues a transcription. A no-op if the episode is already queued or
  /// running. Starts the queue pump if it isn't already going.
  Future<void> transcribe(Episode episode, Podcast? podcast) async {
    if (state.containsKey(episode.id)) return;
    state = {
      ...state,
      episode.id: TranscribeJob(
        episode: episode,
        podcast: podcast,
        stage: 'queued',
        progress: 0,
      ),
    };
    _pending.add(episode.id);
    unawaited(_pump());
  }

  /// Removes an episode from the queue. If it's the one currently running, the
  /// server can't be stopped mid-run, but dropping it from state ends the UI
  /// indicator and the poll loop (which checks state membership) bails out.
  void cancel(int episodeId) {
    _pending.remove(episodeId);
    if (state.containsKey(episodeId)) {
      state = {...state}..remove(episodeId);
    }
  }

  void _setStage(int id, String stage, double progress) {
    final job = state[id];
    if (job == null) return;
    state = {...state, id: job.copyWith(stage: stage, progress: progress)};
  }

  Future<void> _pump() async {
    if (_running) return;
    _running = true;
    try {
      while (_pending.isNotEmpty) {
        final id = _pending.removeAt(0);
        final job = state[id];
        if (job == null) continue; // cancelled before it started
        await _runOne(job.episode, job.podcast);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _runOne(Episode episode, Podcast? podcast) async {
    final client = ref.read(transcribeClientProvider);
    try {
      _setStage(episode.id, 'starting', 0);
      final settings = await ref.read(transcribeSettingsProvider.future);

      // Pick whichever configured address actually answers (LAN first in auto
      // mode), so a down tailnet at home doesn't block transcription — and a
      // specific error can name what's unreachable.
      final baseUrl = await _pickEndpoint(client, settings);
      ref.read(transcribeRouteInUseProvider.notifier).state = settings.labelFor(
        baseUrl,
      );

      String? text;
      try {
        text = await client.transcribe(
          baseUrl: baseUrl,
          token: settings.token,
          audioUrl: episode.audioUrl,
          guid: episode.guid,
          title: episode.title,
          podcast: podcast?.title,
          onProgress: (stage, p) => _setStage(episode.id, stage, p),
        );
      } on TranscribeInterrupted {
        text = await _pollUntilReady(
          client,
          baseUrl,
          settings.token,
          episode,
          podcast,
        );
      }
      if (text != null) {
        await ref
            .read(databaseProvider)
            .transcriptDao
            .upsert(episode.id, text, null);
      }
    } catch (e) {
      // A failed job shouldn't stall the queue, but the user needs to know why
      // rather than watching it silently vanish.
      ref.read(transcribeErrorProvider.notifier).state = (
        message: _transcribeErrorMessage(e),
        at: DateTime.now(),
      );
    } finally {
      if (state.containsKey(episode.id)) {
        state = {...state}..remove(episode.id);
      }
    }
  }

  /// Returns the first configured address whose /health responds. Throws
  /// [_NoEndpointReachable] (carrying which routes were tried) if none do.
  Future<String> _pickEndpoint(
    TranscribeClient client,
    TranscribeSettings settings,
  ) async {
    final candidates = settings.candidates;
    if (candidates.isEmpty) {
      throw const _NoEndpointReachable([]);
    }
    final tried = <String>[];
    for (final c in candidates) {
      tried.add(settings.labelFor(c));
      if (await client.health(c)) return c;
    }
    // Nothing configured answered. The Mac's LAN address changes whenever the
    // router re-leases, so sweep the local subnet for it before giving up — and
    // remember what we find so the next run goes straight there.
    if (settings.route != TranscribeRoute.tailscale) {
      final found = await client.discoverOnLan();
      if (found != null) {
        await ref.read(transcribeSettingsProvider.notifier).setLanUrl(found);
        return found;
      }
      tried.add('LAN auto-discovery');
    }
    throw _NoEndpointReachable(tried);
  }

  /// After a dropped connection, poll the server for the transcript it's still
  /// finishing. Returns the text once available, or null if it never arrives
  /// within the time budget (the user can retry — it'll hit the cache).
  Future<String?> _pollUntilReady(
    TranscribeClient client,
    String baseUrl,
    String token,
    Episode episode,
    Podcast? podcast,
  ) async {
    _setStage(episode.id, 'waiting', 0);
    // ~40 minutes of polling covers even very long episodes on the medium model.
    const interval = Duration(seconds: 10);
    for (var i = 0; i < 240; i++) {
      if (!state.containsKey(episode.id)) return null; // cancelled elsewhere
      await Future<void>.delayed(interval);
      try {
        final text = await client.pollTranscript(
          baseUrl: baseUrl,
          token: token,
          guid: episode.guid,
          title: episode.title,
          podcast: podcast?.title,
        );
        if (text != null) return text;
      } catch (_) {
        // Transient network error while polling — keep trying.
      }
    }
    return null;
  }
}
