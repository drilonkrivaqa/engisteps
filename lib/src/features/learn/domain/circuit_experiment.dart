import '../../history/data/history_repository.dart';
import '../../tools/domain/tool_execution.dart';
import '../../tools/domain/tool_registry.dart';
import 'circuit_course.dart';

class CircuitExperiment {
  CircuitExperiment({
    this.kind = CircuitKind.divider,
    this.voltage = 12,
    this.r1 = 1000,
    this.r2 = 2000,
  }) {
    if (![voltage, r1, r2].every((v) => v.isFinite) ||
        voltage < 0.1 ||
        voltage > 24 ||
        r1 < 10 ||
        r1 > 10000 ||
        r2 < 10 ||
        r2 > 10000) {
      throw ArgumentError('Use 0.1–24 V and 10–10,000 Ω.');
    }
  }
  final CircuitKind kind;
  final double voltage, r1, r2;
  CircuitExperiment copyWith({
    CircuitKind? kind,
    double? voltage,
    double? r1,
    double? r2,
  }) => CircuitExperiment(
    kind: kind ?? this.kind,
    voltage: voltage ?? this.voltage,
    r1: r1 ?? this.r1,
    r2: r2 ?? this.r2,
  );
  double get resistance =>
      kind == CircuitKind.parallel ? r1 * r2 / (r1 + r2) : r1 + r2;
  double get current => voltage / resistance;
  double get output =>
      kind == CircuitKind.parallel ? voltage : voltage * r2 / (r1 + r2);
  double get power => voltage * current;
  String get name => switch (kind) {
    CircuitKind.series => 'Series',
    CircuitKind.parallel => 'Parallel',
    CircuitKind.divider => 'Voltage divider',
  };
  String get explanation => switch (kind) {
    CircuitKind.parallel =>
      'Both branches have the full supply voltage. Increasing R2 reduces the current in that branch, so the total current falls. The voltage across R2 stays the same.',
    _ =>
      'R1 and R2 share the supply voltage. Increasing R2 gives it a larger share, so its voltage rises. Total resistance also rises, so the circuit current falls.',
  };
  HistoryEntry snapshot({int precision = 4, bool scientific = false}) {
    final divider = kind == CircuitKind.divider;
    final toolId = divider ? 'voltage_divider' : 'ohms_resistors';
    final values = <String, double>{
      divider ? 'Vin' : 'V': voltage,
      'R1': r1,
      'R2': r2,
      if (!divider) 'mode': kind == CircuitKind.parallel ? 1 : 0,
    };
    final result = ToolExecution.run(
      ToolRegistry.byId(toolId),
      values,
      precision: precision,
      scientific: scientific,
    );
    if (result.error != null) throw StateError(result.error!);
    final now = DateTime.now();
    return HistoryEntry(
      id: 'lab-${now.microsecondsSinceEpoch}',
      toolId: toolId,
      timestamp: now,
      inputs: {
        for (final entry in values.entries.where((e) => e.key != 'mode'))
          entry.key: entry.value.toString(),
      },
      units: divider ? const {} : const {'R1': 'Ω', 'R2': 'Ω'},
      options: divider ? const {} : {'mode': values['mode']!},
      output: result.mainResult,
      details: Map.fromEntries(result.secondaryResults),
      steps: result.steps,
    );
  }
}
