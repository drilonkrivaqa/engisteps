import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritePreset {
  const FavoritePreset({
    required this.id,
    required this.toolId,
    required this.name,
    required this.values,
  });

  final String id;
  final String toolId;
  final String name;
  final Map<String, String> values;

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolId': toolId,
        'name': name,
        'values': values,
      };

  factory FavoritePreset.fromJson(Map<String, dynamic> json) => FavoritePreset(
        id: json['id'] as String,
        toolId: json['toolId'] as String,
        name: json['name'] as String,
        values: Map<String, String>.from(json['values'] as Map),
      );
}

abstract class FavoritesRepository {
  Future<List<String>> getFavorites();
  Future<void> toggleFavorite(String toolId);
  Future<bool> isFavorite(String toolId);
  Future<List<FavoritePreset>> getPresets();
  Future<void> savePreset(FavoritePreset preset);
}

class SharedPrefsFavoritesRepository implements FavoritesRepository {
  static const _key = 'favorites';
  static const _presetKey = 'favorite_presets';

  @override
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  @override
  Future<bool> isFavorite(String toolId) async {
    final current = await getFavorites();
    return current.contains(toolId);
  }

  @override
  Future<List<FavoritePreset>> getPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_presetKey) ?? [];
    return raw.map((e) => FavoritePreset.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> savePreset(FavoritePreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getPresets();
    current.insert(0, preset);
    await prefs.setStringList(_presetKey, current.map((e) => jsonEncode(e.toJson())).toList());
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

final favoritePresetsProvider = FutureProvider<List<FavoritePreset>>((ref) {
  return ref.watch(favoritesRepositoryProvider).getPresets();
});
