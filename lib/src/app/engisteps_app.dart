import 'package:flutter/material.dart';

import '../core/navigation/app_router.dart';
import '../core/theme/app_theme.dart';

class EngiStepsApp extends StatelessWidget {
  const EngiStepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EngiSteps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
