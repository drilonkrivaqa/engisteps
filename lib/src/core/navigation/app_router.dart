import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/favorites/presentation/favorites_screens.dart';
import '../../features/history/presentation/history_screens.dart';
import '../../features/notes/presentation/notes_screen.dart';
import '../../features/tools/presentation/tools_screens.dart';

final router = GoRouter(
  initialLocation: '/tools',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/tools', builder: (_, __) => const ToolsHomeScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/history', builder: (_, __) => const HistoryScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/notes', builder: (_, __) => const NotesScreen())]),
      ],
    ),
    GoRoute(path: '/tool/:id', builder: (_, s) => ToolDetailScreen(toolId: s.pathParameters['id']!)),
  ],
);

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (idx) => shell.goBranch(idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Tools'),
          NavigationDestination(icon: Icon(Icons.star_border), selectedIcon: Icon(Icons.star), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.note_alt_outlined), selectedIcon: Icon(Icons.note_alt), label: 'Notes'),
        ],
      ),
    );
  }
}
