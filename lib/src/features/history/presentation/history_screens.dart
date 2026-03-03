import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../tools/domain/tool_registry.dart';
import '../data/history_repository.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This will remove all saved computations.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok != true) return;

    await ref.read(historyRepositoryProvider).clear();
    ref.invalidate(historyProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History cleared')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return AppScaffold(
      title: 'History',
      actions: [
        IconButton(
          tooltip: 'Clear',
          onPressed: () => _clear(context, ref),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
      body: history.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No history',
              message: 'Run any tool and your results will appear here.',
              icon: Icons.history,
            );
          }

          return ListView(
            children: [
              SectionCard(
                title: 'Recent computations',
                trailing: Text('${items.length}'),
                child: Column(
                  children: items.take(50).map((e) {
                    final tool = ToolRegistry.byId(e.toolId);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tool.title),
                      subtitle: Text(e.output),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/history/detail?id=${e.id}'),
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

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.entryId});
  final String entryId;

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    await ref.read(historyRepositoryProvider).delete(id);
    ref.invalidate(historyProvider);
    if (!context.mounted) return;
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return AppScaffold(
      title: 'History detail',
      body: history.when(
        data: (items) {
          final entry = items.where((e) => e.id == entryId).cast<HistoryEntry?>().firstWhere((e) => e != null, orElse: () => null);
          if (entry == null) {
            return const EmptyState(title: 'Not found', message: 'This entry no longer exists.', icon: Icons.error_outline);
          }

          final tool = ToolRegistry.byId(entry.toolId);

          return ListView(
            children: [
              SectionCard(
                title: tool.title,
                subtitle: entry.timestamp.toLocal().toString(),
                trailing: IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _delete(context, ref, entry.id),
                  icon: const Icon(Icons.delete_outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.output, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text('Inputs', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...entry.inputs.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(width: 120, child: Text(e.key)),
                          Expanded(child: Text(e.value)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.push('/tool/${tool.id}'),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Open tool'),
                    ),
                  ],
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