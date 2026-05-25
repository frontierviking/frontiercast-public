import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../providers.dart';

/// Tracks which episodes are currently being transcribed (by id) so any screen
/// — Now Playing, the transcript screen, the episode sheet — can reflect the
/// in-progress state. On success the transcript lands in the DB, which updates
/// [transcriptProvider] and flips the buttons to the "done" state.
class TranscribeController extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  bool isTranscribing(int episodeId) => state.contains(episodeId);

  /// Starts a transcription. Safe to call repeatedly — a job already running
  /// for the episode is a no-op. Rethrows on failure so callers can surface it.
  Future<void> transcribe(Episode episode, Podcast? podcast) async {
    if (state.contains(episode.id)) return;
    state = {...state, episode.id};
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
