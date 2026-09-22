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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Saved calculations',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (history.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        final clear = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear saved calculations?'),
                            content: const Text(
                              'This removes all saved calculations from this device.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Keep them'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Clear all'),
                              ),
                            ],
                          ),
                        );
                        if (clear == true) {
                          try {
                            await ref.read(historyProvider.notifier).clear();
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not clear history. Please retry.',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Clear all'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep your working. Revisit an idea. Try another scenario.',
              ),
              const SizedBox(height: 24),
              if (history.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.history, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Your next insight starts with a calculation.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.go('/tools'),
                          child: const Text('Explore tools'),
                        ),
                      ],
                    ),
                  ),
                ),
              ...history.map((entry) {
                final tool = ToolRegistry.find(entry.toolId);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(
                        tool?.title ?? 'Archived tool: ${entry.toolId}',
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${entry.output}\n${DateFormat('MMM d, yyyy · HH:mm').format(entry.timestamp)}',
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: tool == null
                          ? null
                          : () => context.push(
                              '/tool/${entry.toolId}',
                              extra: entry,
                            ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
