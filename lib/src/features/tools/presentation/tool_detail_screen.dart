import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/tool.dart';
import '../../../core/utils/smart_number_parser.dart';
import '../../favorites/data/favorites_repository.dart';
import '../../history/data/history_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/tool_execution.dart';
import '../domain/tool_registry.dart';
import '../domain/unit_conversion.dart';

import 'category_icon.dart';

class ToolDetailScreen extends ConsumerStatefulWidget {
  const ToolDetailScreen({super.key, required this.toolId, this.restore});
  final String toolId;
  final HistoryEntry? restore;
  @override
  ConsumerState<ToolDetailScreen> createState() => _ToolDetailState();
}

class _ToolDetailState extends ConsumerState<ToolDetailScreen> {
  final _controllers = <String, TextEditingController>{};
  final _units = <String, String>{};
  final _degrees = <String, bool>{};
  final _options = <String, double>{};
  final _errors = <String, String>{};
  final _resultKey = GlobalKey();
  ToolResult? _result;
  HistoryEntry? _snapshot;
  bool _saving = false;
  bool _saved = false;
  bool _edited = false;
  late final Tool? _tool;

  @override
  void initState() {
    super.initState();
    _tool = ToolRegistry.find(widget.toolId);
    final restore = widget.restore;
    for (final field in _tool?.inputs ?? <ToolInputSchema>[]) {
      _controllers[field.key] = TextEditingController(
        text: restore?.inputs[field.key] ?? field.defaultValue ?? '',
      )..addListener(_invalidate);
      if (field.unitOptions.isNotEmpty) {
        final unit = restore?.units[field.key];
        _units[field.key] = field.unitOptions.any((u) => u.symbol == unit)
            ? unit!
            : field.unitOptions.first.symbol;
      }
      _degrees[field.key] = restore?.degrees[field.key] ?? true;
      if (field.options.isNotEmpty) {
        final option = restore?.options[field.key];
        _options[field.key] = field.options.any((o) => o.value == option)
            ? option!
            : field.options.first.value;
      }
    }
    if (restore != null) {
      _result = ToolResult(
        mainResult: restore.output,
        secondaryResults: restore.details.entries.toList(),
        steps: restore.steps,
      );
      _snapshot = restore;
      _saved = true;
    }
  }

