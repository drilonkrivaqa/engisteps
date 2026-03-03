import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/tool.dart' as tool_models;
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../favorites/data/favorites_repository.dart';
import '../../history/data/history_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/tool_registry.dart';

enum ToolsSort { recommended, popularity, aToZ }

final _toolsSortProvider = StateProvider<ToolsSort>((ref) => ToolsSort.recommended);
final _coreOnlyProvider = StateProvider<bool>((ref) => false);
final _categoryFilterProvider = StateProvider<String?>((ref) => null);

class ToolsHubScreen extends ConsumerWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(_toolsSortProvider);
    final coreOnly = ref.watch(_coreOnlyProvider);
    final selectedCategory = ref.watch(_categoryFilterProvider);

    final allCategories = ToolRegistry.categories();
    final tools = ToolRegistry.tools.where((t) {
      if (coreOnly && !t.isCore) return false;
      if (selectedCategory != null && t.category != selectedCategory) return false;
      return true;
    }).toList();

    tools.sort((a, b) {
      switch (sort) {
        case ToolsSort.popularity:
          return b.popularity.compareTo(a.popularity);
        case ToolsSort.aToZ:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case ToolsSort.recommended:
          final ac = a.isCore ? 0 : 1;
          final bc = b.isCore ? 0 : 1;
          final byCore = ac.compareTo(bc);
          if (byCore != 0) return byCore;
          return b.popularity.compareTo(a.popularity);
      }
    });

    return AppScaffold(
      title: 'Tools',
      actions: [
        IconButton(
          tooltip: 'Search',
          onPressed: () => context.push('/search'),
          icon: const Icon(Icons.search),
        ),
      ],
      body: ListView(
        children: [
          SectionCard(
            title: 'Browse',
            subtitle: 'Filter fast, find what you need, run tools in seconds.',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All categories')),
                          ...allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        ],
                        onChanged: (v) => ref.read(_categoryFilterProvider.notifier).state = v,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<ToolsSort>(
                        value: sort,
                        decoration: const InputDecoration(
                          labelText: 'Sort',
                          prefixIcon: Icon(Icons.sort),
                        ),
                        items: const [
                          DropdownMenuItem(value: ToolsSort.recommended, child: Text('Recommended')),
                          DropdownMenuItem(value: ToolsSort.popularity, child: Text('Most popular')),
                          DropdownMenuItem(value: ToolsSort.aToZ, child: Text('A → Z')),
                        ],
                        onChanged: (v) => ref.read(_toolsSortProvider.notifier).state = v ?? ToolsSort.recommended,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: coreOnly,
                  onChanged: (v) => ref.read(_coreOnlyProvider.notifier).state = v,
                  title: const Text('Core tools only'),
                  subtitle: const Text('Show the tools you’ll use daily in engineering.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (tools.isEmpty)
            const EmptyState(
              title: 'No tools match your filters',
              message: 'Try turning off Core-only or clearing the category filter.',
              icon: Icons.filter_alt_off,
            )
          else
            SectionCard(
              title: 'All tools',
              trailing: Text('${tools.length}'),
              child: Column(
                children: tools.map((t) => _ToolRow(tool: t)).toList(),
              ),
            ),
          const SizedBox(height: 80),
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
    final tools = ToolRegistry.tools.where((t) => t.category == category).toList()
      ..sort((a, b) => b.popularity.compareTo(a.popularity));

    return AppScaffold(
      title: category,
      actions: [
        IconButton(
          tooltip: 'Search',
          onPressed: () => context.push('/search'),
          icon: const Icon(Icons.search),
        ),
      ],
      body: ListView(
        children: [
          SectionCard(
            title: 'Tools in $category',
            trailing: Text('${tools.length}'),
            child: Column(children: tools.map((t) => _ToolRow(tool: t)).toList()),
          ),
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
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _units = {};
  tool_models.ToolResult? _result;
  String? _textModeBinary;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(tool_models.Tool tool) {
    if (_controllers.isNotEmpty) return;
    for (final input in tool.inputs) {
      _controllers[input.key] = TextEditingController(text: input.defaultValue ?? '');
      if (input.unitOptions.isNotEmpty) {
        _units[input.key] = input.unitOptions.first;
      }
    }
  }

  String _formatNumber(double v) {
    final s = ref.read(settingsControllerProvider);
    if (v.isNaN || v.isInfinite) return 'Invalid';
    if (s.scientificNotation) return v.toStringAsExponential(s.decimalPrecision);
    return v.toStringAsFixed(s.decimalPrecision);
  }

  Future<void> _runTool(tool_models.Tool tool) async {
    FocusScope.of(context).unfocus();

    if (tool.id == 'binary_ones_complement') {
      final raw = (_textModeBinary ?? '').trim();
      if (raw.isEmpty || !RegExp(r'^[01]+$').hasMatch(raw)) {
        setState(() => _result = const tool_models.ToolResult(mainResult: 'Invalid input', error: 'Enter only 0 and 1.'));
        return;
      }
      final inverted = raw.split('').map((c) => c == '0' ? '1' : '0').join();
      setState(() {
        _result = tool_models.ToolResult(
          mainResult: "1's complement: $inverted",
          secondaryResults: [MapEntry('Original', raw)],
          steps: const [
            'Flip every bit: 0 → 1 and 1 → 0',
            'Keep the same bit-length',
          ],
        );
      });
      await _saveHistory(tool, {'bits': raw}, _result!.mainResult);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final parsed = <String, double>{};
    for (final input in tool.inputs) {
      final text = (_controllers[input.key]?.text ?? '').trim();
      if (text.isEmpty && !input.required) continue;

      final value = double.tryParse(text.replaceAll(',', '.'));
      if (value == null) {
        setState(() => _result = const tool_models.ToolResult(mainResult: 'Invalid input', error: 'Please enter valid numbers.'));
        return;
      }
      if (input.min != null && value < input.min!) {
        setState(() => _result = tool_models.ToolResult(mainResult: 'Invalid input', error: '${input.label} must be ≥ ${input.min}'));
        return;
      }
      if (input.max != null && value > input.max!) {
        setState(() => _result = tool_models.ToolResult(mainResult: 'Invalid input', error: '${input.label} must be ≤ ${input.max}'));
        return;
      }

      parsed[input.key] = value;
    }

    final res = tool.compute(parsed);

    setState(() {
      _result = tool_models.ToolResult(
        mainResult: _postFormatMain(res.mainResult),
        secondaryResults: res.secondaryResults,
        steps: res.steps,
        error: res.error,
      );
    });

    await _saveHistory(tool, _controllers.map((k, v) => MapEntry(k, v.text.trim())), _result!.mainResult);
  }

  String _postFormatMain(String main) {
    final match = RegExp(r'^(.*?=\s*)(-?\d+(\.\d+)?)(\s.*)?$').firstMatch(main);
    if (match == null) return main;

    final prefix = match.group(1) ?? '';
    final numStr = match.group(2) ?? '';
    final suffix = match.group(4) ?? '';

    final v = double.tryParse(numStr);
    if (v == null) return main;

    return '$prefix${_formatNumber(v)}${suffix ?? ''}';
  }

  Future<void> _saveHistory(tool_models.Tool tool, Map<String, String> inputs, String output) async {
    final repo = ref.read(historyRepositoryProvider);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await repo.add(
      HistoryEntry(
        id: id,
        toolId: tool.id,
        timestamp: DateTime.now(),
        inputs: inputs,
        output: output,
      ),
    );
    ref.invalidate(historyProvider);
  }

  Future<void> _toggleFavorite(tool_models.Tool tool) async {
    await ref.read(favoritesRepositoryProvider).toggleFavorite(tool.id);
    ref.invalidate(favoritesProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated favorites: ${tool.title}')),
    );
  }

  Future<void> _savePreset(tool_models.Tool tool) async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save preset'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Preset name',
            hintText: 'e.g. Lab default',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;

    final preset = FavoritePreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      toolId: tool.id,
      name: nameCtrl.text.trim().isEmpty ? 'My preset' : nameCtrl.text.trim(),
      values: _controllers.map((k, v) => MapEntry(k, v.text.trim())),
    );

    await ref.read(favoritesRepositoryProvider).savePreset(preset);
    ref.invalidate(favoritePresetsProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset saved')));
  }

  void _applyPreset(tool_models.ToolPreset preset) {
    for (final e in preset.values.entries) {
      _controllers[e.key]?.text = e.value;
    }
    setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    final tool = ToolRegistry.byId(widget.toolId);
    _initControllers(tool);

    final favoritesAsync = ref.watch(favoritesProvider);
    final isFavorite = favoritesAsync.maybeWhen(
      data: (ids) => ids.contains(tool.id),
      orElse: () => false,
    );

    return AppScaffold(
      title: tool.title,
      actions: [
        IconButton(
          tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
          onPressed: () => _toggleFavorite(tool),
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
        ),
        IconButton(
          tooltip: 'Save preset',
          onPressed: () => _savePreset(tool),
          icon: const Icon(Icons.bookmark_add_outlined),
        ),
        IconButton(
          tooltip: 'Tool history',
          onPressed: () => context.push('/tool/${tool.id}/history'),
          icon: const Icon(Icons.history),
        ),
      ],
      body: ListView(
        children: [
          SectionCard(
            title: tool.category,
            subtitle: tool.description,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(tool.subcategory, Icons.layers_outlined),
                if (tool.isCore) _chip('Core tool', Icons.star_outline),
                if (tool.tags.isNotEmpty) ...tool.tags.map((t) => _chip(t, Icons.tag)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (tool.presets.isNotEmpty)
            SectionCard(
              title: 'Presets',
              subtitle: 'Tap to fill inputs fast.',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tool.presets
                    .map((p) => ActionChip(
                  label: Text(p.name),
                  onPressed: () => _applyPreset(p),
                ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Inputs',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (tool.id == 'binary_ones_complement')
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Binary',
                        hintText: '010011',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      onChanged: (v) => _textModeBinary = v,
                    )
                  else
                    ...tool.inputs.map((input) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _controllers[input.key],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: InputDecoration(
                                  labelText: input.label,
                                  hintText: input.hint,
                                  prefixIcon: const Icon(Icons.edit_outlined),
                                ),
                                validator: (v) {
                                  final t = (v ?? '').trim();
                                  if (t.isEmpty && input.required) return 'Required';
                                  if (t.isEmpty && !input.required) return null;
                                  final parsed = double.tryParse(t.replaceAll(',', '.'));
                                  if (parsed == null) return 'Invalid number';
                                  if (input.min != null && parsed < input.min!) return 'Must be ≥ ${input.min}';
                                  if (input.max != null && parsed > input.max!) return 'Must be ≤ ${input.max}';
                                  return null;
                                },
                              ),
                            ),
                            if (input.unitOptions.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 120,
                                child: DropdownButtonFormField<String>(
                                  value: _units[input.key],
                                  decoration: const InputDecoration(labelText: 'Unit'),
                                  items: input.unitOptions
                                      .map((u) => DropdownMenuItem<String>(value: u, child: Text(u)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _units[input.key] = v ?? input.unitOptions.first),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _runTool(tool),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Run'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_result != null)
            SectionCard(
              title: 'Result',
              trailing: IconButton(
                tooltip: 'Copy',
                onPressed: () {
                  final text = _result!.mainResult;
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                },
                icon: const Icon(Icons.copy),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_result!.mainResult, style: Theme.of(context).textTheme.titleLarge),
                  if (_result!.error != null) ...[
                    const SizedBox(height: 8),
                    Text(_result!.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  if (_result!.secondaryResults.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._result!.secondaryResults.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(width: 110, child: Text(e.key, style: Theme.of(context).textTheme.bodyMedium)),
                          Expanded(child: Text(e.value)),
                        ],
                      ),
                    )),
                  ],
                  if (_result!.steps.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Steps', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ..._result!.steps.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            child: Text('${e.key + 1}', style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(e.value)),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _chip(String text, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(text),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.tool});
  final tool_models.Tool tool;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(_iconForCategory(tool.category))),
      title: Text(tool.title),
      subtitle: Text('${tool.category} • ${tool.subcategory}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/tool/${tool.id}'),
    );
  }

  IconData _iconForCategory(String c) {
    return switch (c) {
      'Circuits' => Icons.bolt,
      'Electronics' => Icons.memory,
      'Signals' => Icons.multiline_chart,
      'Computer Arch' => Icons.developer_board,
      'Physics' => Icons.science,
      'Math' => Icons.functions,
      'Stats' => Icons.bar_chart,
      _ => Icons.calculate_outlined,
    };
  }
}

class PerToolHistoryScreen extends ConsumerWidget {
  const PerToolHistoryScreen({super.key, required this.toolId});
  final String toolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = ToolRegistry.byId(toolId);
    final history = ref.watch(historyProvider);

    return AppScaffold(
      title: '${tool.title} history',
      body: history.when(
        data: (items) {
          final filtered = items.where((e) => e.toolId == toolId).toList();
          if (filtered.isEmpty) {
            return const EmptyState(
              title: 'No history yet',
              message: 'Run the tool and your results will show here.',
              icon: Icons.history,
            );
          }
          return ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final entry = filtered[i];
              return ListTile(
                title: Text(entry.output),
                subtitle: Text(entry.timestamp.toLocal().toString()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/history/detail?id=${entry.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}