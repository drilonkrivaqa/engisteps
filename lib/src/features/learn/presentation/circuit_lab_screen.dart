import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/smart_number_parser.dart';
import '../../history/data/history_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/circuit_course.dart';
import '../domain/circuit_experiment.dart';
import 'learning_screens.dart';
import 'student_home_screen.dart';

final circuitExperimentProvider = StateProvider<CircuitExperiment>(
  (ref) => CircuitExperiment(),
);
final circuitBaselineProvider = StateProvider<CircuitExperiment?>(
  (ref) => null,
);

class CircuitLabScreen extends ConsumerStatefulWidget {
  const CircuitLabScreen({super.key, this.topic, this.initial});
  final String? topic;
  final CircuitExperiment? initial;
  @override
  ConsumerState<CircuitLabScreen> createState() => _CircuitLabState();
}

class _CircuitLabState extends ConsumerState<CircuitLabScreen> {
  bool _saving = false;
  CircuitExperiment? _saved;
  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(circuitExperimentProvider.notifier).state = widget.initial!;
        }
      });
    } else if (widget.topic != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final topics = CircuitKind.values.where((k) => k.name == widget.topic);
        if (topics.isNotEmpty) {
          ref.read(circuitExperimentProvider.notifier).state = ref
              .read(circuitExperimentProvider)
              .copyWith(kind: topics.first);
        }
      });
    }
  }

  Future<void> _save(CircuitExperiment experiment) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final settings = ref.read(settingsControllerProvider);
      final snapshot = experiment.snapshot(
        precision: settings.decimalPrecision,
        scientific: settings.scientificNotation,
      );
      await ref.read(historyProvider.notifier).add(snapshot);
      if (mounted) {
        setState(() => _saved = experiment);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved in My work → Saved calculations'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => context.go('/work/history'),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this calculation. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final experiment = ref.watch(circuitExperimentProvider);
    final baseline = ref.watch(circuitBaselineProvider);
    void update(CircuitExperiment next) =>
        ref.read(circuitExperimentProvider.notifier).state = next;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Circuit lab'),
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/learn'),
        ),
      ),
      body: StudentPage(
        children: [
          const Text(
            'Move a slider to see what changes.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start by increasing R2. Watch its voltage and the total current.',
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<CircuitKind>(
            isExpanded: true,
            key: ValueKey(experiment.kind),
            initialValue: experiment.kind,
            decoration: const InputDecoration(labelText: 'Circuit connection'),
            items: [
              for (final kind in CircuitKind.values)
                DropdownMenuItem(
                  value: kind,
                  child: Text(CircuitExperiment(kind: kind).name),
                ),
            ],
            onChanged: (kind) {
              if (kind != null) update(experiment.copyWith(kind: kind));
            },
          ),
          const SizedBox(height: 16),
          CircuitDiagram(
            problem: CircuitProblem(
              'lab',
              experiment.kind.name,
              'Live circuit',
              experiment.r1,
              experiment.r2,
              voltage: experiment.voltage,
            ),
          ),
          if (experiment.kind != CircuitKind.divider)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${number(experiment.voltage)} V ideal supply applied across the two ends.',
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LiveValue(
                    label: 'Voltage across R2',
                    value: '${number(experiment.output)} V',
                  ),
                  const Divider(height: 24),
                  _LiveValue(
                    label: 'Total supply current',
                    value: '${number(experiment.current * 1000)} mA',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ValueSlider(
            label: 'R2',
            value: experiment.r2,
            unit: 'Ω',
            min: 10,
            max: 10000,
            onChanged: (value) => update(experiment.copyWith(r2: value)),
          ),
          _ValueSlider(
            label: 'R1',
            value: experiment.r1,
            unit: 'Ω',
            min: 10,
            max: 10000,
            onChanged: (value) => update(experiment.copyWith(r1: value)),
          ),
          _ValueSlider(
            label: 'Supply',
            value: experiment.voltage,
            unit: 'V',
            min: 0.1,
            max: 24,
            onChanged: (value) => update(experiment.copyWith(voltage: value)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving || identical(_saved, experiment)
                ? null
                : () => _save(experiment),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(
              _saving
                  ? 'Saving…'
                  : identical(_saved, experiment)
                  ? 'Calculation saved'
                  : 'Save calculation',
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ExpansionTile(
              title: const Text('Why does it change?'),
              subtitle: const Text('Explanation and a live graph'),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                Text(experiment.explanation),
                const SizedBox(height: 16),
                Text(
                  'Voltage across R2 as R2 increases (R1 and supply held fixed)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Semantics(
                  image: true,
                  label: experiment.explanation,
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SweepPainter(
                        experiment,
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const Text(
                  'Horizontal: R2 from 10 Ω to 10 kΩ. Vertical: voltage from 0 to the supply voltage. Dot: your current setting.',
                ),
              ],
            ),
          ),
          Card(
            child: ExpansionTile(
              title: const Text('Compare two setups'),
              subtitle: const Text('Keep a reference, then change the circuit'),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                if (baseline == null)
                  const Text(
                    'Keep the current setup as your reference. Then adjust a slider or change the connection.',
                  ),
                if (baseline != null) ...[
                  Text(
                    'Reference: ${baseline.name}, ${number(baseline.voltage)} V, R1 ${number(baseline.r1)} Ω, R2 ${number(baseline.r2)} Ω',
                  ),
                  const SizedBox(height: 12),
                  _Comparison(
                    label: 'R2 voltage',
                    before: baseline.output,
                    after: experiment.output,
                    unit: 'V',
                  ),
                  _Comparison(
                    label: 'Supply current',
                    before: baseline.current * 1000,
                    after: experiment.current * 1000,
                    unit: 'mA',
                  ),
                  _Comparison(
                    label: 'Total resistance',
                    before: baseline.resistance,
                    after: experiment.resistance,
                    unit: 'Ω',
                  ),
                  _Comparison(
                    label: 'Total power',
                    before: baseline.power * 1000,
                    after: experiment.power * 1000,
                    unit: 'mW',
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(circuitBaselineProvider.notifier).state =
                          experiment,
                  child: Text(
                    baseline == null
                        ? 'Use current setup as reference'
                        : 'Replace reference with current setup',
                  ),
                ),
                if (baseline != null)
                  TextButton(
                    onPressed: () =>
                        ref.read(circuitBaselineProvider.notifier).state = null,
                    child: const Text('Clear reference'),
                  ),
              ],
            ),
          ),
          Card(
            child: ExpansionTile(
              title: const Text('More results & assumptions'),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                _LiveValue(
                  label: 'Equivalent resistance',
                  value: '${number(experiment.resistance)} Ω',
                ),
                const SizedBox(height: 10),
                _LiveValue(
                  label: 'Total resistor power',
                  value: '${number(experiment.power * 1000)} mW',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ideal resistors and wires. Steady DC, no output load or source resistance. This lab does not model temperature, component ratings or real-world tolerances.',
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      context.push('/learn/topic/${experiment.kind.name}'),
                  child: const Text('Learn this method step by step'),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => update(CircuitExperiment(kind: experiment.kind)),
            child: const Text('Reset circuit values'),
          ),
          const Text(
            'Your setup and reference stay available during this app session. Save calculations to keep them after closing the app.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LiveValue extends StatelessWidget {
  const _LiveValue({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 16,
    runSpacing: 4,
    children: [
      Text(label),
      Text(
        value,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ],
  );
}

class _ValueSlider extends StatelessWidget {
  const _ValueSlider({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label, unit;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => _edit(context),
                child: Text(
                  '${number(value)} $unit',
                  semanticsLabel: 'Edit $label value',
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            label: '${number(value)} $unit',
            semanticFormatterCallback: (v) => '$label ${number(v)} $unit',
            onChanged: (v) => onChanged(
              unit == 'V' ? (v * 10).round() / 10 : v.roundToDouble(),
            ),
          ),
        ],
      ),
    ),
  );
  Future<void> _edit(BuildContext context) async {
    final next = await showDialog<double>(
      context: context,
      builder: (_) => _ExactValueDialog(
        label: label,
        unit: unit,
        value: value,
        min: min,
        max: max,
      ),
    );
    if (next != null && context.mounted) onChanged(next);
  }
}

class _ExactValueDialog extends StatefulWidget {
  const _ExactValueDialog({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
  });
  final String label, unit;
  final double value, min, max;
  @override
  State<_ExactValueDialog> createState() => _ExactValueState();
}

class _ExactValueState extends State<_ExactValueDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value.toString(),
  );
  String? _error;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final next = SmartNumberParser.parse(_controller.text);
    if (next == null ||
        !next.isFinite ||
        next < widget.min ||
        next > widget.max) {
      setState(() => _error = 'Enter a value in the allowed range.');
      return;
    }
    Navigator.pop(context, next);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Set ${widget.label}'),
    content: TextField(
      autofocus: true,
      controller: _controller,
      onSubmitted: (_) => _apply(),
      decoration: InputDecoration(
        labelText: 'Value in ${widget.unit}',
        helperText:
            '${number(widget.min)}–${number(widget.max)} ${widget.unit}. Expressions such as 2.2k work.',
        helperMaxLines: 3,
        errorText: _error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _apply, child: const Text('Apply')),
    ],
  );
}

class _Comparison extends StatelessWidget {
  const _Comparison({
    required this.label,
    required this.before,
    required this.after,
    required this.unit,
  });
  final String label, unit;
  final double before, after;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          '${number(before)} → ${number(after)} $unit  (${after >= before ? '+' : ''}${number(after - before)} $unit)',
        ),
      ],
    ),
  );
}

class _SweepPainter extends CustomPainter {
  const _SweepPainter(this.experiment, this.color, this.axisColor);
  final CircuitExperiment experiment;
  final Color color, axisColor;
  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTRB(12, 12, size.width - 12, size.height - 12);
    final axis = Paint()
      ..color = axisColor.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    canvas.drawLine(area.bottomLeft, area.bottomRight, axis);
    canvas.drawLine(area.bottomLeft, area.topLeft, axis);
    final path = Path();
    for (var i = 0; i <= 100; i++) {
      final sample = experiment.copyWith(r2: 10 + i * 99.9);
      final point = Offset(
        area.left + i / 100 * area.width,
        area.bottom - sample.output / sample.voltage * area.height,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(
        area.left + (experiment.r2 - 10) / 9990 * area.width,
        area.bottom - experiment.output / experiment.voltage * area.height,
      ),
      5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SweepPainter old) =>
      old.experiment != experiment ||
      old.color != color ||
      old.axisColor != axisColor;
}
