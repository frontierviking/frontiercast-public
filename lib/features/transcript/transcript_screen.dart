import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../providers.dart';
import '../../services/transcribe_controller.dart';

String _statusLabel(TranscribeStatus s) {
  final pct = (s.progress * 100).round();
  return switch (s.stage) {
    'downloading' => s.progress > 0 ? 'Downloading… $pct%' : 'Downloading…',
    'transcribing' => 'Transcribing… $pct%',
    _ => 'Transcribing on your Mac…',
  };
}

class TranscriptScreen extends ConsumerStatefulWidget {
  final Episode episode;
  final Podcast? podcast;
  const TranscriptScreen({super.key, required this.episode, this.podcast});

  @override
  ConsumerState<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends ConsumerState<TranscriptScreen> {
  String? _error;

  Future<void> _transcribe() async {
    setState(() => _error = null);
    try {
      await ref
          .read(transcribeControllerProvider.notifier)
          .transcribe(widget.episode, widget.podcast);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transcript = ref.watch(transcriptProvider(widget.episode.id)).value;
    final status = ref.watch(transcribeControllerProvider)[widget.episode.id];
    final busy = status != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Transcript')),
      body: transcript != null
          ? Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.episode.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      transcript.content,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: busy
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              value: status.progress > 0
                                  ? status.progress
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _statusLabel(status),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Whisper runs on the Mac server. A full episode can '
                            'take several minutes — keep the app open.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.article_outlined, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'No transcript yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generate one with Whisper on your Mac '
                            '(must be reachable over Tailscale/Wi‑Fi).',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _transcribe,
                            icon: const Icon(Icons.graphic_eq),
                            label: const Text('Transcribe'),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
    );
  }
}
