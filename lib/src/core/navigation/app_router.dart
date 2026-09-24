import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/favorites/presentation/favorites_screens.dart';
import '../../features/history/presentation/history_screens.dart';
import '../../features/notes/presentation/notes_screen.dart';
import '../../features/tools/presentation/tools_screens.dart';
import '../../features/history/data/history_repository.dart';
import '../../features/settings/presentation/settings_screens.dart';
import '../../features/planner/presentation/planner_screen.dart';
import '../../features/learn/presentation/learning_screens.dart';

final router = GoRouter(
  initialLocation: '/learn',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/learn', builder: (_, _) => const LearnScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/tools', builder: (_, _) => const ToolsHomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (_, _) => const FavoritesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/notes', builder: (_, _) => const NotesScreen()),
          ],
        ),
      ],
    ),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(
      path: '/learn/topic/:id',
      builder: (_, s) => TopicScreen(topicId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/learn/problem/:id',
      builder: (_, s) => ProblemScreen(
        key: ValueKey(s.pathParameters['id']),
        problemId: s.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/planner',
      builder: (_, _) => const EngineeringPlannerScreen(),
    ),
    GoRoute(
      path: '/tool/:id',
      builder: (_, s) => ToolDetailScreen(
        toolId: s.pathParameters['id']!,
        restore: s.extra is HistoryEntry ? s.extra as HistoryEntry : null,
      ),
    ),
  ],
);

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 900) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: shell.goBranch,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Icon(Icons.architecture, size: 32),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.school_outlined),
                  label: Text('Learn'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.build_outlined),
                  label: Text('Tools'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.star_border),
                  label: Text('Favorites'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.note_alt_outlined),
                  label: Text('Notes'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (idx) => shell.goBranch(idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'Favorites',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: 'Notes',
          ),
        ],
      ),
    );
  }
}
