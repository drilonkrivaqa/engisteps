import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/tool.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/input_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/result_card.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/tool_list_tile.dart';
import '../../favorites/data/favorites_repository.dart';
import '../../history/data/history_repository.dart';
import '../domain/tool_registry.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ToolRegistry.tools.map((e) => e.category).toSet().toList();
    return AppScaffold(
      title: 'Tools',
      body: ListView(
        children: [
          for (final c in categories)
            Card(
              child: ListTile(
                title: Text(c),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/tools/category/$c'),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final tools = ToolRegistry.tools.where((t) => t.category == category).toList();
    return AppScaffold(
      title: category,
      body: ListView(
        children: [
          const SectionCard(title: 'Filter / Sort', child: Text('Filter/sort placeholder UI')),
          const SizedBox(height: 12),
          ...tools.map((t) => ToolListTile(tool: t, onTap: () => context.push('/tool/${t.id}'))),
        ],
      ),
    );
  }
}

class ToolDetailScreen extends ConsumerStatefulWidget {
  const ToolDetailScreen({super.key, required this.toolId});
  final String toolId;

  @override
  ConsumerState<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends ConsumerState<ToolDetailScreen> {
  ToolResult? result;
  late final Tool tool;
  late final Map<String, TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    tool = ToolRegistry.byId(widget.toolId);
    controllers = {for (final i in tool.inputs) i.key: TextEditingController(text: i.defaultValue)};
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _compute() async {
    final inputs = <String, double>{};
    for (final e in controllers.entries) {
      inputs[e.key] = double.tryParse(e.value.text) ?? double.nan;
    }
    final computed = tool.compute(inputs);
    setState(() => result = computed);
    await ref.read(historyRepositoryProvider).add(HistoryEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          toolId: tool.id,
          timestamp: DateTime.now(),
          inputs: {for (final e in controllers.entries) e.key: e.value.text},
          output: computed.mainResult,
        ));
    ref.invalidate(historyProvider);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: tool.title,
      actions: [
        IconButton(
          onPressed: () async {
            await ref.read(favoritesRepositoryProvider).toggleFavorite(tool.id);
            ref.invalidate(favoritesProvider);
          },
          icon: const Icon(Icons.favorite_border),
        ),
      ],
      body: ListView(
        children: [
          SectionCard(
            title: 'Inputs',
            subtitle: tool.description,
            child: Column(
              children: [
                for (final input in tool.inputs) ...[
                  InputField(controller: controllers[input.key]!, label: input.label, hint: input.hint),
                  const SizedBox(height: 8),
                ],
                PrimaryButton(label: 'Compute', onPressed: _compute),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ResultCard(result: result),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(onPressed: () => context.push('/tool/${tool.id}/steps'), child: const Text('Steps')),
              OutlinedButton(onPressed: () => context.push('/tool/${tool.id}/info'), child: const Text('Info')),
              OutlinedButton(onPressed: () => context.push('/tool/${tool.id}/graph'), child: const Text('Graph')),
              OutlinedButton(onPressed: () => context.push('/tool/${tool.id}/history'), child: const Text('History')),
              OutlinedButton(onPressed: () => context.push('/share-export'), child: const Text('Share')),
            ],
          ),
        ],
      ),
    );
  }
}

class ToolStepsScreen extends StatelessWidget { const ToolStepsScreen({super.key}); @override Widget build(BuildContext context)=>const AppScaffold(title:'Tool Steps',body:SectionCard(title:'Step-by-step',child:Text('Steps placeholder, collapsed by default in production widgets.'))); }
class ToolInfoScreen extends StatelessWidget { const ToolInfoScreen({super.key}); @override Widget build(BuildContext context)=>const AppScaffold(title:'Tool Info / Formula',body:SectionCard(title:'Reference',child:Text('Formula and assumptions placeholder.'))); }
class ToolGraphScreen extends StatelessWidget { const ToolGraphScreen({super.key}); @override Widget build(BuildContext context)=>const AppScaffold(title:'Tool Graph',body:SectionCard(title:'Graph',child:Text('Graph placeholder page for graph-capable tools.'))); }

class PerToolHistoryScreen extends ConsumerWidget {
  const PerToolHistoryScreen({super.key, required this.toolId});
  final String toolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return AppScaffold(
      title: 'Tool History',
      body: history.when(
        data: (items) {
          final filtered = items.where((e) => e.toolId == toolId).toList();
          if (filtered.isEmpty) return const Center(child: Text('No history for this tool yet.'));
          return ListView(children: filtered.map((e) => ListTile(title: Text(e.output), subtitle: Text(e.timestamp.toIso8601String()))).toList());
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
