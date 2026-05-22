import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LibrarySort { manual, alphabetical, dateAdded, recentlyUpdated, unplayedFirst }

extension LibrarySortLabel on LibrarySort {
  String get label => switch (this) {
    LibrarySort.manual => 'Manual order',
    LibrarySort.alphabetical => 'Alphabetical',
    LibrarySort.dateAdded => 'Date added',
    LibrarySort.recentlyUpdated => 'Recently updated',
    LibrarySort.unplayedFirst => 'Unplayed first',
  };
}

class LibrarySortController extends AsyncNotifier<LibrarySort> {
  static const _key = 'library_sort';

  @override
  Future<LibrarySort> build() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    return LibrarySort.values.firstWhere(
      (e) => e.name == name,
      orElse: () => LibrarySort.manual,
    );
  }

  Future<void> set(LibrarySort sort) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, sort.name);
    state = AsyncData(sort);
  }
}
