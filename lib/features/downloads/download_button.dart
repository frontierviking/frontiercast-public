import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import '../../theme.dart';

/// Per-episode download control: download / progress (cancel) / downloaded
/// (delete) / retry. Reused in the episode list and the detail sheet.
class DownloadButton extends ConsumerWidget {
  final Episode episode;
  const DownloadButton({super.key, required this.episode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressMap = ref.watch(downloadControllerProvider);
    final controller = ref.read(downloadControllerProvider.notifier);

    final activeProgress = progressMap[episode.id];
    final isDownloading =
        activeProgress != null ||
        episode.downloadState == DownloadState.downloading;

    if (episode.downloadState == DownloadState.downloaded) {
      return IconButton(
        tooltip: 'Downloaded — tap to delete',
        onPressed: () => controller.delete(episode),
        icon: const Icon(Icons.download_done, color: kDownloaded),
      );
    }

    if (isDownloading) {
      return IconButton(
        tooltip: 'Downloading — tap to cancel',
        onPressed: () => controller.cancel(episode),
        icon: SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: activeProgress, strokeWidth: 2),
              const Icon(Icons.close, size: 11),
            ],
          ),
        ),
      );
    }

    final failed = episode.downloadState == DownloadState.failed;
    return IconButton(
      tooltip: failed ? 'Download failed — retry' : 'Download',
      onPressed: () => controller.download(episode),
      icon: Icon(
        failed ? Icons.error_outline : Icons.download_for_offline_outlined,
        color: kAccent,
      ),
    );
  }
}
