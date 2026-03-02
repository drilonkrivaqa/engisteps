import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tools/domain/tool_registry.dart';
import '../data/favorites_repository.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final presets = ref.watch(favoritePresetsProvider);
    return AppScaffold(
      title: 'Favorites',
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(tabs: [Tab(text: 'Tools'), Tab(text: 'Presets')]),
            Expanded(
              child: TabBarView(
                children: [
                  favorites.when(
                    data: (ids) {
                      if (ids.isEmpty) {
                        return const EmptyState(title: 'No favorites', message: 'Tap heart on any tool to save it.');
                      }
                      final tools = ToolRegistry.tools.where((t) => ids.contains(t.id)).toList();
                      return ListView(
                        children: tools
                            .map((t) => ListTile(title: Text(t.title), subtitle: Text(t.category), onTap: () => context.push('/tool/${t.id}')))
                            .toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                  presets.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const EmptyState(title: 'No presets yet', message: 'Save preset values from any tool detail page.');
                      }
                      return ListView(
                        children: items
                            .map((p) => ListTile(
                                  title: Text(p.name),
                                  subtitle: Text('${ToolRegistry.byId(p.toolId).title} • ${p.values.entries.map((e) => '${e.key}=${e.value}').join(', ')}'),
                                  onTap: () => context.push('/tool/${p.toolId}'),
                                ))
                            .toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PresetManagerScreen extends ConsumerWidget {
  const PresetManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(favoritePresetsProvider);
    return AppScaffold(
      title: 'Preset manager',
      body: presets.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(title: 'No presets yet', message: 'Rename/reorder/delete controls will appear after saving presets.');
          }
          return ListView(
            children: items.map((p) => ListTile(title: Text(p.name), subtitle: Text(ToolRegistry.byId(p.toolId).title))).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
