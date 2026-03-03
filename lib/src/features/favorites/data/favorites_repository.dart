import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesController extends StateNotifier<List<String>> {
  FavoritesController() : super(const []) {
    load();
  }

  static const _key = 'favorites_ordered';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? <String>[];
  }

  Future<void> toggle(String toolId) async {
    final next = [...state];
    if (next.contains(toolId)) {
      next.remove(toolId);
    } else {
      next.insert(0, toolId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final next = [...state];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesController, List<String>>((ref) {
  return FavoritesController();
});