  void _invalidate() {
    setState(() {
      _edited = _result != null || _edited;
      _result = null;
      _snapshot = null;
      _saved = false;
      _errors.clear();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tool = _tool;
    if (tool == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tool unavailable')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/tools'),
            child: const Text('Browse tools'),
          ),
        ),
      );
    }
    final colors = Theme.of(context).colorScheme;
    final favorite = ref.watch(favoritesProvider).contains(tool.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(tool.title),
        actions: [
          IconButton(
            tooltip: favorite ? 'Remove favorite' : 'Add favorite',
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggle(tool.id),
            icon: Icon(
              favorite ? Icons.star_rounded : Icons.star_border_rounded,
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Icon(categoryIcon(tool.category), color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    tool.category,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tool.description,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (tool.explain != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(tool.explain!),
                ),
              if (_assumption(tool.id) case final String assumption)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    assumption,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '01  Inputs',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          TextButton.icon(
                            onPressed: _defaults,
                            icon: const Icon(Icons.restart_alt, size: 18),
                            label: const Text('Reset example'),
                          ),
                        ],
                      ),
                      if (tool.inputs.isNotEmpty)
                        Text(
                          'Expressions welcome: 2.2k, 1/3, 3*pi',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 18),
                      if (tool.id == 'unit_converter')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                              UnitConversion
                                  .units[_options['fromUnit']!.toInt()]
                                  .quantity,
                            ),
                            initialValue: UnitConversion
                                .units[_options['fromUnit']!.toInt()]
                                .quantity,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                            items: UnitConversion.units
                                .map((u) => u.quantity)
                                .toSet()
                                .map(
                                  (q) => DropdownMenuItem(
                                    value: q,
                                    child: Text(q),
                                  ),
                                )
                                .toList(),
                            onChanged: (q) {
                              final index = UnitConversion.units.indexWhere(
                                (u) => u.quantity == q,
                              );
                              _options['fromUnit'] = index.toDouble();
                              _options['toUnit'] = (index + 1).toDouble();
                              _invalidate();
                            },
                          ),
                        ),
                      ...tool.inputs.map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _input(field),
                        ),
                      ),
                      if (tool.inputs.isEmpty)
                        const Text(
                          'No inputs needed. Explore the reference values below.',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_result != null)
                KeyedSubtree(key: _resultKey, child: _resultCard(tool, colors))
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.insights_outlined,
                        color: colors.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _edited
                            ? 'Inputs changed. Calculate again to update your result.'
                            : 'Your result and working will appear here.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 752),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _solve,
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Calculate'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(ToolInputSchema field) {
    if (field.type == ToolInputType.dropdown) {
      return DropdownButtonFormField<double>(
        key: ValueKey('${field.key}-${_options[field.key]}'),
        initialValue: _options[field.key],
        decoration: InputDecoration(labelText: field.label),
        items: field.options
            .where(
              (o) =>
                  _tool!.id != 'unit_converter' ||
                  UnitConversion.units[o.value.toInt()].quantity ==
                      UnitConversion
                          .units[_options['fromUnit']!.toInt()]
                          .quantity,
            )
            .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
            .toList(),
        onChanged: (v) {
          _options[field.key] = v!;
          _invalidate();
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controllers[field.key],
          keyboardType: TextInputType.text,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _solve(),
          decoration: InputDecoration(
            labelText: field.label,
            suffixText: field.unitOptions.isEmpty ? field.unit : null,
            errorText: _errors[field.key],
            errorMaxLines: 3,
            hintText: field.hint ?? 'Enter a value or expression',
          ),
        ),
        if (field.unitOptions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: DropdownButtonFormField<String>(
              key: ValueKey('${field.key}-${_units[field.key]}'),
              initialValue: _units[field.key],
              decoration: const InputDecoration(labelText: 'Unit'),
              items: field.unitOptions
                  .map(
                    (u) => DropdownMenuItem(
                      value: u.symbol,
                      child: Text(u.label ?? u.symbol),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                _units[field.key] = v!;
                _invalidate();
              },
            ),
          ),
        if (field.type == ToolInputType.angle)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Degrees')),
                ButtonSegment(value: false, label: Text('Radians')),
              ],
              selected: {_degrees[field.key]!},
              onSelectionChanged: (v) {
                _degrees[field.key] = v.first;
                _invalidate();
              },
            ),
          ),
        if (field.examples.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              children: field.examples
                  .map(
                    (e) => ActionChip(
                      label: Text(e),
                      onPressed: () => _controllers[field.key]!.text = e,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _resultCard(Tool tool, ColorScheme colors) {
    final result = _result!;
    final error = result.error != null;
    return Semantics(
      liveRegion: true,
      child: Card(
        color: error ? colors.errorContainer : colors.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                error ? 'Check your inputs' : '02  Result',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (_snapshot != null && _snapshot!.version < 2)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'This older save does not include units or modes. Check them before recalculating.',
                  ),
                ),
              SelectableText(
                result.mainResult,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              ...result.secondaryResults.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SelectableText('${e.key}: ${e.value}'),
                ),
              ),
              if (result.steps.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Understand the steps'),
                    children: result.steps
                        .asMap()
                        .entries
                        .map(
                          (e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Text('${e.key + 1}.'),
                            title: SelectableText(e.value),
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (!error)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _saving || _saved ? null : _save,
                        icon: Icon(
                          _saved ? Icons.check : Icons.bookmark_add_outlined,
                        ),
                        label: Text(
                          _saved
                              ? 'Saved'
                              : _saving
                              ? 'Saving…'
                              : 'Save result',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _copyText(tool)),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Calculation copied'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy working'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _defaults() {
    for (final field in _tool!.inputs) {
      _controllers[field.key]!.text = field.defaultValue ?? '';
      if (field.unitOptions.isNotEmpty) {
        _units[field.key] = field.unitOptions.first.symbol;
      }
      if (field.options.isNotEmpty) {
        _options[field.key] = field.options.first.value;
      }
      _degrees[field.key] = true;
    }
    _invalidate();
  }

  void _solve() {
    FocusScope.of(context).unfocus();
    final tool = _tool!;
    final values = <String, double>{};
    _errors.clear();
    for (final field in tool.inputs) {
      if (field.type == ToolInputType.dropdown) {
        values[field.key] = _options[field.key]!;
        continue;
      }
      var value = SmartNumberParser.parse(_controllers[field.key]!.text);
      if (value == null) {
        _errors[field.key] =
            'Enter a finite number or expression, such as 2.2k or 1/3.';
        continue;
      }
      if (field.type == ToolInputType.angle && !_degrees[field.key]!) {
        value *= 180 / math.pi;
      }
      if (field.unitOptions.isNotEmpty) {
        value *= field.unitOptions
            .firstWhere((u) => u.symbol == _units[field.key])
            .factorToBase;
      }
      if (!value.isFinite) {
        _errors[field.key] = 'Value is too large. Try a smaller number.';
        continue;
      }
      if (field.min != null && value < field.min! ||
          field.max != null && value > field.max!) {
        _errors[field.key] =
            'Allowed range in base units: ${field.min ?? '−∞'} to ${field.max ?? '∞'}.';
      }
      values[field.key] = value;
    }
    setState(() {
      _saved = false;
      _snapshot = null;
      _edited = false;
      final settings = ref.read(settingsControllerProvider);
      _result = _errors.isEmpty
          ? ToolExecution.run(
              tool,
              values,
              precision: settings.decimalPrecision,
              scientific: settings.scientificNotation,
            )
          : null;
      if (_result != null && _result!.error == null) {
        final now = DateTime.now();
        _snapshot = HistoryEntry(
          id: now.microsecondsSinceEpoch.toString(),
          toolId: tool.id,
          timestamp: now,
          inputs: Map.unmodifiable(
            _controllers.map((k, v) => MapEntry(k, v.text)),
          ),
          units: Map.unmodifiable(_units),
          degrees: Map.unmodifiable(_degrees),
          options: Map.unmodifiable(_options),
          output: _result!.mainResult,
          details: Map.fromEntries(_result!.secondaryResults),
          steps: List.unmodifiable(_result!.steps),
        );
      }
    });
    if (_result != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _resultKey.currentContext;
        if (mounted && target != null) {
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 250),
            alignment: 0.1,
          );
        }
      });
    }
  }

  Future<void> _save() async {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(historyProvider.notifier).add(snapshot);
      if (mounted && identical(snapshot, _snapshot)) {
        setState(() => _saved = true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _copyText(Tool tool) {
    final snapshot = _snapshot!;
    final lines = <String>[tool.title, ''];
    for (final field in tool.inputs) {
      final option = snapshot.options[field.key];
      final value = field.type == ToolInputType.dropdown
          ? field.options
                .firstWhere(
                  (o) => o.value == option,
                  orElse: () =>
                      const ToolSelectOption(label: 'Not recorded', value: 0),
                )
                .label
          : snapshot.inputs[field.key];
      final unit = field.type == ToolInputType.angle
          ? (snapshot.degrees.containsKey(field.key)
                ? (snapshot.degrees[field.key]! ? 'deg' : 'rad')
                : 'angle unit not recorded')
          : snapshot.units[field.key] ?? field.unit ?? '';
      lines.add('${field.label}: $value $unit');
    }
    lines.addAll([
      '',
      snapshot.output,
      ...snapshot.details.entries.map((e) => '${e.key}: ${e.value}'),
      '',
      ...snapshot.steps,
    ]);
    if (_assumption(tool.id) case final String assumption) {
      lines.add(assumption);
    }
    return lines.join('\n');
  }

  String? _assumption(String id) => switch (id) {
    'projectile' =>
      'Assumes level launch and landing, no air resistance, and g = 9.81 m/s².',
    'reynolds_number' =>
      'Regime thresholds apply to flow in a circular pipe. Use speed magnitude.',
    'transformer_turns_ratio' =>
      'Ideal transformer: losses and magnetizing current are neglected.',
    'rc_charge' => 'Initially uncharged capacitor with a constant DC supply.',
    'beam_bending_stress' =>
      'Linear elastic bending with the neutral axis through the centroid.',
    'ideal_gas' => 'Ideal gas approximation. Temperature must be in kelvin.',
    'work_energy_power' =>
      'Constant force parallel to displacement; power is the time average.',
    'ac_power_basic' =>
      'Single-phase sinusoidal AC. Q is the reactive power magnitude.',
    _ => null,
  };
}
