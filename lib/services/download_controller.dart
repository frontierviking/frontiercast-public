import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../domain/models.dart';
import '../providers.dart';

const _audioExtensions = {'mp3', 'm4a', 'aac', 'ogg', 'opus', 'wav', 'mp4'};

/// Tracks in-flight downloads (episodeId -> progress 0..1) and persists the
/// final state (localPath / downloadState) into drift.
class DownloadController extends Notifier<Map<int, double>> {
  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Map<int, double> build() => {};

  Future<void> download(Episode episode) async {
    if (state.containsKey(episode.id)) return;

    await _db.episodeDao.setDownloadState(
      episode.id,
      DownloadState.downloading,
    );
    state = {...state, episode.id: 0};

    final task = DownloadTask(
      taskId: 'ep_${episode.id}',
      url: episode.audioUrl,
      filename: 'episode_${episode.id}.${_extensionFor(episode.audioUrl)}',
      baseDirectory: BaseDirectory.applicationDocuments,
      directory: 'downloads',
      updates: Updates.statusAndProgress,
      retries: 2,
    );

    try {
      final result = await FileDownloader().download(
        task,
        onProgress: (p) {
          if (p >= 0 && p <= 1) state = {...state, episode.id: p};
        },
      );
      if (result.status == TaskStatus.complete) {
        final path = await task.filePath();
        await _db.episodeDao.setDownloaded(episode.id, path);
      } else {
        await _db.episodeDao.setDownloadState(episode.id, DownloadState.failed);
      }
    } catch (_) {
      await _db.episodeDao.setDownloadState(episode.id, DownloadState.failed);
    } finally {
      state = {...state}..remove(episode.id);
    }
  }

  Future<void> cancel(Episode episode) async {
    await FileDownloader().cancelTaskWithId('ep_${episode.id}');
    await _db.episodeDao.setDownloadState(
      episode.id,
      DownloadState.notDownloaded,
    );
    state = {...state}..remove(episode.id);
  }

  Future<void> delete(Episode episode) async {
    final path = episode.localPath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    await _db.episodeDao.clearDownload(episode.id);
  }

  String _extensionFor(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final dot = path.lastIndexOf('.');
    if (dot != -1 && dot < path.length - 1) {
      final ext = path.substring(dot + 1).toLowerCase();
      if (_audioExtensions.contains(ext)) return ext;
    }
    return 'mp3';
  }
}
