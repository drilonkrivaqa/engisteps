import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/tool.dart';
import '../../favorites/data/favorites_repository.dart';
import '../../history/data/history_repository.dart';
import '../domain/tool_registry.dart';

final _searchProvider = StateProvider<String>((ref) => '');

class ToolsHomeScreen extends ConsumerWidget {
  const ToolsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_searchProvider).toLowerCase();
    final favorites = ref.watch(favoritesProvider);
    final history = ref.watch(historyProvider);
    final filtered = ToolRegistry.tools.where((t) {
      return t.title.toLowerCase().contains(query) || t.category.toLowerCase().contains(query);
    }).toList();
    final categories = ToolRegistry.categories();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('EngiSteps', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text('Offline-first engineering toolkit'),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search tools, formulas, topics'),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Favorites'),
          if (favorites.isEmpty)
            const Text('No favorites yet.')
          else
            Wrap(
              spacing: 8,
              children: favorites.take(6).map((id) => ActionChip(label: Text(ToolRegistry.byId(id).title), onPressed: () => context.push('/tool/$id'))).toList(),
            ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Recent tools'),
          if (history.isEmpty)
            const Text('No recent calculations yet.')
          else
            ...history.take(3).map((h) => ListTile(title: Text(ToolRegistry.byId(h.toolId).title), subtitle: Text(h.output), onTap: () => context.push('/tool/${h.toolId}'))),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Categories'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories
                .map((c) => FilterChip(label: Text(c), selected: false, onSelected: (_) => ref.read(_searchProvider.notifier).state = c))
                .toList(),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Toolbox'),
          ...filtered.map(
            (tool) => Card(
              child: ListTile(
                title: Text(tool.title),
                subtitle: Text('${tool.category} • ${tool.description}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/tool/${tool.id}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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
  final Map<String, TextEditingController> _controllers = {};
  ToolResult? _result;
  bool _showSteps = false;
  bool _explain = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tool = ToolRegistry.byId(widget.toolId);
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains(tool.id);

    for (final input in tool.inputs) {
      _controllers.putIfAbsent(input.key, () => TextEditingController(text: input.defaultValue ?? ''));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tool.title),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.star : Icons.star_border),
            onPressed: () => ref.read(favoritesProvider.notifier).toggle(tool.id),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tool.description),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Explain'),
            value: _explain,
            onChanged: (v) => setState(() => _explain = v),
          ),
          if (_explain && tool.explain != null) Text(tool.explain!),
          const SizedBox(height: 8),
          ...tool.inputs.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _controllers[i.key],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(labelText: i.label, hintText: i.hint),
                ),
              )),
          FilledButton(
            onPressed: () {
              final inputs = <String, double>{};
              for (final i in tool.inputs) {
                final value = double.tryParse(_controllers[i.key]!.text);
                if (value == null && i.required) return;
                if (value != null) inputs[i.key] = value;
              }
              setState(() => _result = tool.compute(inputs));
            },
            child: const Text('Solve'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 14),
            Card(child: ListTile(title: const Text('Result'), subtitle: Text(_result!.mainResult))),
            ..._result!.secondaryResults.map((e) => ListTile(title: Text(e.key), subtitle: Text(e.value))),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _showSteps = !_showSteps),
                  icon: const Icon(Icons.rule),
                  label: Text(_showSteps ? 'Hide steps' : 'Show steps'),
                ),
                TextButton.icon(
                  onPressed: () => Clipboard.setData(ClipboardData(text: _composeCopy(tool, _result!))),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy result'),
                ),
              ],
            ),
            if (_showSteps)
              ..._result!.steps.map((s) => ListTile(leading: const Icon(Icons.chevron_right), title: Text(s))),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(historyProvider.notifier).add(
                      HistoryEntry(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        toolId: tool.id,
                        timestamp: DateTime.now(),
                        inputs: {for (final i in tool.inputs) i.key: _controllers[i.key]!.text},
                        output: _result!.mainResult,
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to history')));
              },
              icon: const Icon(Icons.history),
              label: const Text('Save to history'),
            )
          ]
        ],
      ),
    );
  }

  String _composeCopy(Tool tool, ToolResult result) {
    return '${tool.title}\n${result.mainResult}\n${result.secondaryResults.map((e) => '${e.key}: ${e.value}').join('\n')}';
  }
}
