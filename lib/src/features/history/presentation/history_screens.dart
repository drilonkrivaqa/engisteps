import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../tools/domain/tool_registry.dart';
import '../data/history_repository.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text('History', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              TextButton(onPressed: () => ref.read(historyProvider.notifier).clear(), child: const Text('Clear'))
            ],
          ),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('No saved solves yet.'),
            ),
          ...history.map((entry) {
            final tool = ToolRegistry.byId(entry.toolId);
            return Card(
              child: ListTile(
                title: Text(tool.title),
                subtitle: Text('${entry.output}\n${DateFormat('MMM d, HH:mm').format(entry.timestamp)}'),
                isThreeLine: true,
                onTap: () => context.push('/tool/${entry.toolId}'),
              ),
            );
          }),
        ],
      ),
    );
  }
}
