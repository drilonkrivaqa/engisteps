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
    final categories = ToolRegistry.tools.map((e) => e.category).toSet().toList()..sort();
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

enum ToolSort { popular, az, recent }

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.category});
  final String category;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final _searchController = TextEditingController();
  ToolSort _sort = ToolSort.popular;
  bool _filterHasSteps = false;
  bool _filterHasGraph = false;
  bool _filterCore = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);
    final recentIds = historyAsync.maybeWhen(
      data: (items) => items.map((e) => e.toolId).toList(),
      orElse: () => <String>[],
    );

    final query = _searchController.text.trim().toLowerCase();
    var tools = ToolRegistry.tools.where((t) => t.category == widget.category).where((tool) {
      final matchesQuery = query.isEmpty || tool.title.toLowerCase().contains(query) || tool.description.toLowerCase().contains(query);
      final matchesSteps = !_filterHasSteps || tool.compute({for (final i in tool.inputs) i.key: 1}).steps.isNotEmpty;
      final matchesGraph = !_filterHasGraph || tool.hasGraph;
      final matchesCore = !_filterCore || tool.isCore;
      return matchesQuery && matchesSteps && matchesGraph && matchesCore;
    }).toList();

    switch (_sort) {
      case ToolSort.popular:
        tools.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
      case ToolSort.az:
        tools.sort((a, b) => a.title.compareTo(b.title));
        break;
      case ToolSort.recent:
        tools.sort((a, b) {
          final aIdx = recentIds.indexOf(a.id);
          final bIdx = recentIds.indexOf(b.id);
          if (aIdx == -1 && bIdx == -1) return a.title.compareTo(b.title);
          if (aIdx == -1) return 1;
          if (bIdx == -1) return -1;
          return aIdx.compareTo(bIdx);
        });
        break;
    }

    final grouped = <String, List<Tool>>{};
    for (final tool in tools) {
      grouped.putIfAbsent(tool.subcategory, () => []).add(tool);
    }

    return AppScaffold(
      title: widget.category,
      body: ListView(
        children: [
          SectionCard(
            title: 'Search / Sort / Filter',
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search in this category'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ToolSort>(
                  value: _sort,
                  decoration: const InputDecoration(labelText: 'Sort'),
                  items: const [
                    DropdownMenuItem(value: ToolSort.popular, child: Text('Popular')),
                    DropdownMenuItem(value: ToolSort.az, child: Text('A–Z')),
                    DropdownMenuItem(value: ToolSort.recent, child: Text('Recently used')),
                  ],
                  onChanged: (v) => setState(() => _sort = v ?? ToolSort.popular),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _filterHasSteps,
                  title: const Text('Has steps'),
                  onChanged: (v) => setState(() => _filterHasSteps = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _filterHasGraph,
                  title: const Text('Has graph'),
                  onChanged: (v) => setState(() => _filterHasGraph = v ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _filterCore,
                  title: const Text('Core tools'),
                  onChanged: (v) => setState(() => _filterCore = v ?? false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (grouped.isEmpty)
            const SectionCard(title: 'Tools', child: Text('No tools match your current filters.')),
          ...grouped.entries.map((entry) => SectionCard(
                title: entry.key,
                child: Column(
                  children: entry.value
                      .map((t) => ToolListTile(tool: t, onTap: () => context.push('/tool/${t.id}')))
                      .toList(),
                ),
              )),
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
  final Map<String, String> fieldErrors = {};
  final Map<String, String> unitSelections = {};
  bool showAdvanced = false;
  String? selectedPresetName;

  @override
  void initState() {
    super.initState();
    tool = ToolRegistry.byId(widget.toolId);
    controllers = {for (final i in tool.inputs) i.key: TextEditingController(text: i.defaultValue)};
    for (final input in tool.inputs) {
      if (input.unitOptions.isNotEmpty) {
        unitSelections[input.key] = input.unitOptions.first;
      }
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyPreset(ToolPreset? preset) {
    if (preset == null) return;
    for (final entry in preset.values.entries) {
      if (controllers.containsKey(entry.key)) {
        controllers[entry.key]!.text = entry.value;
      }
    }
    setState(() {
      selectedPresetName = preset.name;
      fieldErrors.clear();
    });
  }

  bool _validateFields() {
    fieldErrors.clear();
    for (final input in tool.inputs) {
      final raw = controllers[input.key]!.text.trim();
      if (input.required && raw.isEmpty) {
        fieldErrors[input.key] = 'This field is required.';
        continue;
      }
      if (raw.isNotEmpty && double.tryParse(raw) == null) {
        fieldErrors[input.key] = 'Enter a valid number.';
      }
    }
    setState(() {});
    return fieldErrors.isEmpty;
  }

  Future<void> _saveAsPreset() async {
    final nameController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as preset'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Preset name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true || nameController.text.trim().isEmpty) return;
    await ref.read(favoritesRepositoryProvider).savePreset(
          FavoritePreset(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            toolId: tool.id,
            name: nameController.text.trim(),
            values: {for (final e in controllers.entries) e.key: e.value.text.trim()},
          ),
        );
    ref.invalidate(favoritePresetsProvider);
  }

  Future<void> _compute() async {
    if (!_validateFields()) return;

    final inputs = <String, double>{};
    for (final e in controllers.entries) {
      inputs[e.key] = double.parse(e.value.text.trim());
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
    final favoritesAsync = ref.watch(favoritesProvider);
    final isFavorite = favoritesAsync.maybeWhen(data: (ids) => ids.contains(tool.id), orElse: () => false);

    return AppScaffold(
      title: tool.title,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'favorite') {
              await ref.read(favoritesRepositoryProvider).toggleFavorite(tool.id);
              ref.invalidate(favoritesProvider);
            }
            if (value == 'preset') {
              await _saveAsPreset();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'favorite', child: Text('Toggle favorite')),
            PopupMenuItem(value: 'preset', child: Text('Save as preset')),
          ],
        ),
        IconButton(
          onPressed: () async {
            await ref.read(favoritesRepositoryProvider).toggleFavorite(tool.id);
            ref.invalidate(favoritesProvider);
          },
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.redAccent : null),
        ),
      ],
      body: ListView(
        children: [
          SectionCard(
            title: 'Inputs',
            subtitle: tool.description,
            child: Column(
              children: [
                if (tool.presets.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedPresetName,
                    decoration: const InputDecoration(labelText: 'Preset'),
                    items: tool.presets
                        .map((preset) => DropdownMenuItem<String>(value: preset.name, child: Text(preset.name)))
                        .toList(),
                    onChanged: (name) => _applyPreset(tool.presets.firstWhere((p) => p.name == name)),
                  ),
                if (tool.presets.isNotEmpty) const SizedBox(height: 12),
                for (final input in tool.inputs.where((e) => !e.isAdvanced)) ...[
                  InputField(controller: controllers[input.key]!, label: input.label, hint: input.hint),
                  if (fieldErrors[input.key] case final err?)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(err, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                      ),
                    ),
                  if (input.unitOptions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DropdownButtonFormField<String>(
                        value: unitSelections[input.key],
                        decoration: InputDecoration(labelText: '${input.label} Unit'),
                        items: input.unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) => setState(() => unitSelections[input.key] = v ?? input.unitOptions.first),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                ExpansionTile(
                  title: const Text('Advanced'),
                  initiallyExpanded: showAdvanced,
                  onExpansionChanged: (expanded) => setState(() => showAdvanced = expanded),
                  children: [
                    for (final input in tool.inputs.where((e) => e.isAdvanced))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InputField(controller: controllers[input.key]!, label: input.label, hint: input.hint),
                      ),
                    if (!tool.inputs.any((e) => e.isAdvanced))
                      const ListTile(title: Text('No advanced options for this tool yet.')),
                  ],
                ),
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
              if (tool.hasGraph) OutlinedButton(onPressed: () => context.push('/tool/${tool.id}/graph'), child: const Text('Graph')),
              OutlinedButton(onPressed: () => context.push('/tool/${tool.id}/history'), child: const Text('History')),
              OutlinedButton(onPressed: () => context.push('/share-export'), child: const Text('Share')),
            ],
          ),
        ],
      ),
    );
  }
}

class ToolStepsScreen extends StatelessWidget {
  const ToolStepsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(title: 'Tool Steps', body: SectionCard(title: 'Step-by-step', child: Text('Steps placeholder, collapsed by default in production widgets.')));
}

class ToolInfoScreen extends StatelessWidget {
  const ToolInfoScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(title: 'Tool Info / Formula', body: SectionCard(title: 'Reference', child: Text('Formula and assumptions placeholder.')));
}

class ToolGraphScreen extends StatelessWidget {
  const ToolGraphScreen({super.key});
  @override
  Widget build(BuildContext context) => const AppScaffold(title: 'Tool Graph', body: SectionCard(title: 'Graph', child: Text('Graph placeholder page for graph-capable tools.')));
}

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
