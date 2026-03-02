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

  static const _categoryIcons = {
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
    final categories = ToolRegistry.tools.map((e) => e.category).toSet().toList()..sort();
    final countsByCategory = <String, int>{
      for (final category in categories) category: ToolRegistry.tools.where((tool) => tool.category == category).length,
    };

    return AppScaffold(
      title: 'Home',
      body: ListView(
        children: [
          SearchBar(
            hintText: 'Search tools...',
            onTap: () => context.push('/search'),
            enabled: true,
            readOnly: true,
            leading: const Icon(Icons.search),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Categories',
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.6,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final icon = _categoryIcons[category] ?? Icons.category;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/tools/category/$category'),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
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
                  return const EmptyState(title: 'Nothing to continue', message: 'Run a tool once and it appears here.');
                }
                final latest = items.first;
                final tool = ToolRegistry.byId(latest.toolId);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tool.title),
                  subtitle: Text('Last result: ${latest.output}'),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () => context.push('/tool/${tool.id}'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Recents',
            child: history.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(title: 'No recent tools', message: 'Your computations will appear here.');
                }
                return Column(
                  children: items.take(5).map((entry) {
                    final tool = ToolRegistry.byId(entry.toolId);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tool.title),
                      subtitle: Text(entry.output),
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
          const SizedBox(height: 12),
          SectionCard(
            title: 'Favorites',
            child: favorites.when(
              data: (ids) {
                if (ids.isEmpty) {
                  return const EmptyState(title: 'No favorites yet', message: 'Save tools to access them faster.');
                }
                final tools = ToolRegistry.tools.where((t) => ids.contains(t.id)).toList();
                return Column(
                  children: tools.take(5).map((tool) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tool.title),
                      subtitle: Text(tool.category),
                      trailing: const Icon(Icons.favorite, color: Colors.redAccent),
                      onTap: () => context.push('/tool/${tool.id}'),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ),
        ],
      ),
    );
  }
}
