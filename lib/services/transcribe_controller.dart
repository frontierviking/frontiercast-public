import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../providers.dart';

/// Live status of an in-progress transcription.
class TranscribeStatus {
  /// 'starting' | 'downloading' | 'transcribing'.
  final String stage;

  /// Fraction (0..1) within the current stage; 0 means "no progress yet".
  final double progress;
  const TranscribeStatus(this.stage, this.progress);
}

/// Tracks episodes currently being transcribed and their progress so any screen
/// — Now Playing, the transcript screen, the episode sheet — can show a progress
/// circle (downloading, then transcribing). On success the transcript lands in
/// the DB, which updates [transcriptProvider] and flips the buttons to "done".
class TranscribeController extends Notifier<Map<int, TranscribeStatus>> {
  @override
  Map<int, TranscribeStatus> build() => {};

  bool isTranscribing(int episodeId) => state.containsKey(episodeId);

  /// Current status for an episode, or null if not transcribing.
  TranscribeStatus? statusFor(int episodeId) => state[episodeId];

  /// Starts a transcription. Safe to call repeatedly — a job already running
  /// for the episode is a no-op. Rethrows on failure so callers can surface it.
  Future<void> transcribe(Episode episode, Podcast? podcast) async {
    if (state.containsKey(episode.id)) return;
    state = {...state, episode.id: const TranscribeStatus('starting', 0)};
    try {
      final settings = await ref.read(transcribeSettingsProvider.future);
      final text = await ref
          .read(transcribeClientProvider)
          .transcribe(
            baseUrl: settings.url,
            token: settings.token,
            audioUrl: episode.audioUrl,
            guid: episode.guid,
            title: episode.title,
            podcast: podcast?.title,
            onProgress: (stage, p) {
              if (state.containsKey(episode.id)) {
                state = {...state, episode.id: TranscribeStatus(stage, p)};
              }
            },
          );
      await ref
          .read(databaseProvider)
          .transcriptDao
          .upsert(episode.id, text, null);
    } finally {
      state = {...state}..remove(episode.id);
    }
  }
}
