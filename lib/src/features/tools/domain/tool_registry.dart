import 'dart:math' as math;

import '../../../core/models/tool.dart';

class ToolRegistry {
  static final List<Tool> tools = [
    Tool(
      id: 'ohms_law',
      title: 'Ohm\'s Law',
      category: 'Circuits',
      subcategory: 'Conversions',
      description: 'Solve resistance from voltage and current.',
      isCore: true,
      popularity: 95,
      inputs: const [
        ToolInputSchema(key: 'V', label: 'Voltage', unitOptions: ['V', 'mV'], defaultValue: '5'),
        ToolInputSchema(key: 'I', label: 'Current', unitOptions: ['A', 'mA'], defaultValue: '0.5'),
      ],
      presets: const [
        ToolPreset(name: '5V @ 0.5A', values: {'V': '5', 'I': '0.5'}),
        ToolPreset(name: '12V @ 2A', values: {'V': '12', 'I': '2'}),
      ],
      compute: (m) => _validateResult('R', m['V']! / m['I']!, 'Circuits', 'Ohm\'s Law'),
    ),
    Tool(
      id: 'kinetic_energy',
      title: 'Kinetic Energy',
      category: 'Physics',
      subcategory: 'Dynamics',
      description: 'Compute kinetic energy from mass and velocity.',
      popularity: 80,
      inputs: const [
        ToolInputSchema(key: 'm', label: 'Mass', unitOptions: ['kg', 'g'], defaultValue: '1'),
        ToolInputSchema(key: 'v', label: 'Velocity', unitOptions: ['m/s', 'km/h'], defaultValue: '2'),
      ],
      compute: (m) => _validateResult('KE', 0.5 * m['m']! * m['v']! * m['v']!, 'Physics', 'Kinetic Energy'),
    ),
    Tool(
      id: 'power',
      title: 'Electrical Power',
      category: 'Circuits',
      subcategory: 'Core tools',
      description: 'Find power from voltage and current.',
      isCore: true,
      popularity: 90,
      inputs: const [
        ToolInputSchema(key: 'V', label: 'Voltage', unitOptions: ['V', 'mV'], defaultValue: '10'),
        ToolInputSchema(key: 'I', label: 'Current', unitOptions: ['A', 'mA'], defaultValue: '1'),
      ],
      presets: const [
        ToolPreset(name: 'USB 5V/2A', values: {'V': '5', 'I': '2'}),
      ],
      compute: (m) => _validateResult('P', m['V']! * m['I']!, 'Circuits', 'Electrical Power'),
    ),
    Tool(
      id: 'cap_charge',
      title: 'Capacitor Charge Time',
      category: 'Electronics',
      subcategory: 'Time constants',
      description: 'Estimate 5τ charge time.',
      inputs: const [
        ToolInputSchema(key: 'R', label: 'Resistance', unitOptions: ['Ω', 'kΩ'], defaultValue: '1000'),
        ToolInputSchema(key: 'C', label: 'Capacitance', unitOptions: ['F', 'mF', 'µF'], defaultValue: '0.001'),
      ],
      compute: (m) => _validateResult('t', 5 * m['R']! * m['C']!, 'Electronics', 'Capacitor Charge Time'),
    ),
    Tool(
      id: 'bandwidth',
      title: 'Nyquist Rate',
      category: 'Signals',
      subcategory: 'Sampling',
      description: 'Compute minimum sampling rate from bandwidth.',
      isCore: true,
      popularity: 85,
      hasGraph: true,
      inputs: const [
        ToolInputSchema(key: 'B', label: 'Bandwidth', unitOptions: ['Hz', 'kHz', 'MHz'], defaultValue: '1000'),
      ],
      compute: (m) => _validateResult('Rate', 2 * m['B']!, 'Signals', 'Nyquist Rate'),
    ),
    Tool(
      id: 'cpu_time',
      title: 'CPU Time',
      category: 'Computer Arch',
      subcategory: 'Performance',
      description: 'Estimate execution time from IC, CPI, and clock rate.',
      popularity: 70,
      inputs: const [
        ToolInputSchema(key: 'IC', label: 'Instruction count', defaultValue: '1000000'),
        ToolInputSchema(key: 'CPI', label: 'Cycles per instruction', defaultValue: '1.2'),
        ToolInputSchema(key: 'Clock', label: 'Clock rate', unitOptions: ['Hz', 'MHz', 'GHz'], defaultValue: '2000000000'),
      ],
      compute: (m) => _validateResult('Time', (m['IC']! * m['CPI']!) / m['Clock']!, 'Computer Arch', 'CPU Time'),
    ),
    Tool(
      id: 'slope',
      title: 'Line Slope',
      category: 'Math',
      subcategory: 'Core tools',
      description: 'Compute line slope from rise and run.',
      isCore: true,
      hasGraph: true,
      popularity: 88,
      inputs: const [
        ToolInputSchema(key: 'dy', label: 'Rise', defaultValue: '3'),
        ToolInputSchema(key: 'dx', label: 'Run', defaultValue: '4'),
      ],
      compute: (m) => _validateResult('m', m['dy']! / m['dx']!, 'Math', 'Line Slope'),
    ),
    Tool(
      id: 'mean',
      title: 'Mean Value',
      category: 'Stats',
      subcategory: 'Core tools',
      description: 'Average from sum and count.',
      isCore: true,
      popularity: 84,
      inputs: const [
        ToolInputSchema(key: 'sum', label: 'Sum of values', defaultValue: '100'),
        ToolInputSchema(key: 'n', label: 'Number of samples', defaultValue: '5'),
      ],
      compute: (m) => _validateResult('Mean', m['sum']! / m['n']!, 'Stats', 'Mean Value'),
    ),
    Tool(
      id: 'std_err',
      title: 'Standard Error',
      category: 'Stats',
      subcategory: 'Complexity',
      description: 'Standard error from standard deviation and sample size.',
      hasGraph: true,
      popularity: 74,
      inputs: const [
        ToolInputSchema(key: 'sd', label: 'Std. deviation', defaultValue: '2.5'),
        ToolInputSchema(key: 'n', label: 'Sample size', defaultValue: '25'),
      ],
      compute: (m) => _validateResult('SE', m['sd']! / math.sqrt(m['n']!), 'Stats', 'Standard Error'),
    ),
    Tool(
      id: 'throughput',
      title: 'System Throughput',
      category: 'Software',
      subcategory: 'Complexity',
      description: 'Tasks completed per second.',
      popularity: 76,
      inputs: const [
        ToolInputSchema(key: 'tasks', label: 'Tasks completed', defaultValue: '1200'),
        ToolInputSchema(key: 'seconds', label: 'Elapsed seconds', defaultValue: '60'),
        ToolInputSchema(key: 'threads', label: 'Worker threads', defaultValue: '4', isAdvanced: true, required: false),
      ],
      presets: const [
        ToolPreset(name: '8-bit batch', values: {'tasks': '256', 'seconds': '8'}),
      ],
      compute: (m) => _validateResult('TPS', m['tasks']! / m['seconds']!, 'Software', 'System Throughput'),
    ),
  ];

  static Tool byId(String id) => tools.firstWhere((t) => t.id == id);
}

ToolResult _validateResult(String out, double value, String category, String title) {
  if (value.isNaN || value.isInfinite) {
    return const ToolResult(mainResult: 'Invalid input', error: 'Please check inputs.');
  }
  return ToolResult(
    mainResult: '$out = ${value.toStringAsFixed(4)}',
    secondaryResults: [MapEntry('Category', category)],
    steps: ['Read inputs', 'Apply $title formula', 'Format output'],
  );
}
