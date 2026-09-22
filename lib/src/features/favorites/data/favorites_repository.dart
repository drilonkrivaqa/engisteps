import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesController extends StateNotifier<List<String>> {
  FavoritesController() : super(const []) {
    _ready = load();
  }

  static const _key = 'favorites_ordered';
  late final Future<void> _ready;
  Future<void> _writes = Future.value();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      state = (prefs.getStringList(_key) ?? <String>[]).toSet().toList();
    }
  }

  Future<void> toggle(String toolId) async {
    await _ready;
    final next = [...state];
    if (next.contains(toolId)) {
      next.remove(toolId);
    } else {
      next.insert(0, toolId);
    }
    state = next;
    await _save(next);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    await _ready;
    final next = [...state];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    state = next;
    await _save(next);
  }

  Future<void> _save(List<String> values) {
    final operation = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setStringList(_key, values)) {
        throw StateError('Could not save favorites');
      }
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesController, List<String>>((ref) {
      return FavoritesController();
    });
