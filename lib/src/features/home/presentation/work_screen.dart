import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../history/data/history_repository.dart';
import '../../learn/presentation/student_home_screen.dart';

class WorkScreen extends ConsumerWidget {
  const WorkScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('My work')),
    body: StudentPage(
      children: [
        const Text('Everything you keep, in one place.'),
        const SizedBox(height: 20),
        StudentLink(
          title: 'Saved calculations',
          subtitle:
              '${ref.watch(historyProvider).length} saved · open, copy or recalculate',
          icon: Icons.history,
          onTap: () => context.push('/work/history'),
        ),
        StudentLink(
          title: 'My notes',
          subtitle: 'Keep your working and explanations.',
          icon: Icons.note_alt_outlined,
          onTap: () => context.push('/work/notes'),
        ),
        StudentLink(
          title: 'Favorite tools',
          subtitle: 'Shortcuts to the calculators you use most.',
          icon: Icons.star_outline,
          onTap: () => context.push('/work/favorites'),
        ),
        StudentLink(
          title: 'Learning progress',
          subtitle: 'See what you’ve completed and what needs practice.',
          icon: Icons.insights,
          onTap: () => context.push('/work/progress'),
        ),
        StudentLink(
          title: 'Study planner',
          subtitle: 'Organize your study tasks.',
          icon: Icons.event_note_outlined,
          onTap: () => context.push('/work/planner'),
        ),
      ],
    ),
  );
}
