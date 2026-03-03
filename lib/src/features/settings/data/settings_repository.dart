import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
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

  static const _kDarkMode = 'dark_mode';
  static const _kProfessorMode = 'professor_mode';
  static const _kPrecision = 'precision';
  static const _kSci = 'sci';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      darkMode: prefs.getBool(_kDarkMode) ?? false,
      professorMode: prefs.getBool(_kProfessorMode) ?? false,
      decimalPrecision: prefs.getInt(_kPrecision) ?? 4,
      scientificNotation: prefs.getBool(_kSci) ?? false,
    );
  }

  Future<void> setDarkMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, v);
    state = state.copyWith(darkMode: v);
  }

  Future<void> setProfessorMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kProfessorMode, v);
    state = state.copyWith(professorMode: v);
  }

  Future<void> setPrecision(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrecision, v);
    state = state.copyWith(decimalPrecision: v);
  }

  Future<void> setScientificNotation(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSci, v);
    state = state.copyWith(scientificNotation: v);
  }
}

final settingsControllerProvider =
StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController();
});