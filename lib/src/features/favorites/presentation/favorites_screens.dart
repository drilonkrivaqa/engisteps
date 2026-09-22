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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your essentials',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Favorite tools, in your order. Drag a handle to rearrange.',
                    ),
                  ],
                ),
              ),
              if (ids.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_border_rounded, size: 48),
                        const SizedBox(height: 16),
                        const Text('Keep the tools you reach for close.'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.go('/tools'),
                          child: const Text('Find your first favorite'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    buildDefaultDragHandles: false,
                    itemCount: ids.length,
                    onReorder: (oldIndex, newIndex) => ref
                        .read(favoritesProvider.notifier)
                        .reorder(oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final tool = ToolRegistry.find(ids[index]);
                      return Card(
                        key: ValueKey(ids[index]),
                        child: ListTile(
                          leading: const Icon(Icons.star_rounded),
                          title: Text(tool?.title ?? 'Unavailable tool'),
                          subtitle: Text(tool?.category ?? ids[index]),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                          onTap: tool == null
                              ? null
                              : () => context.push('/tool/${tool.id}'),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
