import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers.dart';
import 'services/audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Generous image cache so library thumbnails stay decoded in memory across
  // navigations — Now Playing's full-res artwork would otherwise evict them
  // and cause a brief reload flicker when returning to Library.
  PaintingBinding.instance.imageCache
    ..maximumSize = 500
    ..maximumSizeBytes = 256 << 20; // 256 MB
  final handler = await AudioService.init(
    builder: PodcastAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.martin.frontiercast.audio',
      androidNotificationChannelName: 'FrontierCast playback',
      androidNotificationOngoing: true,
      fastForwardInterval: Duration(seconds: 30),
      rewindInterval: Duration(seconds: 30),
    ),
  );
  runApp(
    ProviderScope(
      overrides: [audioHandlerProvider.overrideWithValue(handler)],
      child: const FrontierCastApp(),
    ),
  );
}
