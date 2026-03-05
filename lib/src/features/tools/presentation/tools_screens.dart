import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/tool.dart';
import '../../favorites/data/favorites_repository.dart';
import '../../history/data/history_repository.dart';
import '../domain/tool_registry.dart';

final _searchProvider = StateProvider<String>((ref) => '');
final _categoryProvider = StateProvider<String?>((ref) => null);

class ToolsHomeScreen extends ConsumerWidget {
  const ToolsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_searchProvider).trim().toLowerCase();
    final selectedCategory = ref.watch(_categoryProvider);
    final favorites = ref.watch(favoritesProvider);
    final history = ref.watch(historyProvider);
    final categories = ToolRegistry.categories();

    final filtered = ToolRegistry.tools.where((t) {
      final inQuery = query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query) ||
          t.tags.any((tag) => tag.toLowerCase().contains(query));
      final inCategory = selectedCategory == null || t.category == selectedCategory;
      return inQuery && inCategory;
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _heroCard(context, filtered.length),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search calculators, formulas, topics',
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => ref.read(_searchProvider.notifier).state = '',
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: selectedCategory == null,
                onSelected: (_) => ref.read(_categoryProvider.notifier).state = null,
              ),
              ...categories.map(
                (c) => ChoiceChip(
                  label: Text(c),
                  selected: selectedCategory == c,
                  onSelected: (_) => ref.read(_categoryProvider.notifier).state = c,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Quick access'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _metricCard(context, 'Favorites', favorites.length.toString(), Icons.star)),
              const SizedBox(width: 10),
              Expanded(child: _metricCard(context, 'Recent', history.length.toString(), Icons.history)),
              const SizedBox(width: 10),
              Expanded(child: _metricCard(context, 'Tools', ToolRegistry.tools.length.toString(), Icons.calculate)),
            ],
          ),
          const SizedBox(height: 16),
          if (favorites.isNotEmpty) ...[
            _sectionTitle(context, 'Pinned tools'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: favorites
                  .take(8)
                  .map((id) => ActionChip(
                        avatar: const Icon(Icons.star, size: 16),
                        label: Text(ToolRegistry.byId(id).title),
                        onPressed: () => context.push('/tool/$id'),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          _sectionTitle(context, 'Engineering toolbox'),
          const SizedBox(height: 8),
          ...filtered.map(
            (tool) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                title: Text(tool.title),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${tool.category} • ${tool.description}'),
                ),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(tool.category.substring(0, 1)),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/tool/${tool.id}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard(BuildContext context, int resultCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EngiSteps Pro', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Faster inputs, clearer outputs, and practical engineering calculators in one place.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92))),
          const SizedBox(height: 8),
          Text('$resultCount tools match your filters', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _metricCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700));
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
  final Map<String, String?> _errors = {};
  final Map<String, String> _selectedUnits = {};
  final Map<String, bool> _anglesInDegrees = {};
  final Map<String, double> _selectedOptions = {};
  ToolResult? _result;
  bool _showSteps = false;
  bool _explain = true;

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

    _initStateForTool(tool);

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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 220),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tool.description, style: Theme.of(context).textTheme.bodyLarge),
                  if (tool.explain != null) ...[
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show concept explanation'),
                      value: _explain,
                      onChanged: (v) => setState(() => _explain = v),
                    ),
                    if (_explain)
                      Text(
                        tool.explain!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Input assistant', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _fillDefaults(tool),
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('Fill defaults'),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...tool.inputs.map((i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildInputControl(i))),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Material(
          elevation: 10,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_result != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Result', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(_result!.mainResult, style: Theme.of(context).textTheme.bodyLarge),
                        ..._result!.secondaryResults.map((e) => Text('${e.key}: ${e.value}')),
                        Wrap(
                          spacing: 6,
                          children: [
                            TextButton.icon(
                              onPressed: () => setState(() => _showSteps = !_showSteps),
                              icon: const Icon(Icons.rule),
                              label: Text(_showSteps ? 'Hide steps' : 'Show steps'),
                            ),
                            TextButton.icon(
                              onPressed: () => Clipboard.setData(ClipboardData(text: _composeCopy(tool, _result!))),
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy'),
                            ),
                            TextButton.icon(
                              onPressed: _saveToHistory,
                              icon: const Icon(Icons.history),
                              label: const Text('Save'),
                            ),
                          ],
                        ),
                        if (_showSteps) ..._result!.steps.map((s) => Text('• $s')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _solve,
                        icon: const Icon(Icons.calculate),
                        label: const Text('Solve now'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        for (final c in _controllers.values) {
                          c.clear();
                        }
                        _errors.clear();
                        _result = null;
                      }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _fillDefaults(Tool tool) {
    setState(() {
      for (final input in tool.inputs) {
        if (input.defaultValue != null && _controllers.containsKey(input.key)) {
          _controllers[input.key]!.text = input.defaultValue!;
        }
      }
    });
  }

  Widget _buildInputControl(ToolInputSchema schema) {
    switch (schema.type) {
      case ToolInputType.dropdown:
        return DropdownButtonFormField<double>(
          value: _selectedOptions[schema.key],
          decoration: InputDecoration(labelText: schema.label, errorText: _errors[schema.key]),
          items: schema.options.map((o) => DropdownMenuItem(value: o.value, child: Text(o.label))).toList(),
          onChanged: (v) => setState(() => _selectedOptions[schema.key] = v ?? schema.options.first.value),
        );
      case ToolInputType.toggle:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(schema.label),
          subtitle: _errors[schema.key] == null ? null : Text(_errors[schema.key]!, style: const TextStyle(color: Colors.red)),
          value: (_selectedOptions[schema.key] ?? 0) == 1,
          onChanged: (v) => setState(() => _selectedOptions[schema.key] = v ? 1 : 0),
        );
      case ToolInputType.range:
        final value = double.tryParse(_controllers[schema.key]!.text) ?? schema.min ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${schema.label}: ${_eng(value)}${schema.unit != null ? ' ${schema.unit}' : ''}'),
            Slider(
              min: schema.min ?? 0,
              max: schema.max ?? 100,
              value: value.clamp(schema.min ?? 0, schema.max ?? 100),
              onChanged: (v) => setState(() => _controllers[schema.key]!.text = v.toStringAsFixed(3)),
            ),
            if (_errors[schema.key] != null) Text(_errors[schema.key]!, style: const TextStyle(color: Colors.red)),
          ],
        );
      case ToolInputType.vector:
      case ToolInputType.complex:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(schema.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(schema.vectorDimensions, (idx) {
                final key = '${schema.key}_$idx';
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: idx == schema.vectorDimensions - 1 ? 0 : 8),
                    child: TextField(
                      controller: _controllers[key],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(labelText: schema.type == ToolInputType.complex ? (idx == 0 ? 'Real' : 'Imag') : 'v${idx + 1}'),
                    ),
                  ),
                );
              }),
            ),
            if (_errors[schema.key] != null) Text(_errors[schema.key]!, style: const TextStyle(color: Colors.red)),
          ],
        );
      case ToolInputType.matrix:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(schema.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ...List.generate(schema.matrixRows, (r) {
              return Row(
                children: List.generate(schema.matrixCols, (c) {
                  final key = '${schema.key}_${r}_$c';
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: c == schema.matrixCols - 1 ? 0 : 8, top: 8),
                      child: TextField(
                        controller: _controllers[key],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(labelText: '[${r + 1},${c + 1}]'),
                      ),
                    ),
                  );
                }),
              );
            }),
          ],
        );
      case ToolInputType.number:
      case ToolInputType.integer:
      case ToolInputType.angle:
        return _numericField(schema);
    }
  }

  Widget _numericField(ToolInputSchema schema) {
    final unitOptions = schema.unitOptions;
    final text = _controllers[schema.key]!.text;
    final parsed = double.tryParse(_normalizedNumber(text));
    final unitHelper = parsed != null && unitOptions.isNotEmpty ? 'Base: ${_eng(parsed * _selectedUnitFactor(schema))} ${unitOptions.first.symbol}' : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controllers[schema.key],
          keyboardType: TextInputType.numberWithOptions(decimal: schema.type != ToolInputType.integer, signed: true),
          inputFormatters: schema.type == ToolInputType.integer ? [FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))] : null,
          decoration: InputDecoration(
            labelText: schema.label,
            hintText: schema.hint,
            errorText: _errors[schema.key],
            helperText: unitHelper,
            suffixIcon: unitOptions.isEmpty
                ? null
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedUnits[schema.key],
                      onChanged: (v) => setState(() => _selectedUnits[schema.key] = v ?? unitOptions.first.symbol),
                      items: unitOptions.map((u) => DropdownMenuItem<String>(value: u.symbol, child: Text(u.symbol))).toList(),
                    ),
                  ),
          ),
        ),
        if (schema.type == ToolInputType.angle)
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(value: true, label: Text('deg')),
              ButtonSegment<bool>(value: false, label: Text('rad')),
            ],
            selected: {_anglesInDegrees[schema.key] ?? true},
            onSelectionChanged: (v) => setState(() => _anglesInDegrees[schema.key] = v.first),
          ),
        if (schema.examples.isNotEmpty)
          Wrap(
            spacing: 6,
            children: schema.examples
                .map((example) => ActionChip(label: Text(example), onPressed: () => setState(() => _controllers[schema.key]!.text = example)))
                .toList(),
          ),
      ],
    );
  }

  void _initStateForTool(Tool tool) {
    for (final input in tool.inputs) {
      if (input.type == ToolInputType.vector || input.type == ToolInputType.complex) {
        for (var idx = 0; idx < input.vectorDimensions; idx++) {
          _controllers.putIfAbsent('${input.key}_$idx', () => TextEditingController());
        }
      } else if (input.type == ToolInputType.matrix) {
        for (var r = 0; r < input.matrixRows; r++) {
          for (var c = 0; c < input.matrixCols; c++) {
            _controllers.putIfAbsent('${input.key}_${r}_$c', () => TextEditingController());
          }
        }
      } else {
        _controllers.putIfAbsent(input.key, () => TextEditingController(text: input.defaultValue ?? ''));
      }
      if (input.unitOptions.isNotEmpty) {
        _selectedUnits.putIfAbsent(input.key, () => input.unitOptions.first.symbol);
      }
      if (input.options.isNotEmpty) {
        _selectedOptions.putIfAbsent(input.key, () => input.options.first.value);
      }
      if (input.type == ToolInputType.angle) {
        _anglesInDegrees.putIfAbsent(input.key, () => true);
      }
    }
  }

  void _solve() {
    final tool = ToolRegistry.byId(widget.toolId);
    final inputs = <String, double>{};
    final nextErrors = <String, String?>{};

    for (final schema in tool.inputs) {
      final value = _extractValue(schema, inputs, nextErrors);
      if (value != null) {
        inputs[schema.key] = value;
      }
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(nextErrors);
      if (nextErrors.values.any((e) => e != null)) {
        _result = null;
        return;
      }
      _result = tool.compute(inputs);
    });
  }

  double? _extractValue(ToolInputSchema schema, Map<String, double> inputs, Map<String, String?> errors) {
    if (schema.type == ToolInputType.dropdown || schema.type == ToolInputType.toggle) {
      final choice = _selectedOptions[schema.key];
      if (choice == null && schema.required) {
        errors[schema.key] = '${schema.label} is required';
      }
      return choice;
    }

    if (schema.type == ToolInputType.vector || schema.type == ToolInputType.complex || schema.type == ToolInputType.matrix) {
      errors[schema.key] = null;
      return 0;
    }

    final text = _controllers[schema.key]?.text.trim() ?? '';
    if (text.isEmpty) {
      if (schema.required) {
        errors[schema.key] = '${schema.label} is required';
      }
      return null;
    }

    final parsed = double.tryParse(_normalizedNumber(text));
    if (parsed == null) {
      errors[schema.key] = 'Enter a valid number (e.g. 2.5)';
      return null;
    }

    var normalized = parsed;
    if (schema.type == ToolInputType.integer && parsed != parsed.roundToDouble()) {
      errors[schema.key] = '${schema.label} must be an integer';
      return null;
    }

    if (schema.type == ToolInputType.angle && !(_anglesInDegrees[schema.key] ?? true)) {
      normalized = parsed * 180 / math.pi;
    }

    normalized *= _selectedUnitFactor(schema);

    if (schema.min != null && normalized < schema.min!) {
      errors[schema.key] = '${schema.label} must be ≥ ${schema.min}';
      return null;
    }
    if (schema.max != null && normalized > schema.max!) {
      errors[schema.key] = '${schema.label} must be ≤ ${schema.max}';
      return null;
    }

    errors[schema.key] = null;
    return normalized;
  }

  double _selectedUnitFactor(ToolInputSchema schema) {
    if (schema.unitOptions.isEmpty) return 1;
    final selected = _selectedUnits[schema.key];
    return schema.unitOptions.firstWhere((u) => u.symbol == selected, orElse: () => schema.unitOptions.first).factorToBase;
  }

  void _saveToHistory() {
    final tool = ToolRegistry.byId(widget.toolId);
    if (_result == null) return;
    ref.read(historyProvider.notifier).add(
          HistoryEntry(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            toolId: tool.id,
            timestamp: DateTime.now(),
            inputs: {for (final i in tool.inputs) i.key: _controllers[i.key]?.text ?? ''},
            output: _result!.mainResult,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to history')));
  }

  String _composeCopy(Tool tool, ToolResult result) {
    return '${tool.title}\n${result.mainResult}\n${result.secondaryResults.map((e) => '${e.key}: ${e.value}').join('\n')}';
  }

  String _normalizedNumber(String value) => value.replaceAll(',', '.').replaceAll(' ', '');

  String _eng(double value) {
    if (value == 0) return '0';
    const prefixes = [
      MapEntry(-12, 'p'),
      MapEntry(-9, 'n'),
      MapEntry(-6, 'µ'),
      MapEntry(-3, 'm'),
      MapEntry(0, ''),
      MapEntry(3, 'k'),
      MapEntry(6, 'M'),
      MapEntry(9, 'G'),
    ];
    final exp = (math.log(value.abs()) / math.ln10).floor();
    final snapped = (exp / 3).floor() * 3;
    final use = prefixes.reduce((a, b) => (snapped - a.key).abs() < (snapped - b.key).abs() ? a : b);
    final scaled = value / math.pow(10, use.key);
    return '${scaled.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}${use.value}';
  }
}
