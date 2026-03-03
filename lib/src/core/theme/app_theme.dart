import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF4F46E5);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seed,
      brightness: Brightness.light,
    );

    return base.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: const CardThemeData(
        elevation: 0.6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seed,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      cardTheme: const CardThemeData(
        elevation: 0.6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}