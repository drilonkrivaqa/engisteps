import 'dart:math' as math;

import '../../../core/models/tool.dart';

class ToolRegistry {
  static final List<Tool> tools = <Tool>[
    // =====================
    // Circuits / Electronics
    // =====================
    Tool(
      id: 'ohms_law',
      title: "Ohm's Law",
      category: 'Circuits',
      subcategory: 'Basics',
      description: 'Solve V = I·R (find voltage, current, or resistance).',
      tags: const ['resistance', 'voltage', 'current'],
      isCore: true,
      popularity: 98,
      inputs: const [
        ToolInputSchema(key: 'V', label: 'Voltage (V)', defaultValue: '5', min: 0),
        ToolInputSchema(key: 'I', label: 'Current (A)', defaultValue: '0.5', min: 0),
      ],
      presets: const [
        ToolPreset(name: 'USB 5V @ 2A', values: {'V': '5', 'I': '2'}),
        ToolPreset(name: 'Car 12V @ 1.5A', values: {'V': '12', 'I': '1.5'}),
      ],
      compute: (m) {
        final v = m['V']!;
        final i = m['I']!;
        final r = v / i;

        return ToolResult(
          mainResult: _fmt('R', r, 'Ω'),
          secondaryResults: [
            MapEntry('Formula', 'R = V / I'),
            MapEntry('Given', 'V=$v V, I=$i A'),
          ],
          steps: [
            'Start with Ohm’s law: V = I·R',
            'Rearrange to solve for resistance: R = V / I',
            'Substitute values: R = $v / $i',
          ],
        );
      },
    ),
    Tool(
      id: 'power_dc',
      title: 'Electrical Power (DC)',
      category: 'Circuits',
      subcategory: 'Basics',
      description: 'Compute P = V·I, plus energy estimate.',
      tags: const ['power', 'watts', 'energy'],
      isCore: true,
      popularity: 93,
      inputs: const [
        ToolInputSchema(key: 'V', label: 'Voltage (V)', defaultValue: '12', min: 0),
        ToolInputSchema(key: 'I', label: 'Current (A)', defaultValue: '2', min: 0),
        ToolInputSchema(key: 't', label: 'Time (s) (optional)', defaultValue: '60', required: false, min: 0),
      ],
      compute: (m) {
        final p = m['V']! * m['I']!;
        final t = m['t'] ?? 0;
        final e = p * t;

        return ToolResult(
          mainResult: _fmt('P', p, 'W'),
          secondaryResults: [
            MapEntry('Energy', t > 0 ? _fmt('E', e, 'J') : 'Provide time to compute'),
            const MapEntry('Formula', 'P = V·I'),
          ],
          steps: [
            'Use P = V·I',
            'Multiply voltage by current to get power',
            if (t > 0) 'Energy over time: E = P·t',
          ],
        );
      },
    ),
    Tool(
      id: 'rc_time_constant',
      title: 'RC Time Constant',
      category: 'Electronics',
      subcategory: 'Time constants',
      description: 'Compute τ = R·C and 5τ (≈99% charge/discharge).',
      tags: const ['capacitor', 'resistor', 'tau'],
      popularity: 86,
      inputs: const [
        ToolInputSchema(key: 'R', label: 'Resistance (Ω)', defaultValue: '1000', min: 0),
        ToolInputSchema(key: 'C', label: 'Capacitance (F)', defaultValue: '0.000001', min: 0),
      ],
      compute: (m) {
        final tau = m['R']! * m['C']!;
        final t5 = 5 * tau;

        return ToolResult(
          mainResult: _fmt('τ', tau, 's'),
          secondaryResults: [
            MapEntry('~99% time', _fmt('5τ', t5, 's')),
            const MapEntry('Formula', 'τ = R·C'),
          ],
          steps: [
            'Time constant τ = R·C',
            'For practical full charge/discharge use about 5τ',
          ],
        );
      },
    ),

    // ==========
    // Signals
    // ==========
    Tool(
      id: 'nyquist_rate',
      title: 'Nyquist Sampling Rate',
      category: 'Signals',
      subcategory: 'Sampling',
      description: 'Minimum sampling frequency: fs ≥ 2B.',
      tags: const ['sampling', 'bandwidth'],
      isCore: true,
      hasGraph: true,
      popularity: 90,
      inputs: const [
        ToolInputSchema(key: 'B', label: 'Bandwidth (Hz)', defaultValue: '1000', min: 0),
      ],
      compute: (m) {
        final b = m['B']!;
        final fs = 2 * b;
        return ToolResult(
          mainResult: _fmt('fs(min)', fs, 'Hz'),
          secondaryResults: [
            const MapEntry('Formula', 'fs ≥ 2B'),
            MapEntry('Bandwidth', '$b Hz'),
          ],
          steps: [
            'Nyquist requires sampling at least twice the highest frequency component.',
            'Compute fs(min) = 2·B',
          ],
        );
      },
    ),

    // ==========
    // Physics
    // ==========
    Tool(
      id: 'kinetic_energy',
      title: 'Kinetic Energy',
      category: 'Physics',
      subcategory: 'Dynamics',
      description: 'Compute KE = ½·m·v².',
      tags: const ['energy', 'motion'],
      isCore: true,
      popularity: 88,
      inputs: const [
        ToolInputSchema(key: 'm', label: 'Mass (kg)', defaultValue: '1', min: 0),
        ToolInputSchema(key: 'v', label: 'Velocity (m/s)', defaultValue: '2', min: 0),
      ],
      compute: (m) {
        final ke = 0.5 * m['m']! * math.pow(m['v']!, 2);
        return ToolResult(
          mainResult: _fmt('KE', ke.toDouble(), 'J'),
          secondaryResults: const [MapEntry('Formula', 'KE = ½·m·v²')],
          steps: [
            'Square the velocity v²',
            'Multiply by mass m',
            'Multiply by ½',
          ],
        );
      },
    ),

    // ==========
    // Math / Stats
    // ==========
    Tool(
      id: 'line_slope',
      title: 'Line Slope',
      category: 'Math',
      subcategory: 'Algebra',
      description: 'Compute slope m = Δy / Δx.',
      tags: const ['slope', 'line'],
      isCore: true,
      hasGraph: true,
      popularity: 84,
      inputs: const [
        ToolInputSchema(key: 'dy', label: 'Δy', defaultValue: '3'),
        ToolInputSchema(key: 'dx', label: 'Δx', defaultValue: '4', min: 0.0000001),
      ],
      compute: (m) {
        final slope = m['dy']! / m['dx']!;
        return ToolResult(
          mainResult: _fmt('m', slope, ''),
          secondaryResults: const [MapEntry('Formula', 'm = Δy / Δx')],
          steps: [
            'Take the change in y (Δy)',
            'Divide by the change in x (Δx)',
          ],
        );
      },
    ),
    Tool(
      id: 'mean',
      title: 'Mean Value',
      category: 'Stats',
      subcategory: 'Basics',
      description: 'Compute mean = sum / n.',
      tags: const ['average'],
      isCore: true,
      popularity: 80,
      inputs: const [
        ToolInputSchema(key: 'sum', label: 'Sum of values', defaultValue: '100'),
        ToolInputSchema(key: 'n', label: 'Number of samples', defaultValue: '5', min: 1),
      ],
      compute: (m) {
        final mean = m['sum']! / m['n']!;
        return ToolResult(
          mainResult: _fmt('Mean', mean, ''),
          secondaryResults: const [MapEntry('Formula', 'mean = sum / n')],
          steps: [
            'Divide the total sum by the number of samples',
          ],
        );
      },
    ),

    // ==========
    // Computer Eng (your uni track)
    // ==========
    Tool(
      id: 'binary_ones_complement',
      title: "1's Complement (Binary)",
      category: 'Computer Arch',
      subcategory: 'Binary',
      description: 'Invert bits of a binary number.',
      tags: const ['binary', 'complement'],
      popularity: 78,
      inputs: const [
        ToolInputSchema(key: 'bits', label: 'Binary (e.g. 010011)', defaultValue: '010011'),
      ],
      compute: (m) {
        // We store input as a numeric but here we want raw text.
        // This tool is handled specially in UI (text input).
        return const ToolResult(
          mainResult: 'Use the text mode input (handled in UI).',
        );
      },
    ),
  ];

  static Tool byId(String id) => tools.firstWhere((t) => t.id == id);

  static List<String> categories() {
    final s = tools.map((e) => e.category).toSet().toList()..sort();
    return s;
  }
}

String _fmt(String symbol, double value, String unit) {
  if (value.isNaN || value.isInfinite) return '$symbol = Invalid';
  final u = unit.isEmpty ? '' : ' $unit';
  return '$symbol = ${value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '')}$u';
}