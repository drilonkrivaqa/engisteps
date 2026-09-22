import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/settings/data/settings_repository.dart';

import '../core/navigation/app_router.dart';
import '../core/theme/app_theme.dart';

class EngiStepsApp extends ConsumerWidget {
  const EngiStepsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'EngiSteps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(settingsControllerProvider).themeMode,
      routerConfig: router,
    );
  }
}
