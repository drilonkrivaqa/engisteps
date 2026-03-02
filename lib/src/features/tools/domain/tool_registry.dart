import 'dart:math' as math;

import '../../../core/models/tool.dart';

class ToolRegistry {
  static final List<Tool> tools = [
    _tool('ohms_law', 'Ohm\'s Law', 'Circuits', ['V', 'I'], (m) => m['V']! / m['I']!, 'R'),
    _tool('kinetic_energy', 'Kinetic Energy', 'Physics', ['m', 'v'], (m) => 0.5 * m['m']! * m['v']! * m['v']!, 'KE'),
    _tool('power', 'Electrical Power', 'Circuits', ['V', 'I'], (m) => m['V']! * m['I']!, 'P'),
    _tool('cap_charge', 'Capacitor Charge Time', 'Electronics', ['R', 'C'], (m) => 5 * m['R']! * m['C']!, 't'),
    _tool('bandwidth', 'Nyquist Rate', 'Signals', ['B'], (m) => 2 * m['B']!, 'Rate'),
    _tool('cpu_time', 'CPU Time', 'Computer Arch', ['IC', 'CPI', 'Clock'], (m) => (m['IC']! * m['CPI']!) / m['Clock']!, 'Time'),
    _tool('slope', 'Line Slope', 'Math', ['dy', 'dx'], (m) => m['dy']! / m['dx']!, 'm'),
    _tool('mean', 'Mean Value', 'Stats', ['sum', 'n'], (m) => m['sum']! / m['n']!, 'Mean'),
    _tool('std_err', 'Standard Error', 'Stats', ['sd', 'n'], (m) => m['sd']! / math.sqrt(m['n']!), 'SE'),
    _tool('throughput', 'System Throughput', 'Software', ['tasks', 'seconds'], (m) => m['tasks']! / m['seconds']!, 'TPS'),
  ];

  static Tool byId(String id) => tools.firstWhere((t) => t.id == id);

  static Tool _tool(
    String id,
    String title,
    String category,
    List<String> inputKeys,
    double Function(Map<String, double>) formula,
    String out,
  ) {
    return Tool(
      id: id,
      title: title,
      category: category,
      description: '$title quick calculator',
      inputs: inputKeys.map((e) => ToolInputSchema(key: e, label: e)).toList(),
      compute: (inputs) {
        final value = formula(inputs);
        if (value.isNaN || value.isInfinite) {
          return const ToolResult(mainResult: 'Invalid input', error: 'Please check inputs.');
        }
        return ToolResult(
          mainResult: '$out = ${value.toStringAsFixed(4)}',
          secondaryResults: [MapEntry('Category', category)],
          steps: ['Read inputs', 'Apply $title formula', 'Format output'],
        );
      },
    );
  }
}
