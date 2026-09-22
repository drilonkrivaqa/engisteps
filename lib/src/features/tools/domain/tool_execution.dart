import 'dart:async';
import '../../../core/models/tool.dart';

/// The single boundary for validating and executing a calculation.
class ToolExecution {
  static ToolResult run(
    Tool tool,
    Map<String, double> inputs, {
    int precision = 4,
    bool scientific = false,
  }) {
    for (final field in tool.inputs) {
      final value = inputs[field.key];
      if (value == null || !value.isFinite) {
        return _error('${field.label}: enter a finite number.');
      }
      if (field.type == ToolInputType.integer &&
          value != value.roundToDouble()) {
        return _error('${field.label} must be a whole number.');
      }
      if (field.options.isNotEmpty &&
          !field.options.any((o) => o.value == value)) {
        return _error('Choose a valid ${field.label.toLowerCase()}.');
      }
      if (field.min != null && value < field.min! ||
          field.max != null && value > field.max!) {
        return _error('${field.label} is outside the allowed range.');
      }
    }
    const positive = <String, List<String>>{
      'work_energy_power': ['t'],
      'ohms_resistors': ['R1', 'R2'],
      'capacitors': ['C1', 'C2'],
      'coulomb_field': ['r'],
      'rc_charge': ['R', 'C'],
      'thevenin_norton': ['Rth'],
      'beam_bending_stress': ['I'],
      'reynolds_number': ['rho', 'D', 'mu'],
      'ideal_gas': ['T', 'V'],
      'transformer_turns_ratio': ['Np', 'Ns'],
    };
    for (final key in positive[tool.id] ?? <String>[]) {
      if (inputs[key]! <= 0) return _error('$key must be greater than zero.');
    }
    if (tool.id == 'voltage_divider' &&
        (inputs['R1']! < 0 ||
            inputs['R2']! < 0 ||
            inputs['R1']! + inputs['R2']! == 0)) {
      return _error('Resistances must be non-negative with a non-zero sum.');
    }
    if (tool.id == 'complex_ops' && inputs['c'] == 0 && inputs['d'] == 0) {
      return _error('Cannot divide by a zero complex number.');
    }
    if (tool.id == 'percent_error' && inputs['true'] == 0) {
      return _error('Relative error is undefined for a zero reference.');
    }
    if (tool.id == 'ac_power_basic' &&
        (inputs['pf']!.abs() > 1 || inputs['V']! < 0 || inputs['I']! < 0)) {
      return _error(
        'Use non-negative RMS values and a power factor from −1 to 1.',
      );
    }
    if (tool.id == 'sig_figs' &&
        (inputs['n']! < 1 ||
            inputs['n']! > 15 ||
            inputs['n']! != inputs['n']!.roundToDouble())) {
      return _error('Significant figures must be a whole number from 1 to 15.');
    }
    if (tool.id == 'projectile' &&
        (inputs['theta']! < 0 || inputs['theta']! > 90)) {
      return _error('Launch angle must be between 0° and 90°.');
    }
    if (tool.id == 'kinematics' && inputs['t']! < 0 ||
        tool.id == 'reynolds_number' && inputs['V']! < 0 ||
        tool.id == 'ideal_gas' && inputs['n']! < 0) {
      return _error('Time, speed, and amount of substance cannot be negative.');
    }
    try {
      final result = runZoned(
        () => tool.compute(Map.unmodifiable(inputs)),
        zoneValues: {
          #precision: precision.clamp(0, 10),
          #scientific: scientific,
        },
      );
      final values = [
        result.mainResult,
        ...result.secondaryResults.map((e) => e.value),
      ];
      if (values.any((v) => v.contains('NaN') || v.contains('Infinity'))) {
        return _error('These inputs exceed the supported numerical range.');
      }
      if (result.error != null || result.steps.isNotEmpty) return result;
      return ToolResult(
        mainResult: result.mainResult,
        secondaryResults: result.secondaryResults,
        steps: [
          ..._formulas[tool.id] ?? [tool.description],
          if (inputs.isNotEmpty)
            'Values in base units (angles in degrees): ${inputs.entries.map((e) => '${e.key} = ${e.value}').join(', ')}',
        ],
      );
    } catch (_) {
      return _error(
        'Unable to calculate with these values. Check the inputs and try again.',
      );
    }
  }

  static ToolResult _error(String message) =>
      ToolResult(mainResult: message, error: message);

  static const _formulas = <String, List<String>>{
    'numeric_integral': [
      'Trapezoid = (x₁ − x₀)[f(x₀) + f(x₁)] / 2.',
      'Simpson = (x₁ − x₀)[f(x₀) + 4f((x₀ + x₁)/2) + f(x₁)] / 6. Simpson is exact for this quadratic polynomial, within floating-point precision.',
    ],
    'projectile': [
      'Flight time = 2v₀ sin(θ) / g.',
      'Range = v₀² sin(2θ) / g; maximum height = v₀² sin²(θ) / (2g).',
    ],
    'work_energy_power': [
      'Work = force × distance.',
      'Average power = work / elapsed time.',
    ],
    'ohms_resistors': [
      'Series: R = R₁ + R₂. Parallel: R = R₁R₂ / (R₁ + R₂).',
      'Use the selected connection to calculate I = V / R.',
    ],
    'capacitors': [
      'Parallel: C = C₁ + C₂. Series: C = C₁C₂ / (C₁ + C₂).',
      'Energy for the parallel connection: E = CV² / 2.',
    ],
    'coulomb_field': [
      'F = kq₁q₂ / r²; E = kq₁ / r².',
      'A negative force value indicates attraction; a positive value indicates repulsion.',
    ],
    'rc_charge': [
      'Time constant τ = RC.',
      'For an initially uncharged capacitor, Vc(t) = Vin × (1 − exp(−t/τ)).',
    ],
    'ac_power_basic': [
      'Apparent power S = Vrms × Irms.',
      'Real power P = S × power factor; reactive power magnitude Q = √(S² − P²).',
    ],
    'thevenin_norton': [
      'Vth = open-circuit voltage. Norton current In = Vth / Rth.',
      'The Thevenin and Norton resistances are equal.',
    ],
    'percent_error': [
      'Absolute error = |measured − reference|.',
      'Relative error = absolute error / |reference|. Multiply by 100 for percentage error.',
    ],
    'scientific_notation': [
      'Write x = a × 10ⁿ, with 1 ≤ |a| < 10 for non-zero x.',
    ],
    'sig_figs': [
      'Count significant digits from the first non-zero digit and round at the requested precision. Trailing zeroes convey precision.',
    ],
    'constants_library': [
      'g = 9.81 m/s² is an approximate near-Earth gravitational acceleration. Local gravity varies.',
      'Electromagnetic constants are displayed at the precision listed.',
    ],
    'beam_bending_stress': [
      'Bending stress σ = Mc / I. Divide pascals by 10⁶ to obtain MPa.',
    ],
    'reynolds_number': [
      'Re = density × speed × diameter / dynamic viscosity.',
      'Circular pipe flow: below 2300 is laminar; 2300–4000 is transitional; above 4000 is turbulent.',
    ],
    'ideal_gas': ['PV = nRT, so P = nRT / V, with R = 8.314462618 J/(mol·K).'],
    'gpa_tracker': [
      'Total grade points = previous CGPA × previous credits + current GPA × current credits.',
      'Updated CGPA = total grade points / total credits.',
    ],
    'transformer_turns_ratio': [
      'Turns ratio = Ns / Np. Vs = Vp × turns ratio.',
      'Conservation of power for an ideal transformer gives Is = Ip / turns ratio.',
    ],
  };
}
