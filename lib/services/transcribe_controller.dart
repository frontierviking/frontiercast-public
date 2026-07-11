import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/transcribe/transcribe_client.dart';
import '../providers.dart';

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
      String? text;
      try {
        text = await client.transcribe(
          baseUrl: settings.url,
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
          settings.url,
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
    } catch (_) {
      // A failed job shouldn't stall the queue; drop it and move on.
    } finally {
      if (state.containsKey(episode.id)) {
        state = {...state}..remove(episode.id);
      }
    }
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
