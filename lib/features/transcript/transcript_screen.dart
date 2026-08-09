import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/transcribe/transcribe_settings.dart';
import '../../providers.dart';
import '../../services/transcribe_controller.dart';

/// Small pill showing which address transcription is using.
class _RouteChip extends StatelessWidget {
  final String label;
  const _RouteChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lan = label.contains('LAN') || label.contains('Wi-Fi');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            lan ? Icons.wifi : Icons.vpn_lock,
            size: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Headline above the progress bar. The percentage is rendered separately
/// beside the bar, so it isn't repeated here.
String _statusLabel(TranscribeJob s) => switch (s.stage) {
  'queued' => 'Waiting in the queue',
  'downloading' => 'Fetching the audio',
  'transcribing' => 'Transcribing on your Mac',
  'waiting' => 'Finishing on your Mac',
  _ => 'Starting…',
};

/// Sub-label under the bar explaining what the current stage means.
String _stageDetail(TranscribeJob s) => switch (s.stage) {
  'queued' => 'Starts when the current job finishes',
  'downloading' => 'Server is downloading the episode',
  'transcribing' => 'Whisper is running',
  'waiting' => 'Reconnected — waiting for the result',
  _ => 'Contacting the server',
};

class TranscriptScreen extends ConsumerStatefulWidget {
  final Episode episode;
  final Podcast? podcast;
  const TranscriptScreen({super.key, required this.episode, this.podcast});

  @override
  ConsumerState<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends ConsumerState<TranscriptScreen> {
  Future<void> _transcribe() async {
    ref.read(transcribeErrorProvider.notifier).state = null;
    await ref
        .read(transcribeControllerProvider.notifier)
        .transcribe(widget.episode, widget.podcast);
  }

  Future<void> _chooseRoute(
    BuildContext context,
    TranscribeSettings settings,
  ) async {
    final picked = await showDialog<TranscribeRoute>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Reach the Mac via'),
        children: [
          for (final r in TranscribeRoute.values)
            RadioListTile<TranscribeRoute>(
              value: r,
              groupValue: settings.route,
              title: Text(r.label),
              subtitle: Text(switch (r) {
                TranscribeRoute.auto =>
                  'Fastest at home, still works away from it',
                TranscribeRoute.lan => settings.lanUrl,
                TranscribeRoute.tailscale => settings.url,
              }, maxLines: 1, overflow: TextOverflow.ellipsis),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref.read(transcribeSettingsProvider.notifier).setRoute(picked);
      ref.read(transcribeRouteInUseProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transcript = ref.watch(transcriptProvider(widget.episode.id)).value;
    final status = ref.watch(transcribeControllerProvider)[widget.episode.id];
    final busy = status != null;
    // Failures are reported by the queue controller (the job runs outside this
    // screen's lifetime), so read them from the shared provider.
    final error = ref.watch(transcribeErrorProvider)?.message;
    final routeInUse = ref.watch(transcribeRouteInUseProvider);
    final settings = ref.watch(transcribeSettingsProvider).value;

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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _statusLabel(status),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 14),
                          // A bar reads better than a spinner for work that runs
                          // for many minutes: it shows the run is alive and how
                          // far along it is. Indeterminate until the server
                          // reports a fraction (queued / starting / reconnected).
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: status.progress > 0
                                  ? status.progress
                                  : null,
                              minHeight: 8,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _stageDetail(status),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (status.progress > 0)
                                Text(
                                  '${(status.progress * 100).round()}%',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Whisper runs on the Mac server. A full episode can '
                            'take several minutes — keep the app open.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (routeInUse != null) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: _RouteChip(
                                label: 'Connected via $routeInUse',
                              ),
                            ),
                          ],
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
                          if (settings != null) ...[
                            const SizedBox(height: 14),
                            _RouteChip(
                              label: routeInUse != null
                                  ? 'Last connected via $routeInUse'
                                  : 'Route: ${settings.route.label}',
                            ),
                            TextButton(
                              onPressed: () => _chooseRoute(context, settings),
                              child: const Text('Change connection'),
                            ),
                          ],
                          if (error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              error,
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
