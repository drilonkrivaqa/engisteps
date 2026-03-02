import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/classroom/presentation/classroom_screens.dart';
import '../../features/favorites/presentation/favorites_screens.dart';
import '../../features/history/presentation/history_screens.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screens.dart';
import '../../features/search/presentation/search_screens.dart';
import '../../features/settings/presentation/settings_screens.dart';
import '../../features/tools/presentation/tools_screens.dart';
import '../widgets/stub_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHome = GlobalKey<NavigatorState>();
final _shellNavigatorTools = GlobalKey<NavigatorState>();
final _shellNavigatorFavorites = GlobalKey<NavigatorState>();
final _shellNavigatorSettings = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/pick-track', builder: (_, __) => const PickTrackScreen()),
      GoRoute(path: '/permissions', builder: (_, __) => const PermissionsScreen()),
      GoRoute(path: '/create-account', builder: (_, __) => const CreateAccountScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BottomNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(navigatorKey: _shellNavigatorHome, routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(navigatorKey: _shellNavigatorTools, routes: [GoRoute(path: '/tools', builder: (_, __) => const ToolsHubScreen())]),
          StatefulShellBranch(navigatorKey: _shellNavigatorFavorites, routes: [GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen())]),
          StatefulShellBranch(navigatorKey: _shellNavigatorSettings, routes: [GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen())]),
        ],
      ),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/search/results', builder: (_, __) => const SearchResultsScreen()),
      GoRoute(path: '/tools/category/:category', builder: (_, s) => CategoryScreen(category: s.pathParameters['category']!)),
      GoRoute(path: '/tool/:id', builder: (_, s) => ToolDetailScreen(toolId: s.pathParameters['id']!)),
      GoRoute(path: '/tool/:id/steps', builder: (_, __) => const ToolStepsScreen()),
      GoRoute(path: '/tool/:id/info', builder: (_, __) => const ToolInfoScreen()),
      GoRoute(path: '/tool/:id/graph', builder: (_, __) => const ToolGraphScreen()),
      GoRoute(path: '/tool/:id/history', builder: (_, s) => PerToolHistoryScreen(toolId: s.pathParameters['id']!)),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/history/detail', builder: (_, __) => const HistoryDetailScreen()),
      GoRoute(path: '/favorites/presets', builder: (_, __) => const PresetManagerScreen()),
      GoRoute(path: '/share-export', builder: (_, __) => const StubScreen(title: 'Share / Export', message: 'Share/export stubs.')),
      GoRoute(path: '/settings/account', builder: (_, __) => const AccountScreen()),
      GoRoute(path: '/settings/preferences', builder: (_, __) => const PreferencesScreen()),
      GoRoute(path: '/settings/units', builder: (_, __) => const UnitsScreen()),
      GoRoute(path: '/settings/offline', builder: (_, __) => const OfflineScreen()),
      GoRoute(path: '/settings/about', builder: (_, __) => const AboutScreen()),
      GoRoute(path: '/settings/legal', builder: (_, __) => const LegalScreen()),
      GoRoute(path: '/settings/feedback', builder: (_, __) => const FeedbackScreen()),
      GoRoute(path: '/classroom/dashboard', builder: (_, __) => const ProfessorDashboardScreen()),
      GoRoute(path: '/classroom/template-builder', builder: (_, __) => const TemplateBuilderScreen()),
      GoRoute(path: '/classroom/template-preview', builder: (_, __) => const TemplatePreviewScreen()),
      GoRoute(path: '/classroom/share-template', builder: (_, __) => const ShareTemplateScreen()),
    ],
    redirect: (context, state) {
      if (state.fullPath == '/splash') return '/welcome';
      if (state.fullPath == '/welcome') return '/home';
      return null;
    },
  );
});

class BottomNavShell extends StatelessWidget {
  const BottomNavShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calculate_outlined), label: 'Tools'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
