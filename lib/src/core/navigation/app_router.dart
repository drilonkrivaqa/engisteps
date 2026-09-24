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
import '../../features/learn/presentation/student_home_screen.dart';
import '../../features/home/presentation/work_screen.dart';
import '../../features/learn/presentation/circuit_lab_screen.dart';
import '../../features/learn/domain/circuit_experiment.dart';

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
              path: '/work',
              builder: (_, _) => const WorkScreen(),
              routes: [
                GoRoute(
                  path: 'history',
                  builder: (_, _) => const HistoryScreen(),
                ),
                GoRoute(
                  path: 'favorites',
                  builder: (_, _) => const FavoritesScreen(),
                ),
                GoRoute(
                  path: 'notes',
                  builder: (_, _) => Scaffold(
                    appBar: AppBar(title: const Text('My notes')),
                    body: const NotesScreen(),
                  ),
                ),
                GoRoute(
                  path: 'progress',
                  builder: (_, _) => const ProgressScreen(),
                ),
                GoRoute(
                  path: 'planner',
                  builder: (_, _) => const EngineeringPlannerScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/learn/course', builder: (_, _) => const CourseScreen()),
    GoRoute(
      path: '/lab',
      builder: (_, s) => CircuitLabScreen(
        topic: s.uri.queryParameters['topic'],
        initial: s.extra is CircuitExperiment
            ? s.extra as CircuitExperiment
            : null,
      ),
    ),
    GoRoute(path: '/notes', redirect: (_, _) => '/work/notes'),
    GoRoute(path: '/history', redirect: (_, _) => '/work/history'),
    GoRoute(path: '/favorites', redirect: (_, _) => '/work/favorites'),
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
    GoRoute(path: '/planner', redirect: (_, _) => '/work/planner'),
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
    final wide = MediaQuery.sizeOf(context).width >= 900;
    const icons = [
      Icons.home_outlined,
      Icons.calculate_outlined,
      Icons.folder_outlined,
    ];
    const labels = ['Home', 'Solve', 'My work'];
    if (wide) {
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
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationRailDestination(
                    icon: Icon(icons[i]),
                    label: Text(labels[i]),
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
        onDestinationSelected: shell.goBranch,
        destinations: [
          for (var i = 0; i < labels.length; i++)
            NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
        ],
      ),
    );
  }
}
