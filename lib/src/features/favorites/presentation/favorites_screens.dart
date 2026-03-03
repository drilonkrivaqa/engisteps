import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tools/domain/tool_registry.dart';
import '../data/favorites_repository.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoritesProvider);
    return SafeArea(
      child: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ids.length + 1,
        onReorder: (oldIndex, newIndex) {
          if (oldIndex == 0 || newIndex == 0) return;
          ref.read(favoritesProvider.notifier).reorder(oldIndex - 1, newIndex - 1);
        },
        itemBuilder: (context, index) {
          if (index == 0) {
            return const ListTile(key: ValueKey('header'), title: Text('Favorites'), subtitle: Text('Starred tools, drag to reorder'));
          }
          final id = ids[index - 1];
          final tool = ToolRegistry.byId(id);
          return Card(
            key: ValueKey(id),
            child: ListTile(
              title: Text(tool.title),
              subtitle: Text(tool.category),
              trailing: const Icon(Icons.drag_handle),
              onTap: () => context.push('/tool/${tool.id}'),
            ),
          );
        },
      ),
    );
  }
}
