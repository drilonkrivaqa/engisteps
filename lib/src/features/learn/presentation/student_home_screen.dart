import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/learning_repository.dart';
import '../domain/circuit_course.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('EngiSteps'),
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.tune),
        ),
      ],
    ),
    body: ref
        .watch(learningProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(learningProvider),
              child: const Text('Retry loading progress'),
            ),
          ),
          data: (progress) => StudentPage(
            children: [
              Text(
                'Engineering, one step at a time.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Learn a method, use it to solve a problem, and keep your work here.',
              ),
              const SizedBox(height: 24),
              _NextStep(progress: progress),
              const SizedBox(height: 24),
              const Text(
                'Explore at your own pace',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              StudentLink(
                title: 'Browse lessons',
                subtitle: 'Series, parallel and voltage-divider circuits.',
                icon: Icons.school_outlined,
                onTap: () => context.push('/learn/course'),
              ),
              StudentLink(
                title: 'Experiment with a circuit',
                subtitle: 'Change a value. See why the answer changes.',
                icon: Icons.tune,
                onTap: () => context.push('/lab'),
              ),
            ],
          ),
        ),
  );
}

class _NextStep extends StatelessWidget {
  const _NextStep({required this.progress});
  final LearningProgress progress;
  @override
  Widget build(BuildContext context) {
    final next = progress.next;
    final first = progress.attempts.isEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF123A46),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            first ? 'START HERE · ABOUT 5 MINUTES' : 'YOUR NEXT STEP',
            style: const TextStyle(
              color: Color(0xFFA3E7D6),
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            first
                ? 'Solve your first circuit'
                : next?.title ?? 'You’ve finished the course',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            first
                ? 'We’ll show you the circuit, help you choose a method, and check your answer.'
                : next == null
                ? 'Revisit a lesson or try changing the circuit in the lab.'
                : '${next.topic.title} · ${next.guided ? 'Learn with guidance' : 'Put your understanding into practice'}.',
            style: const TextStyle(color: Color(0xFFD3E9E7), height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: () => next == null
                ? context.push('/lab')
                : context.push('/learn/problem/${next.id}'),
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              first
                  ? 'Start guided lesson'
                  : next == null
                  ? 'Open circuit lab'
                  : 'Continue learning',
            ),
          ),
        ],
      ),
    );
  }
}

class CourseScreen extends ConsumerWidget {
  const CourseScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Circuit fundamentals'),
      leading: BackButton(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/learn'),
      ),
    ),
    body: StudentPage(
      children: [
        Text(
          'A clear path from example to practice.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Start with series circuits, then explore branches and voltage dividers. Each topic has one guided example and four practice problems.',
        ),
        const SizedBox(height: 20),
        for (final topic in circuitTopics)
          StudentLink(
            title: '${circuitTopics.indexOf(topic) + 1}. ${topic.title}',
            subtitle: topic.outcome,
            icon: Icons.school_outlined,
            onTap: () => context.push('/learn/topic/${topic.id}'),
          ),
      ],
    ),
  );
}

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Learning progress')),
    body: ref
        .watch(learningProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(learningProvider),
              child: const Text('Retry'),
            ),
          ),
          data: (p) => StudentPage(
            children: [
              Text(
                '${p.independentCount} of 12 solved without help',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: p.independentCount / 12,
                minHeight: 8,
              ),
              const SizedBox(height: 12),
              const Text(
                'Based on your latest attempts. Completing a guided example does not count as independent practice.',
              ),
              const SizedBox(height: 24),
              if (p.review.isNotEmpty) ...[
                const Text(
                  'Worth another try',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final problem in p.review)
                  StudentLink(
                    title: problem.title,
                    subtitle:
                        'Completed with help · review your working and retry',
                    icon: Icons.replay,
                    onTap: () => context.push('/learn/problem/${problem.id}'),
                  ),
              ],
              for (final topic in circuitTopics)
                StudentLink(
                  title: topic.title,
                  subtitle:
                      '${topic.problems.where((q) => p.attempt(q.id).completed).length} of 5 activities complete',
                  icon: Icons.school_outlined,
                  onTap: () => context.push('/learn/topic/${topic.id}'),
                ),
            ],
          ),
        ),
  );
}

class StudentPage extends StatelessWidget {
  const StudentPage({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 850),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: children,
      ),
    ),
  );
}

class StudentLink extends StatelessWidget {
  const StudentLink({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
