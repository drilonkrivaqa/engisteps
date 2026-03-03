import 'dart:math' as math;

import '../../../core/models/tool.dart';

class ToolRegistry {
  static final List<Tool> tools = <Tool>[
    Tool(
      id: 'quadratic_solver',
      title: 'Quadratic Solver',
      category: 'Math',
      description: 'Solve ax² + bx + c = 0 with real/complex roots.',
      explain: 'Useful in algebra, signals, and control problems where characteristic equations appear.',
      inputs: const [
        ToolInputSchema(key: 'a', label: 'a', defaultValue: '1'),
        ToolInputSchema(key: 'b', label: 'b', defaultValue: '-3'),
        ToolInputSchema(key: 'c', label: 'c', defaultValue: '2'),
      ],
      compute: (m) {
        final a = m['a']!;
        final b = m['b']!;
        final c = m['c']!;
        if (a == 0) return const ToolResult(mainResult: 'a must be non-zero', error: 'Invalid input');
        final d = b * b - 4 * a * c;
        final denom = 2 * a;
        if (d >= 0) {
          final x1 = (-b + math.sqrt(d)) / denom;
          final x2 = (-b - math.sqrt(d)) / denom;
          return ToolResult(
            mainResult: 'x₁=${_n(x1)}, x₂=${_n(x2)}',
            secondaryResults: [MapEntry('Discriminant', _n(d))],
            steps: [
              'Compute discriminant: Δ = b² - 4ac = ${_n(d)}',
              'Use x = (-b ± √Δ)/(2a)',
              'x₁=${_n(x1)}, x₂=${_n(x2)}'
            ],
          );
        }
        final real = -b / denom;
        final imag = math.sqrt(-d) / denom;
        return ToolResult(
          mainResult: 'x₁=${_n(real)} + ${_n(imag)}i, x₂=${_n(real)} - ${_n(imag)}i',
          secondaryResults: [MapEntry('Discriminant', _n(d))],
          steps: ['Δ < 0, so roots are complex.', 'Real part = -b/(2a), Imaginary part = √(-Δ)/(2a)'],
        );
      },
    ),
    Tool(
      id: 'linear_2x2',
      title: 'Linear System 2x2',
      category: 'Math',
      description: 'Solve a₁x+b₁y=c₁ and a₂x+b₂y=c₂.',
      inputs: const [
        ToolInputSchema(key: 'a1', label: 'a₁', defaultValue: '2'),
        ToolInputSchema(key: 'b1', label: 'b₁', defaultValue: '1'),
        ToolInputSchema(key: 'c1', label: 'c₁', defaultValue: '5'),
        ToolInputSchema(key: 'a2', label: 'a₂', defaultValue: '1'),
        ToolInputSchema(key: 'b2', label: 'b₂', defaultValue: '-1'),
        ToolInputSchema(key: 'c2', label: 'c₂', defaultValue: '1'),
      ],
      compute: (m) {
        final det = m['a1']! * m['b2']! - m['a2']! * m['b1']!;
        if (det == 0) return const ToolResult(mainResult: 'No unique solution');
        final x = (m['c1']! * m['b2']! - m['c2']! * m['b1']!) / det;
        final y = (m['a1']! * m['c2']! - m['a2']! * m['c1']!) / det;
        return ToolResult(mainResult: 'x=${_n(x)}, y=${_n(y)}', steps: ['Use Cramer determinant D=${_n(det)}']);
      },
    ),
    Tool(
      id: 'determinant_3x3',
      title: 'Matrix Determinant 3x3',
      category: 'Math',
      description: 'Determinant of a 3x3 matrix.',
      inputs: const [
        ToolInputSchema(key: 'a', label: 'a', defaultValue: '1'),
        ToolInputSchema(key: 'b', label: 'b', defaultValue: '2'),
        ToolInputSchema(key: 'c', label: 'c', defaultValue: '3'),
        ToolInputSchema(key: 'd', label: 'd', defaultValue: '0'),
        ToolInputSchema(key: 'e', label: 'e', defaultValue: '1'),
        ToolInputSchema(key: 'f', label: 'f', defaultValue: '4'),
        ToolInputSchema(key: 'g', label: 'g', defaultValue: '5'),
        ToolInputSchema(key: 'h', label: 'h', defaultValue: '6'),
        ToolInputSchema(key: 'i', label: 'i', defaultValue: '0'),
      ],
      compute: (m) {
        final det = m['a']! * (m['e']! * m['i']! - m['f']! * m['h']!) -
            m['b']! * (m['d']! * m['i']! - m['f']! * m['g']!) +
            m['c']! * (m['d']! * m['h']! - m['e']! * m['g']!);
        return ToolResult(mainResult: 'det=${_n(det)}', steps: ['Expand along first row.']);
      },
    ),
    Tool(
      id: 'complex_ops',
      title: 'Complex Multiply/Divide + Polar',
      category: 'Math',
      description: 'z1 and z2 operations with polar conversion.',
      inputs: const [
        ToolInputSchema(key: 'a', label: 'z1 real', defaultValue: '2'),
        ToolInputSchema(key: 'b', label: 'z1 imag', defaultValue: '3'),
        ToolInputSchema(key: 'c', label: 'z2 real', defaultValue: '1'),
        ToolInputSchema(key: 'd', label: 'z2 imag', defaultValue: '-2'),
      ],
      compute: (m) {
        final a = m['a']!;
        final b = m['b']!;
        final c = m['c']!;
        final d = m['d']!;
        final mulR = a * c - b * d;
        final mulI = a * d + b * c;
        final den = c * c + d * d;
        final divR = (a * c + b * d) / den;
        final divI = (b * c - a * d) / den;
        final r = math.sqrt(a * a + b * b);
        final th = math.atan2(b, a) * 180 / math.pi;
        return ToolResult(
          mainResult: '(z1·z2)=${_n(mulR)} + ${_n(mulI)}i',
          secondaryResults: [
            MapEntry('z1/z2', '${_n(divR)} + ${_n(divI)}i'),
            MapEntry('z1 polar', 'r=${_n(r)}, θ=${_n(th)}°'),
          ],
          steps: ['Multiply with distributive rule.', 'Divide using conjugate denominator.', 'Polar: r=√(a²+b²), θ=atan2(b,a).'],
        );
      },
    ),
    Tool(
      id: 'numeric_derivative',
      title: 'Derivative (Polynomial + Numeric)',
      category: 'Math',
      description: 'For f(x)=ax²+bx+c, compute f’(x) and numeric slope.',
      inputs: const [
        ToolInputSchema(key: 'a', label: 'a', defaultValue: '1'),
        ToolInputSchema(key: 'b', label: 'b', defaultValue: '0'),
        ToolInputSchema(key: 'c', label: 'c', defaultValue: '0'),
        ToolInputSchema(key: 'x', label: 'x point', defaultValue: '2'),
      ],
      compute: (m) {
        final der = 2 * m['a']! * m['x']! + m['b']!;
        return ToolResult(
          mainResult: "f'(x)=${_n(der)}",
          secondaryResults: const [MapEntry('Rule', "d/dx(ax²+bx+c)=2ax+b")],
          steps: ['Power rule: d/dx(ax²)=2ax, d/dx(bx)=b, d/dx(c)=0'],
        );
      },
    ),
    Tool(
      id: 'numeric_integral',
      title: 'Numeric Integral (Trap/Simpson)',
      category: 'Math',
      description: 'Integrate f(x)=ax²+bx+c on [x0,x1].',
      inputs: const [
        ToolInputSchema(key: 'a', label: 'a', defaultValue: '1'),
        ToolInputSchema(key: 'b', label: 'b', defaultValue: '0'),
        ToolInputSchema(key: 'c', label: 'c', defaultValue: '0'),
        ToolInputSchema(key: 'x0', label: 'x0', defaultValue: '0'),
        ToolInputSchema(key: 'x1', label: 'x1', defaultValue: '2'),
      ],
      compute: (m) {
        double f(double x) => m['a']! * x * x + m['b']! * x + m['c']!;
        final x0 = m['x0']!;
        final x1 = m['x1']!;
        final trap = (x1 - x0) * (f(x0) + f(x1)) / 2;
        final xm = (x0 + x1) / 2;
        final simpson = (x1 - x0) * (f(x0) + 4 * f(xm) + f(x1)) / 6;
        return ToolResult(mainResult: 'Trapezoid=${_n(trap)}', secondaryResults: [MapEntry('Simpson', _n(simpson))]);
      },
    ),
    Tool(
      id: 'kinematics',
      title: 'Kinematics (u,v,a,t,s)',
      category: 'Physics',
      description: 'Uses v=u+at and s=ut+½at² to solve basics.',
      inputs: const [
        ToolInputSchema(key: 'u', label: 'u (m/s)', defaultValue: '0'),
        ToolInputSchema(key: 'a', label: 'a (m/s²)', defaultValue: '2'),
        ToolInputSchema(key: 't', label: 't (s)', defaultValue: '4'),
      ],
      compute: (m) {
        final v = m['u']! + m['a']! * m['t']!;
        final s = m['u']! * m['t']! + 0.5 * m['a']! * m['t']! * m['t']!;
        return ToolResult(mainResult: 'v=${_n(v)} m/s', secondaryResults: [MapEntry('s', '${_n(s)} m')], steps: ['v=u+at', 's=ut+½at²']);
      },
    ),
    Tool(
      id: 'projectile',
      title: 'Projectile Motion',
      category: 'Physics',
      description: 'Range, flight time, and max height.',
      inputs: const [
        ToolInputSchema(key: 'v0', label: 'v0', defaultValue: '20', unit: 'm/s', examples: ['10', '20', '50'], min: 0),
        ToolInputSchema(key: 'theta', label: 'θ', type: ToolInputType.angle, defaultValue: '45', examples: ['30', '45', '60']),
      ],
      compute: (m) {
        const g = 9.81;
        final t = m['theta']! * math.pi / 180;
        final time = 2 * m['v0']! * math.sin(t) / g;
        final range = m['v0']! * m['v0']! * math.sin(2 * t) / g;
        final h = m['v0']! * m['v0']! * math.pow(math.sin(t), 2) / (2 * g);
        return ToolResult(mainResult: 'Range=${_n(range)} m', secondaryResults: [MapEntry('Time', '${_n(time)} s'), MapEntry('Hmax', '${_n(h.toDouble())} m')]);
      },
    ),
    Tool(
      id: 'work_energy_power',
      title: 'Work / Energy / Power',
      category: 'Physics',
      description: 'W=F·d and P=W/t.',
      inputs: const [
        ToolInputSchema(key: 'F', label: 'Force (N)', defaultValue: '10'),
        ToolInputSchema(key: 'd', label: 'Distance (m)', defaultValue: '5'),
        ToolInputSchema(key: 't', label: 'Time (s)', defaultValue: '2'),
      ],
      compute: (m) {
        final w = m['F']! * m['d']!;
        final p = w / m['t']!;
        return ToolResult(mainResult: 'Work=${_n(w)} J', secondaryResults: [MapEntry('Power', '${_n(p)} W')]);
      },
    ),
    Tool(
      id: 'ohms_resistors',
      title: 'Ohm + Resistor Series/Parallel',
      category: 'Physics',
      description: 'Ohm law and equivalent resistance.',
      inputs: const [
        ToolInputSchema(key: 'V', label: 'Voltage', defaultValue: '12', unit: 'V', min: 0),
        ToolInputSchema(key: 'R1', label: 'R1', defaultValue: '100', unitOptions: [
          ToolUnitOption(symbol: 'Ω', factorToBase: 1),
          ToolUnitOption(symbol: 'kΩ', factorToBase: 1e3),
          ToolUnitOption(symbol: 'MΩ', factorToBase: 1e6),
        ], examples: ['100', '1000'], min: 0),
        ToolInputSchema(key: 'R2', label: 'R2', defaultValue: '200', unitOptions: [
          ToolUnitOption(symbol: 'Ω', factorToBase: 1),
          ToolUnitOption(symbol: 'kΩ', factorToBase: 1e3),
          ToolUnitOption(symbol: 'MΩ', factorToBase: 1e6),
        ], examples: ['220', '1000'], min: 0),
        ToolInputSchema(key: 'mode', label: 'Connection', type: ToolInputType.dropdown, options: [
          ToolSelectOption(label: 'Series', value: 0),
          ToolSelectOption(label: 'Parallel', value: 1),
        ]),
      ],
      compute: (m) {
        final rs = m['R1']! + m['R2']!;
        final rp = (m['R1']! * m['R2']!) / (m['R1']! + m['R2']!);
        final selectedReq = (m['mode'] ?? 0) == 1 ? rp : rs;
        final i = m['V']! / selectedReq;
        return ToolResult(mainResult: 'Req=${_n(selectedReq)} Ω', secondaryResults: [MapEntry('Series Req', '${_n(rs)} Ω'), MapEntry('Parallel Req', '${_n(rp)} Ω'), MapEntry('Current', '${_n(i)} A')]);
      },
    ),
    Tool(
      id: 'capacitors',
      title: 'Capacitors + Energy',
      category: 'Physics',
      description: 'Series/parallel capacitance and stored energy.',
      inputs: const [
        ToolInputSchema(key: 'C1', label: 'C1', defaultValue: '1', unitOptions: [
          ToolUnitOption(symbol: 'F', factorToBase: 1),
          ToolUnitOption(symbol: 'mF', factorToBase: 1e-3),
          ToolUnitOption(symbol: 'µF', factorToBase: 1e-6),
          ToolUnitOption(symbol: 'nF', factorToBase: 1e-9),
        ], examples: ['1', '10', '100']),
        ToolInputSchema(key: 'C2', label: 'C2', defaultValue: '2', unitOptions: [
          ToolUnitOption(symbol: 'F', factorToBase: 1),
          ToolUnitOption(symbol: 'mF', factorToBase: 1e-3),
          ToolUnitOption(symbol: 'µF', factorToBase: 1e-6),
          ToolUnitOption(symbol: 'nF', factorToBase: 1e-9),
        ], examples: ['1', '10', '100']),
        ToolInputSchema(key: 'V', label: 'Voltage', defaultValue: '10', unit: 'V', min: 0),
      ],
      compute: (m) {
        final cp = m['C1']! + m['C2']!;
        final cs = (m['C1']! * m['C2']!) / (m['C1']! + m['C2']!);
        final e = 0.5 * cp * m['V']! * m['V']!;
        return ToolResult(mainResult: 'Cparallel=${_n(cp)} F', secondaryResults: [MapEntry('Cseries', '${_n(cs)} F'), MapEntry('Energy (parallel)', '${_n(e)} J')]);
      },
    ),
    Tool(
      id: 'coulomb_field',
      title: 'Coulomb Law + Field',
      category: 'Physics',
      description: 'Force and electric field for point charges.',
      inputs: const [
        ToolInputSchema(key: 'q1', label: 'q1 (C)', defaultValue: '0.000001'),
        ToolInputSchema(key: 'q2', label: 'q2 (C)', defaultValue: '0.000002'),
        ToolInputSchema(key: 'r', label: 'r (m)', defaultValue: '0.1'),
      ],
      compute: (m) {
        const k = 8.9875517923e9;
        final f = k * m['q1']! * m['q2']! / (m['r']! * m['r']!);
        final e = k * m['q1']! / (m['r']! * m['r']!);
        return ToolResult(mainResult: 'F=${_n(f)} N', secondaryResults: [MapEntry('E', '${_n(e)} N/C')]);
      },
    ),
    Tool(
      id: 'unit_converter',
      title: 'Unit Converter',
      category: 'Physics',
      description: 'Generic converter using factor method.',
      inputs: const [
        ToolInputSchema(key: 'value', label: 'Value', defaultValue: '1'),
        ToolInputSchema(key: 'fromFactor', label: 'From base factor', defaultValue: '1'),
        ToolInputSchema(key: 'toFactor', label: 'To base factor', defaultValue: '1000'),
      ],
      compute: (m) {
        final out = m['value']! * m['fromFactor']! / m['toFactor']!;
        return ToolResult(mainResult: 'Converted=${_n(out)}');
      },
    ),
    Tool(
      id: 'voltage_divider',
      title: 'Voltage Divider',
      category: 'Circuits',
      description: 'Vout = Vin * R2/(R1+R2).',
      inputs: const [
        ToolInputSchema(key: 'Vin', label: 'Vin (V)', defaultValue: '12'),
        ToolInputSchema(key: 'R1', label: 'R1 (Ω)', defaultValue: '1000'),
        ToolInputSchema(key: 'R2', label: 'R2 (Ω)', defaultValue: '1000'),
      ],
      compute: (m) {
        final vout = m['Vin']! * m['R2']! / (m['R1']! + m['R2']!);
        return ToolResult(mainResult: 'Vout=${_n(vout)} V', steps: ['Apply divider ratio R2/(R1+R2).']);
      },
    ),
    Tool(
      id: 'rc_charge',
      title: 'RC Charge/Discharge',
      category: 'Circuits',
      description: 'Time constant and voltage at time t.',
      inputs: const [
        ToolInputSchema(key: 'R', label: 'R', defaultValue: '1', unitOptions: [
          ToolUnitOption(symbol: 'Ω', factorToBase: 1),
          ToolUnitOption(symbol: 'kΩ', factorToBase: 1e3),
        ], examples: ['1', '10']),
        ToolInputSchema(key: 'C', label: 'C', defaultValue: '1', unitOptions: [
          ToolUnitOption(symbol: 'F', factorToBase: 1),
          ToolUnitOption(symbol: 'mF', factorToBase: 1e-3),
          ToolUnitOption(symbol: 'µF', factorToBase: 1e-6),
        ], examples: ['1', '10', '100']),
        ToolInputSchema(key: 'Vin', label: 'Vin', defaultValue: '5', unit: 'V'),
        ToolInputSchema(key: 't', label: 't', type: ToolInputType.range, defaultValue: '1', min: 0, max: 10, unit: 's'),
      ],
      compute: (m) {
        final tau = m['R']! * m['C']!;
        final vc = m['Vin']! * (1 - math.exp(-m['t']! / tau));
        return ToolResult(mainResult: 'τ=${_n(tau)} s', secondaryResults: [MapEntry('Vc(t)', '${_n(vc)} V')]);
      },
    ),
    Tool(
      id: 'ac_power_basic',
      title: 'AC Power Basics',
      category: 'Circuits',
      description: 'P, Q, S and power factor.',
      inputs: const [
        ToolInputSchema(key: 'V', label: 'Vrms (V)', defaultValue: '230'),
        ToolInputSchema(key: 'I', label: 'Irms (A)', defaultValue: '2'),
        ToolInputSchema(key: 'pf', label: 'Power factor', defaultValue: '0.8'),
      ],
      compute: (m) {
        final s = m['V']! * m['I']!;
        final p = s * m['pf']!;
        final q = math.sqrt(math.max(0, s * s - p * p));
        return ToolResult(mainResult: 'P=${_n(p)} W', secondaryResults: [MapEntry('Q', '${_n(q)} var'), MapEntry('S', '${_n(s)} VA')]);
      },
    ),
    Tool(
      id: 'thevenin_norton',
      title: 'Thevenin/Norton Helper',
      category: 'Circuits',
      description: 'From Voc and Rth compute In and equivalent.',
      inputs: const [
        ToolInputSchema(key: 'Voc', label: 'Voc (V)', defaultValue: '10'),
        ToolInputSchema(key: 'Rth', label: 'Rth (Ω)', defaultValue: '100'),
      ],
      compute: (m) {
        final inorton = m['Voc']! / m['Rth']!;
        return ToolResult(mainResult: 'Inorton=${_n(inorton)} A', secondaryResults: [MapEntry('Vth', '${_n(m['Voc']!)} V'), MapEntry('Rn', '${_n(m['Rth']!)} Ω')]);
      },
    ),
    Tool(
      id: 'percent_error',
      title: 'Percentage/Relative Error',
      category: 'Helpers',
      description: 'Compute absolute, relative, and percent error.',
      inputs: const [
        ToolInputSchema(key: 'measured', label: 'Measured', defaultValue: '9.8'),
        ToolInputSchema(key: 'true', label: 'True', defaultValue: '10'),
      ],
      compute: (m) {
        final abs = (m['measured']! - m['true']!).abs();
        final rel = abs / m['true']!;
        return ToolResult(mainResult: '% error=${_n(rel * 100)}%', secondaryResults: [MapEntry('Abs error', _n(abs)), MapEntry('Relative', _n(rel))]);
      },
    ),
    Tool(
      id: 'scientific_notation',
      title: 'Scientific Notation Helper',
      category: 'Helpers',
      description: 'Convert number to a×10^n.',
      inputs: const [ToolInputSchema(key: 'x', label: 'Value', defaultValue: '12345')],
      compute: (m) {
        final x = m['x']!;
        if (x == 0) return const ToolResult(mainResult: '0 = 0×10^0');
        final n = (math.log(x.abs()) / math.ln10).floor();
        final a = x / math.pow(10, n);
        return ToolResult(mainResult: '${_n(a.toDouble())} × 10^$n');
      },
    ),
    Tool(
      id: 'sig_figs',
      title: 'Significant Figures Helper',
      category: 'Helpers',
      description: 'Round value to n significant figures.',
      inputs: const [
        ToolInputSchema(key: 'x', label: 'Value', defaultValue: '3.1415926'),
        ToolInputSchema(key: 'n', label: 'Sig figs', defaultValue: '3'),
      ],
      compute: (m) {
        final n = m['n']!.round();
        final x = m['x']!;
        final exp = math.pow(10, n - 1 - (math.log(x.abs()) / math.ln10).floor());
        final r = (x * exp).round() / exp;
        return ToolResult(mainResult: 'Rounded=${_n(r)}');
      },
    ),
    Tool(
      id: 'constants_library',
      title: 'Quick Constants Library',
      category: 'Helpers',
      description: 'g, k, ε0, μ0 and more.',
      inputs: const [],
      compute: (_) => const ToolResult(
        mainResult: 'g=9.81 m/s²',
        secondaryResults: [
          MapEntry('k', '8.9875517923×10^9 N·m²/C²'),
          MapEntry('ε0', '8.8541878128×10^-12 F/m'),
          MapEntry('μ0', '1.25663706212×10^-6 H/m'),
        ],
      ),
    ),
  ];

  static Tool byId(String id) => tools.firstWhere((t) => t.id == id);

  static List<String> categories() => tools.map((e) => e.category).toSet().toList()..sort();
}

String _n(double v) => v.toStringAsPrecision(6);
