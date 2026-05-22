import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/podcast_repository.dart';
import '../../providers.dart';
import '../../services/playback_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(transcribeSettingsProvider).value;
    final playback = ref.watch(playbackSettingsProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Subscriptions'),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: const Text('Import Castbox subscriptions'),
            subtitle: const Text('From the bundled OPML export'),
            onTap: () => _importBundled(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_open_outlined),
            title: const Text('Import OPML file…'),
            subtitle: const Text('Pick an .opml / .xml export'),
            onTap: () => _importFile(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.add_link),
            title: const Text('Add by feed URL…'),
            onTap: () => _addByUrl(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh all feeds'),
            onTap: () => _refreshAll(context, ref),
          ),
          const Divider(),
          const _SectionHeader('Playback'),
          ListTile(
            leading: const Icon(Icons.forward_30),
            title: const Text('Skip forward'),
            subtitle: Text('${playback?.forwardSeconds ?? 30} seconds'),
            onTap: () => _chooseSeconds(
              context,
              title: 'Skip forward',
              current: playback?.forwardSeconds ?? 30,
              onPick: (s) =>
                  ref.read(playbackSettingsProvider.notifier).setForward(s),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.replay_30),
            title: const Text('Skip backward'),
            subtitle: Text('${playback?.backwardSeconds ?? 30} seconds'),
            onTap: () => _chooseSeconds(
              context,
              title: 'Skip backward',
              current: playback?.backwardSeconds ?? 30,
              onPick: (s) =>
                  ref.read(playbackSettingsProvider.notifier).setBackward(s),
            ),
          ),
          const Divider(),
          const _SectionHeader('Transcription (Whisper)'),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Server URL'),
            subtitle: Text(settings?.url ?? '…'),
            onTap: settings == null
                ? null
                : () => _editText(
                    context,
                    title: 'Transcription server URL',
                    hint: 'http://100.x.x.x:8765',
                    initial: settings.url,
                    onSave: (v) =>
                        ref.read(transcribeSettingsProvider.notifier).setUrl(v),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('Server token'),
            subtitle: Text(settings == null ? '…' : _mask(settings.token)),
            onTap: settings == null
                ? null
                : () => _editText(
                    context,
                    title: 'Server token',
                    hint: 'bearer token',
                    initial: settings.token,
                    onSave: (v) => ref
                        .read(transcribeSettingsProvider.notifier)
                        .setToken(v),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.wifi_tethering),
            title: const Text('Test connection'),
            onTap: () => _testConnection(context, ref),
          ),
          const Divider(),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('FrontierCast'),
            subtitle: Text('Personal, ad-free podcast player'),
          ),
        ],
      ),
    );
  }

  String _mask(String token) {
    if (token.length <= 8) return '••••';
    return '${token.substring(0, 4)}…${token.substring(token.length - 4)}';
  }

  Future<void> _editText(
    BuildContext context, {
    required String title,
    required String hint,
    required String initial,
    required Future<void> Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) await onSave(value);
  }

  Future<void> _chooseSeconds(
    BuildContext context, {
    required String title,
    required int current,
    required Future<void> Function(int) onPick,
  }) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          for (final s in skipSecondOptions)
            ListTile(
              title: Text('$s seconds'),
              trailing: s == current
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(ctx).pop(s),
            ),
        ],
      ),
    );
    if (picked != null) await onPick(picked);
  }

  Future<void> _testConnection(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(transcribeSettingsProvider).value;
    if (settings == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Checking server…')));
    final ok = await ref.read(transcribeClientProvider).health(settings.url);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Server reachable ✓' : 'Could not reach ${settings.url}',
        ),
      ),
    );
  }

  Future<void> _importBundled(BuildContext context, WidgetRef ref) async {
    final xml = await rootBundle.loadString(
      'assets/castbox_subscriptions.opml',
    );
    if (!context.mounted) return;
    await _runImport(
      context,
      ref,
      label: 'Importing Castbox subscriptions',
      action: (onProgress) => ref
          .read(podcastRepositoryProvider)
          .importOpml(xml, onProgress: onProgress),
    );
  }

  Future<void> _importFile(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['opml', 'xml'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;
    final xml = utf8.decode(bytes, allowMalformed: true);
    if (!context.mounted) return;
    await _runImport(
      context,
      ref,
      label: 'Importing OPML',
      action: (onProgress) => ref
          .read(podcastRepositoryProvider)
          .importOpml(xml, onProgress: onProgress),
    );
  }

  Future<void> _addByUrl(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add by feed URL'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://…/feed.xml'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (url == null || url.isEmpty || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _BusyDialog(label: 'Subscribing'),
    );
    try {
      await ref.read(podcastRepositoryProvider).subscribeByFeedUrl(url);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Subscribed')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _refreshAll(BuildContext context, WidgetRef ref) async {
    await _runImport(
      context,
      ref,
      label: 'Refreshing all feeds',
      action: (onProgress) => ref
          .read(podcastRepositoryProvider)
          .refreshAll(onProgress: onProgress),
    );
  }

  Future<void> _runImport(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required Future<ImportResult> Function(ProgressCallback) action,
  }) async {
    final progress = ValueNotifier<({int done, int total})>((
      done: 0,
      total: 0,
    ));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(label: label, progress: progress),
    );
    try {
      final result = await action((done, total) {
        progress.value = (done: done, total: total);
      });
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$label done: ${result.succeeded} ok'
              '${result.failed > 0 ? ', ${result.failed} failed' : ''}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      progress.dispose();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _BusyDialog extends StatelessWidget {
  final String label;
  const _BusyDialog({required this.label});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _ProgressDialog extends StatelessWidget {
  final String label;
  final ValueNotifier<({int done, int total})> progress;
  const _ProgressDialog({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(label),
      content: ValueListenableBuilder<({int done, int total})>(
        valueListenable: progress,
        builder: (_, value, _) {
          final fraction = value.total == 0 ? null : value.done / value.total;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: fraction),
              const SizedBox(height: 12),
              Text(
                value.total == 0
                    ? 'Starting…'
                    : '${value.done} / ${value.total}',
              ),
            ],
          );
        },
      ),
    );
  }
}
