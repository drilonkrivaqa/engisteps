import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
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
      actions: [
        IconButton(
          tooltip: 'Presets',
          onPressed: () => context.push('/favorites/presets'),
          icon: const Icon(Icons.bookmarks_outlined),
        ),
      ],
      body: ListView(
        children: [
          favorites.when(
            data: (ids) {
              final tools = ToolRegistry.tools.where((t) => ids.contains(t.id)).toList()
                ..sort((a, b) => b.popularity.compareTo(a.popularity));

              if (tools.isEmpty) {
                return const EmptyState(
                  title: 'No favorites yet',
                  message: 'Open any tool and tap the heart icon.',
                  icon: Icons.favorite_border,
                );
              }

              return SectionCard(
                title: 'Favorite tools',
                trailing: Text('${tools.length}'),
                child: Column(
                  children: tools
                      .map((t) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.favorite),
                    title: Text(t.title),
                    subtitle: Text('${t.category} • ${t.subcategory}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/tool/${t.id}'),
                  ))
                      .toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          const SizedBox(height: 12),
          presets.when(
            data: (items) {
              if (items.isEmpty) {
                return const SectionCard(
                  title: 'Presets',
                  subtitle: 'Save your lab defaults and reuse them fast.',
                  child: Text('No presets saved yet.'),
                );
              }

              return SectionCard(
                title: 'Presets',
                trailing: Text('${items.length}'),
                child: Column(
                  children: items.take(6).map((p) {
                    final tool = ToolRegistry.byId(p.toolId);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.name),
                      subtitle: Text(tool.title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/tool/${tool.id}'),
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}

class PresetManagerScreen extends ConsumerWidget {
  const PresetManagerScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    await ref.read(favoritesRepositoryProvider).deletePreset(id);
    ref.invalidate(favoritePresetsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset deleted')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(favoritePresetsProvider);

    return AppScaffold(
      title: 'Presets',
      body: presets.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No presets',
              message: 'Open a tool → Save preset.',
              icon: Icons.bookmark_add_outlined,
            );
          }

          return ListView(
            children: [
              SectionCard(
                title: 'Your presets',
                trailing: Text('${items.length}'),
                child: Column(
                  children: items.map((p) {
                    final tool = ToolRegistry.byId(p.toolId);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.name),
                      subtitle: Text(tool.title),
                      trailing: IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(context, ref, p.id),
                      ),
                      onTap: () => context.push('/tool/${tool.id}'),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}