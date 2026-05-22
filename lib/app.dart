import 'package:flutter/material.dart';

import 'features/downloads/downloads_screen.dart';
import 'features/library/library_screen.dart';
import 'features/player/mini_player.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
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

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    LibraryScreen(),
    SearchScreen(),
    DownloadsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
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
    );
  }
}
