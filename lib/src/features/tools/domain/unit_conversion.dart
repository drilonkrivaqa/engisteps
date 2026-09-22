class EngineeringUnit {
  const EngineeringUnit(
    this.quantity,
    this.symbol,
    this.factor, [
    this.offset = 0,
  ]);
  final String quantity;
  final String symbol;
  final double factor;
  final double offset;
}

class UnitConversion {
  static const units = [
    EngineeringUnit('Length', 'm', 1),
    EngineeringUnit('Length', 'km', 1000),
    EngineeringUnit('Length', 'cm', 0.01),
    EngineeringUnit('Length', 'mm', 0.001),
    EngineeringUnit('Length', 'in', 0.0254),
    EngineeringUnit('Length', 'ft', 0.3048),
    EngineeringUnit('Mass', 'kg', 1),
    EngineeringUnit('Mass', 'g', 0.001),
    EngineeringUnit('Mass', 'lb', 0.45359237),
    EngineeringUnit('Temperature', 'K', 1),
    EngineeringUnit('Temperature', '°C', 1, 273.15),
    EngineeringUnit('Temperature', '°F', 5 / 9, 459.67 * 5 / 9),
    EngineeringUnit('Pressure', 'Pa', 1),
    EngineeringUnit('Pressure', 'kPa', 1000),
    EngineeringUnit('Pressure', 'MPa', 1e6),
    EngineeringUnit('Pressure', 'bar', 1e5),
    EngineeringUnit('Pressure', 'psi', 6894.757293168),
    EngineeringUnit('Speed', 'm/s', 1),
    EngineeringUnit('Speed', 'km/h', 1 / 3.6),
    EngineeringUnit('Speed', 'mph', 0.44704),
    EngineeringUnit('Energy', 'J', 1),
    EngineeringUnit('Energy', 'kJ', 1000),
    EngineeringUnit('Energy', 'Wh', 3600),
    EngineeringUnit('Energy', 'kWh', 3.6e6),
    EngineeringUnit('Area', 'm²', 1),
    EngineeringUnit('Area', 'cm²', 1e-4),
    EngineeringUnit('Area', 'ft²', 0.09290304),
    EngineeringUnit('Volume', 'm³', 1),
    EngineeringUnit('Volume', 'L', 1e-3),
    EngineeringUnit('Volume', 'mL', 1e-6),
    EngineeringUnit('Time', 's', 1),
    EngineeringUnit('Time', 'min', 60),
    EngineeringUnit('Time', 'h', 3600),
    EngineeringUnit('Power', 'W', 1),
    EngineeringUnit('Power', 'kW', 1000),
    EngineeringUnit('Power', 'MW', 1e6),
  ];

  static double convert(double value, int from, int to) {
    if (!value.isFinite ||
        from < 0 ||
        to < 0 ||
        from >= units.length ||
        to >= units.length) {
      throw const FormatException('Choose valid units and a finite value.');
    }
    final source = units[from];
    final target = units[to];
    if (source.quantity != target.quantity) {
      throw const FormatException('Choose units of the same quantity.');
    }
    final base = value * source.factor + source.offset;
    if (source.quantity == 'Temperature' && base < -1e-10) {
      throw const FormatException('Temperature cannot be below absolute zero.');
    }
    final result = (base - target.offset) / target.factor;
    if (!result.isFinite) {
      throw const FormatException('Value exceeds the supported range.');
    }
    return result;
  }
}
