import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/data/settings_repository.dart';

class EngiStepsApp extends ConsumerWidget {
  const EngiStepsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: 'EngiSteps',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}