import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class FavoritesRepository {
  Future<List<String>> getFavorites();
  Future<void> toggleFavorite(String toolId);
}

class SharedPrefsFavoritesRepository implements FavoritesRepository {
  static const _key = 'favorites';

  @override
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  @override
  Future<void> toggleFavorite(String toolId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    if (current.contains(toolId)) {
      current.remove(toolId);
    } else {
      current.add(toolId);
    }
    await prefs.setStringList(_key, current);
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return SharedPrefsFavoritesRepository();
});

final favoritesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(favoritesRepositoryProvider).getFavorites();
});
