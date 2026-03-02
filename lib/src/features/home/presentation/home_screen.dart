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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final favorites = ref.watch(favoritesProvider);
    final categories = ToolRegistry.tools.map((e) => e.category).toSet().toList()..sort();

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
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/tools/category/$category'),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Center(child: Text(category, style: Theme.of(context).textTheme.titleSmall)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Continue / Recent',
            child: history.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(title: 'No recent tools', message: 'Your computations will appear here.');
                }
                return Column(
                  children: items.take(4).map((entry) {
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
                  children: tools.take(4).map((tool) {
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
