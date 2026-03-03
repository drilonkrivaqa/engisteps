import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../favorites/data/favorites_repository.dart';
import '../../history/data/history_repository.dart';
import '../../tools/domain/tool_registry.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _categoryIcons = <String, IconData>{
    'Circuits': Icons.bolt,
    'Electronics': Icons.memory,
    'Signals': Icons.multiline_chart,
    'Computer Arch': Icons.developer_board,
    'Physics': Icons.science,
    'Math': Icons.functions,
    'Stats': Icons.bar_chart,
    'Software': Icons.code,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final favoritesSet = ref.watch(favoritesProvider).whenData((ids) => ids.toSet());

    final categories = ToolRegistry.categories();

    return AppScaffold(
      title: 'Dashboard',
      body: ListView(
        children: [
          _HeroSearch(onTap: () => context.push('/search')),
          const SizedBox(height: 16),
          _buildOverview(context, history, favoritesSet),
          const SizedBox(height: 12),
          _quickActions(context),
          const SizedBox(height: 12),
          _buildFocusLane(context, history),
          const SizedBox(height: 12),
          _buildRecommendedCategories(context, categories),
          const SizedBox(height: 12),
          _buildFavoriteShortcuts(context, favoritesSet),
        ],
      ),
    );
  }

  Widget _buildOverview(
    BuildContext context,
    AsyncValue<List<HistoryEntry>> history,
    AsyncValue<Set<String>> favoritesSet,
  ) {
    return SectionCard(
      title: 'Your engineering pulse',
      subtitle: 'Track momentum, practice consistency, and jump back in fast.',
      child: history.when(
        data: (items) {
          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          final thisWeek = items.where((entry) => entry.timestamp.isAfter(weekAgo)).length;
          final dayStreak = _estimateStreak(items);

          return favoritesSet.when(
            data: (favorites) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.local_fire_department,
                        label: 'Current streak',
                        value: '$dayStreak days',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.insights,
                        label: 'Sessions this week',
                        value: '$thisWeek',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.favorite,
                        label: 'Saved tools',
                        value: '${favorites.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.grid_view,
                        label: 'Total calculators',
                        value: '${ToolRegistry.tools.length}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Favorites unavailable: $e'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('History unavailable: $e'),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return SectionCard(
      title: 'Quick actions',
      subtitle: 'Start common tasks in one tap.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () => context.go('/tools'),
            icon: const Icon(Icons.construction),
            label: const Text('Open tools'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.history),
            label: const Text('View history'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => context.go('/favorites'),
            icon: const Icon(Icons.favorite_border),
            label: const Text('Favorites'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/settings/preferences'),
            icon: const Icon(Icons.tune),
            label: const Text('Preferences'),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusLane(BuildContext context, AsyncValue<List<HistoryEntry>> history) {
    return SectionCard(
      title: 'Focus lane',
      subtitle: 'Context-aware recommendations based on your latest sessions.',
      child: history.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No activity yet',
              message: 'Run your first calculation and we will tailor this lane for you.',
            );
          }

          final latest = items.first;
          final recentTool = ToolRegistry.byId(latest.toolId);
          final sameCategory = ToolRegistry.tools
              .where((tool) => tool.category == recentTool.category && tool.id != recentTool.id)
              .take(2)
              .toList();

          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.play_arrow_rounded)),
                title: Text('Continue ${recentTool.title}'),
                subtitle: Text('Last output: ${latest.output}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/tool/${recentTool.id}'),
              ),
              for (final tool in sameCategory)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.explore_outlined)),
                  title: Text('Try next: ${tool.title}'),
                  subtitle: Text('${tool.category} • ${tool.subcategory}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/tool/${tool.id}'),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('History unavailable: $e'),
      ),
    );
  }

  Widget _buildRecommendedCategories(BuildContext context, List<String> categories) {
    return SectionCard(
      title: 'Explore by domain',
      subtitle: 'A cleaner way to navigate your engineering tool stack.',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.3,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final icon = _categoryIcons[category] ?? Icons.category;
          final categoryCount = ToolRegistry.tools.where((tool) => tool.category == category).length;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/tools/category/$category'),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(icon),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category, style: Theme.of(context).textTheme.titleSmall),
                          Text('$categoryCount tools', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteShortcuts(BuildContext context, AsyncValue<Set<String>> favoritesSet) {
    return SectionCard(
      title: 'Favorite shortcuts',
      subtitle: 'One-tap access to your pinned calculators.',
      child: favoritesSet.when(
        data: (ids) {
          if (ids.isEmpty) {
            return const EmptyState(
              title: 'No favorites yet',
              message: 'Pin a tool and it will show up here for quick launch.',
            );
          }

          final tools = ToolRegistry.tools.where((tool) => ids.contains(tool.id)).take(4);

          return Column(
            children: tools
                .map(
                  (tool) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.favorite, color: Colors.redAccent)),
                    title: Text(tool.title),
                    subtitle: Text('${tool.category} • ${tool.subcategory}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/tool/${tool.id}'),
                  ),
                )
                .toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Favorites unavailable: $e'),
      ),
    );
  }

  int _estimateStreak(List<HistoryEntry> items) {
    if (items.isEmpty) return 0;

    final byDay = items
        .map((entry) => DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    for (final day in byDay) {
      if (day == cursor || day == cursor.subtract(Duration(days: streak))) {
        streak++;
      } else if (day.isBefore(cursor.subtract(Duration(days: streak)))) {
        break;
      }
    }

    return streak;
  }
}

class _HeroSearch extends StatelessWidget {
  const _HeroSearch({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Build faster. Solve smarter.', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Search calculators, continue workflows, and keep your study momentum high.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          SearchBar(
            hintText: 'Find a tool or topic...',
            onTap: onTap,
            readOnly: true,
            enabled: true,
            leading: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
