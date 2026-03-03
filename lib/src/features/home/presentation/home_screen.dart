import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/tool.dart';
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
    final favorites = ref.watch(favoritesProvider);

    final categories = ToolRegistry.categories();
    final countsByCategory = <String, int>{
      for (final c in categories) c: ToolRegistry.tools.where((t) => t.category == c).length,
    };

    return AppScaffold(
      title: 'EngiSteps',
      actions: [
        IconButton(
          tooltip: 'Search',
          onPressed: () => context.push('/search'),
          icon: const Icon(Icons.search),
        ),
        IconButton(
          tooltip: 'History',
          onPressed: () => context.push('/history'),
          icon: const Icon(Icons.history),
        ),
      ],
      body: ListView(
        children: [
          _CommandCenterCard(
            totalTools: ToolRegistry.tools.length,
            totalCategories: categories.length,
            coreTools: ToolRegistry.tools.where((t) => t.isCore).length,
            onExploreTools: () => context.push('/tools'),
            onOpenFavorites: () => context.push('/favorites'),
          ),
          const SizedBox(height: 12),
          _WorkflowSection(history: history, favorites: favorites),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Categories',
            subtitle: 'Open the right toolkit for your current problem domain.',
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.6,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final icon = _categoryIcons[category] ?? Icons.category;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/tools/category/$category'),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(child: Icon(icon)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category, style: Theme.of(context).textTheme.titleSmall),
                                Text('${countsByCategory[category]} tools', style: Theme.of(context).textTheme.bodySmall),
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
          ),
          const SizedBox(height: 12),
          _ContinueSection(history: history),
          const SizedBox(height: 12),
          _FavoriteShortcutsSection(favorites: favorites),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _CommandCenterCard extends StatelessWidget {
  const _CommandCenterCard({
    required this.totalTools,
    required this.totalCategories,
    required this.coreTools,
    required this.onExploreTools,
    required this.onOpenFavorites,
  });

  final int totalTools;
  final int totalCategories;
  final int coreTools;
  final VoidCallback onExploreTools;
  final VoidCallback onOpenFavorites;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Engineering command center',
      subtitle: 'Plan, compute, and verify faster with a workflow-first experience.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statChip(context, '$totalTools tools', Icons.calculate_outlined),
              _statChip(context, '$totalCategories domains', Icons.grid_view_outlined),
              _statChip(context, '$coreTools core calculators', Icons.star_outline),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onExploreTools,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Open tool workspace'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenFavorites,
                icon: const Icon(Icons.favorite_border),
                label: const Text('My shortcuts'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection({required this.history, required this.favorites});

  final AsyncValue<List<HistoryEntry>> history;
  final AsyncValue<Set<String>> favorites;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Guided workflows',
      subtitle: 'Start from a goal and jump directly into a relevant sequence of tools.',
      child: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (items) {
          final favIds = favorites.maybeWhen(data: (v) => v, orElse: () => <String>{});
          final workflows = _buildWorkflows(items, favIds);

          return Column(
            children: workflows.map((flow) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(flow.icon)),
                  title: Text(flow.title),
                  subtitle: Text(flow.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/tool/${flow.startingToolId}'),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  List<_WorkflowPlan> _buildWorkflows(List<HistoryEntry> historyEntries, Set<String> favIds) {
    final recentTools = historyEntries
        .take(10)
        .map((e) => ToolRegistry.byId(e.toolId))
        .toList();

    final mostRecentCategory = recentTools.isEmpty ? null : recentTools.first.category;
    final focusCategory = mostRecentCategory ?? 'Circuits';

    final categoryAnchor = ToolRegistry.tools.firstWhere(
      (t) => t.category == focusCategory,
      orElse: () => ToolRegistry.tools.first,
    );

    final favoriteAnchor = ToolRegistry.tools.firstWhere(
      (t) => favIds.contains(t.id),
      orElse: () => ToolRegistry.tools.first,
    );

    return [
      _WorkflowPlan(
        title: 'Exam prep sprint',
        description: 'Start with ${categoryAnchor.category} fundamentals and iterate through solved scenarios.',
        startingToolId: categoryAnchor.id,
        icon: Icons.timer_outlined,
      ),
      _WorkflowPlan(
        title: 'Lab validation flow',
        description: 'Use your favorite calculators first, then cross-check with tool history.',
        startingToolId: favoriteAnchor.id,
        icon: Icons.science_outlined,
      ),
      _WorkflowPlan(
        title: 'Design review checklist',
        description: 'Open a high-impact core tool and verify assumptions before finalizing.',
        startingToolId: ToolRegistry.tools.firstWhere((t) => t.isCore, orElse: () => ToolRegistry.tools.first).id,
        icon: Icons.fact_check_outlined,
      ),
    ];
  }
}

class _ContinueSection extends StatelessWidget {
  const _ContinueSection({required this.history});

  final AsyncValue<List<HistoryEntry>> history;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Continue',
      subtitle: 'Pick up where you left off in one tap.',
      child: history.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Nothing to continue',
              message: 'Run a tool once and it appears here.',
              icon: Icons.play_circle_outline,
            );
          }

          final latest = items.first;
          final tool = ToolRegistry.byId(latest.toolId);

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.play_arrow_rounded)),
            title: Text(tool.title),
            subtitle: Text('Last result: ${latest.output}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tool/${tool.id}'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }
}

class _FavoriteShortcutsSection extends StatelessWidget {
  const _FavoriteShortcutsSection({required this.favorites});

  final AsyncValue<Set<String>> favorites;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Favorites',
      subtitle: 'Your personal shortcut shelf for repetitive work.',
      child: favorites.when(
        data: (ids) {
          if (ids.isEmpty) {
            return const EmptyState(
              title: 'No favorites yet',
              message: 'Save tools you use a lot.',
              icon: Icons.favorite_border,
            );
          }

          final tools = ToolRegistry.tools.where((t) => ids.contains(t.id)).toList()
            ..sort((a, b) => b.popularity.compareTo(a.popularity));

          return Column(
            children: tools.take(6).map((tool) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tool.title),
                subtitle: Text(tool.category),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/tool/${tool.id}'),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }
}

class _WorkflowPlan {
  const _WorkflowPlan({
    required this.title,
    required this.description,
    required this.startingToolId,
    required this.icon,
  });

  final String title;
  final String description;
  final String startingToolId;
  final IconData icon;
}
