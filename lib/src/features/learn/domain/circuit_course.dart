enum CircuitKind { series, parallel, divider }

class CircuitTopic {
  const CircuitTopic(
    this.id,
    this.title,
    this.outcome,
    this.concept,
    this.kind,
    this.toolId,
  );
  final String id, title, outcome, concept, toolId;
  final CircuitKind kind;
  List<CircuitProblem> get problems =>
      circuitProblems.where((p) => p.topicId == id).toList();
}

const circuitTopics = [
  CircuitTopic(
    'series',
    'Series circuits',
    'Find resistance along a single path.',
    'In a series connection, the same current passes through both resistors. '
        'Their voltage drops add, so their resistances add too.',
    CircuitKind.series,
    'ohms_resistors',
  ),
  CircuitTopic(
    'parallel',
    'Parallel circuits',
    'Recognize branches and combine resistance.',
    'Parallel resistors connect across the same two nodes and have the same '
        'voltage. An extra branch gives current another path, reducing total resistance.',
    CircuitKind.parallel,
    'ohms_resistors',
  ),
  CircuitTopic(
    'divider',
    'Voltage dividers',
    'Predict the voltage across a resistor.',
    'Two series resistors share the supply voltage in proportion to their '
        'resistance. Here the output is measured across R2, with no load attached.',
    CircuitKind.divider,
    'voltage_divider',
  ),
];

class CircuitProblem {
  const CircuitProblem(
    this.id,
    this.topicId,
    this.title,
    this.r1,
    this.r2, {
    this.voltage = 12,
    this.guided = false,
    this.kilo = false,
  });
  final String id, topicId, title;
  final double r1, r2, voltage;
  final bool guided, kilo;
  CircuitTopic get topic => circuitTopics.firstWhere((t) => t.id == topicId);
  String get unit => topic.kind == CircuitKind.divider ? 'V' : 'Ω';
  String resistor(double value) =>
      kilo ? '${number(value / 1000)} kΩ' : '${number(value)} Ω';
  String get prompt => topic.kind == CircuitKind.divider
      ? 'An ideal ${number(voltage)} V supply feeds R1 = ${resistor(r1)} and '
            'R2 = ${resistor(r2)} in series. Find the unloaded output voltage across R2.'
      : 'R1 = ${resistor(r1)} and R2 = ${resistor(r2)} are connected in '
            '$topicId. Find their equivalent resistance in ohms.';
  double get answer => switch (topic.kind) {
    CircuitKind.series => r1 + r2,
    CircuitKind.parallel => r1 * r2 / (r1 + r2),
    CircuitKind.divider => voltage * r2 / (r1 + r2),
  };
  List<String> get methods => const [
    'Add the resistances: R1 + R2',
    'Combine branches: (R1 × R2) / (R1 + R2)',
    'Take the R2 share: Vin × R2 / (R1 + R2)',
  ];
  int get method => topic.kind.index;
  String methodFeedback(int chosen) {
    if (chosen == method) return 'That method matches the connection.';
    return switch (topic.kind) {
      CircuitKind.series =>
        'There is only one path. Both resistors oppose the same current; their resistances add.',
      CircuitKind.parallel =>
        'These are separate branches across the same two nodes. Adding resistances would describe a series connection.',
      CircuitKind.divider =>
        'The unknown is a voltage, not a resistance. Find the fraction of the supply across R2.',
    };
  }

