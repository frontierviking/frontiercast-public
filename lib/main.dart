import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers.dart';
import 'services/audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep library thumbnails decoded across navigations so returning from Now
  // Playing doesn't flicker, but not at any price: Android kills this process
  // by resident size, and a 256 MB cache made it the fattest target on the
  // phone (observed 530 MB RSS at kill time), taking long transcriptions with
  // it. 64 MB still holds the visible grid several screens deep.
  PaintingBinding.instance.imageCache
    ..maximumSize = 300
    ..maximumSizeBytes = 64 << 20; // 64 MB
  final handler = await AudioService.init(
    builder: PodcastAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.martin.frontiercast.audio',
      androidNotificationChannelName: 'FrontierCast playback',
      // Keep the foreground service while paused. The default drops it on
      // pause, which hands the process straight to the freezer and the
      // low-memory killer — so pausing an episode and coming back later found
      // the app dead, the bar empty, and the episode to be hunted down again.
      // (androidNotificationOngoing has to be false to allow this; the
      // notification becomes dismissible, which is the usual podcast-app
      // behaviour anyway.)
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
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
