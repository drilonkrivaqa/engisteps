import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.darkMode = false,
    this.professorMode = false,
    this.decimalPrecision = 4,
    this.scientificNotation = false,
  });

  final bool darkMode;
  final bool professorMode;
  final int decimalPrecision;
  final bool scientificNotation;

  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;

  AppSettings copyWith({
    bool? darkMode,
    bool? professorMode,
    int? decimalPrecision,
    bool? scientificNotation,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      professorMode: professorMode ?? this.professorMode,
      decimalPrecision: decimalPrecision ?? this.decimalPrecision,
      scientificNotation: scientificNotation ?? this.scientificNotation,
    );
  }
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      darkMode: prefs.getBool('dark_mode') ?? false,
      professorMode: prefs.getBool('professor_mode') ?? false,
      decimalPrecision: prefs.getInt('precision') ?? 4,
      scientificNotation: prefs.getBool('sci') ?? false,
    );
  }

  Future<void> setDarkMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', v);
    state = state.copyWith(darkMode: v);
  }

  Future<void> setProfessorMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('professor_mode', v);
    state = state.copyWith(professorMode: v);
  }

  Future<void> setPrecision(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('precision', v);
    state = state.copyWith(decimalPrecision: v);
  }

  Future<void> setScientificNotation(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sci', v);
    state = state.copyWith(scientificNotation: v);
  }
}

final settingsControllerProvider = StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController();
});