  String get hint =>
      '${topic.concept}${kilo ? ' Convert kΩ to Ω by multiplying by 1000 before entering an answer in Ω.' : ''}';
  String get working => switch (topic.kind) {
    CircuitKind.series =>
      'Req = R1 + R2\n= ${number(r1)} + ${number(r2)}\n= ${number(answer)} Ω',
    CircuitKind.parallel =>
      'Req = (R1 × R2) / (R1 + R2)\n= (${number(r1)} × ${number(r2)}) / (${number(r1)} + ${number(r2)})\n= ${number(answer)} Ω',
    CircuitKind.divider =>
      'Vout = Vin × R2 / (R1 + R2)\n= ${number(voltage)} × ${number(r2)} / (${number(r1)} + ${number(r2)})\n= ${number(answer)} V',
  };
  String get senseCheck => switch (topic.kind) {
    CircuitKind.series =>
      'Check: the total is larger than either resistor alone.',
    CircuitKind.parallel =>
      'Check: the total is smaller than the smaller branch resistance.',
    CircuitKind.divider =>
      'Check: the output lies between 0 V and the supply voltage. Equal resistors would split the voltage in half.',
  };
  bool accepts(double value) =>
      value.isFinite && (value - answer).abs() <= answer.abs() * 0.005;
  String feedback(double value) {
    if (kilo &&
        (value * 1000 - answer).abs() <= answer * 0.005 &&
        unit == 'Ω') {
      return 'Your value looks like kΩ. This answer asks for Ω: multiply by 1000.';
    }
    if (topic.kind == CircuitKind.parallel && value >= (r1 < r2 ? r1 : r2)) {
      return 'A parallel total must be smaller than either branch. Use the product divided by the sum.';
    }
    if (topic.kind == CircuitKind.divider &&
        (value - (voltage - answer)).abs() < 0.001 &&
        r1 != r2) {
      return 'That is the voltage across R1. The output is across R2, so R2 belongs in the numerator.';
    }
    return 'Not quite. Check the substitution and units, then try again. Answers within 0.5% are accepted.';
  }
}

String number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsPrecision(4);

// Original exercises. Relationships checked against OpenStax University Physics
// Volume 2, section 10.2. All models use ideal resistors and wires; dividers have no load.
const circuitProblems = [
  CircuitProblem(
    'series-example',
    'series',
    'One path, two resistors',
    100,
    200,
    guided: true,
  ),
  CircuitProblem('series-1', 'series', 'Combine two resistors', 220, 330),
  CircuitProblem(
    'series-2',
    'series',
    'Work with kilohms',
    1000,
    2200,
    kilo: true,
  ),
  CircuitProblem('series-3', 'series', 'Unequal resistors', 470, 100),
  CircuitProblem(
    'series-4',
    'series',
    'Two equal resistors',
    1500,
    1500,
    kilo: true,
  ),
  CircuitProblem(
    'parallel-example',
    'parallel',
    'Two paths for current',
    100,
    100,
    guided: true,
  ),
  CircuitProblem('parallel-1', 'parallel', 'Equal branches', 220, 220),
  CircuitProblem('parallel-2', 'parallel', 'Unequal branches', 100, 300),
  CircuitProblem(
    'parallel-3',
    'parallel',
    'Kilohm branches',
    1000,
    1000,
    kilo: true,
  ),
  CircuitProblem('parallel-4', 'parallel', 'Check your intuition', 600, 300),
  CircuitProblem(
    'divider-example',
    'divider',
    'Share a supply voltage',
    1000,
    2000,
    guided: true,
    kilo: true,
  ),
  CircuitProblem(
    'divider-1',
    'divider',
    'Split a supply equally',
    1000,
    1000,
    voltage: 10,
    kilo: true,
  ),
  CircuitProblem(
    'divider-2',
    'divider',
    'Measure across R2',
    2000,
    1000,
    voltage: 9,
    kilo: true,
  ),
  CircuitProblem(
    'divider-3',
    'divider',
    'A larger lower resistor',
    1000,
    3000,
    voltage: 8,
    kilo: true,
  ),
  CircuitProblem(
    'divider-4',
    'divider',
    'A smaller output',
    3000,
    2000,
    voltage: 5,
    kilo: true,
  ),
];

CircuitProblem? findProblem(String id) {
  for (final p in circuitProblems) {
    if (p.id == id) return p;
  }
  return null;
}
