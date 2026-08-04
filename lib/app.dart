import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/downloads/downloads_screen.dart';
import 'features/library/library_screen.dart';
import 'features/player/mini_player.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'providers.dart';
import 'services/playback_controller.dart';
import 'theme.dart';

class FrontierCastApp extends StatelessWidget {
  const FrontierCastApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Neutral true-black surfaces (Castbox-style), with the red accent on top —
    // seeding surfaces off the red made everything look brownish.
    final darkScheme =
        ColorScheme.fromSeed(
          seedColor: kAccent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: kAccent,
          onPrimary: Colors.white,
          surface: const Color(0xFF0A0A0A),
          surfaceContainerLowest: const Color(0xFF000000),
          surfaceContainerLow: const Color(0xFF141414),
          surfaceContainer: const Color(0xFF1A1A1A),
          surfaceContainerHigh: const Color(0xFF212121),
          surfaceContainerHighest: const Color(0xFF2A2A2A),
          onSurface: Colors.white,
          onSurfaceVariant: const Color(0xFFB5B5B5),
          outlineVariant: const Color(0xFF2A2A2A),
        );

    return MaterialApp(
      title: 'FrontierCast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: Colors.black,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: kAccent,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;
  DateTime? _lastRefresh;
  static const _minRefreshInterval = Duration(minutes: 15);

  static const _screens = [
    LibraryScreen(),
    SearchScreen(),
    DownloadsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Let the first frames and initial scroll settle before kicking off the
    // background refresh, so startup feels instant.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), _quietRefresh);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _quietRefresh();
  }

  /// Refreshes all subscribed feeds quietly in the background (no spinner),
  /// throttled so foreground switches don't hammer the network.
  Future<void> _quietRefresh() async {
    final now = DateTime.now();
    if (_lastRefresh != null &&
        now.difference(_lastRefresh!) < _minRefreshInterval) {
      return;
    }
    _lastRefresh = now;
    try {
      await ref.read(podcastRepositoryProvider).refreshAll();
    } catch (_) {
      // best-effort; ignore failures
    }
  }

  @override
  Widget build(BuildContext context) {
    // Surface playback errors (e.g. dead audio URLs) as a one-shot snackbar.
    ref.listen<PlaybackState>(playbackControllerProvider, (prev, next) {
      final err = next.lastError;
      if (err == null || err == prev?.lastError) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.hideCurrentSnackBar();
      // Stay on screen until the user dismisses it (or navigates somewhere
      // that hides snackbars). Far longer than any reasonable read time.
      messenger.showSnackBar(
        SnackBar(
          content: Text(err.message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(days: 1),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: messenger.hideCurrentSnackBar,
          ),
        ),
      );
    });
    // Surface transcription failures (e.g. Tailscale down) — the job runs in a
    // queue outside any one screen, so report it app-wide.
    ref.listen<({String message, DateTime at})?>(transcribeErrorProvider, (
      prev,
      next,
    ) {
      if (next == null || next == prev) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(next.message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(days: 1),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: messenger.hideCurrentSnackBar,
          ),
        ),
      );
    });
    return PopScope(
      // Allow the system back to actually pop (i.e. exit the app) only when
      // already on the Library tab. From any other tab, back returns to Library
      // first — matches the standard Android bottom-nav pattern.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) {
              ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
              setState(() => _index = i);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
              NavigationDestination(
                icon: Icon(Icons.download_outlined),
                selectedIcon: Icon(Icons.download),
                label: 'Downloads',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
