import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/history_repository.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return AppScaffold(
      title: 'History',
      actions: [
        IconButton(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Clear history?'),
                content: const Text('This cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(historyRepositoryProvider).clear();
              ref.invalidate(historyProvider);
            }
          },
          icon: const Icon(Icons.delete_outline),
        ),
      ],
      body: history.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(title: 'No history', message: 'Computed results are stored here grouped by date.');
          }
          return ListView(
            children: items
                .map((e) => ListTile(
                      title: Text(e.output),
                      subtitle: Text('${DateFormat.yMMMd().format(e.timestamp)} • ${e.toolId}'),
                    ))
                .toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class HistoryDetailScreen extends StatelessWidget { const HistoryDetailScreen({super.key}); @override Widget build(BuildContext context)=>const AppScaffold(title:'History Detail',body:Text('History detail placeholder.')); }
