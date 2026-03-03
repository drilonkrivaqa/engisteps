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
          SectionCard(
            title: 'Quick actions',
            subtitle: 'What do you want to do right now?',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => context.push('/tools'),
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Browse tools'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/favorites'),
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Favorites'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Categories',
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
          SectionCard(
            title: 'Continue',
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
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Favorites',
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
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}