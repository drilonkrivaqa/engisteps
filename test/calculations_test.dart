import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:engisteps/src/core/utils/smart_number_parser.dart';
import 'package:engisteps/src/features/tools/domain/tool_execution.dart';
import 'package:engisteps/src/features/tools/domain/tool_registry.dart';
import 'package:engisteps/src/features/tools/domain/unit_conversion.dart';

void main() {
  group('Expression input', () {
    final cases = <String, double>{
      '2.2k': 2200,
      '470u': 470e-6,
      '470µ': 470e-6,
      '470μ': 470e-6,
      '1/3': 1 / 3,
      '3*pi': 3 * math.pi,
      '2pi': 2 * math.pi,
      '(12-2.5)*4': 38,
      '-2^2': -4,
      '(-2)^2': 4,
      '2^-3': 0.125,
      '2^3^2': 512,
      '2×3': 6,
      '6÷2': 3,
      '2,5': 2.5,
      '1e-6': 1e-6,
    };
    for (final entry in cases.entries) {
      test(
        entry.key,
        () => expect(
          SmartNumberParser.parse(entry.key),
          closeTo(entry.value, 1e-10),
        ),
      );
    }
    for (final text in [
      '',
      'NaN',
      'Infinity',
      '1/0',
      '1e999',
      '2+',
      '(2',
      'abc',
    ]) {
      test('Reject $text', () => expect(SmartNumberParser.parse(text), isNull));
    }
  });

  group('Calculator regression checks', () {
    for (final tool in ToolRegistry.tools) {
      test('${tool.id} has a valid default calculation', () {
        final inputs = <String, double>{
          for (final field in tool.inputs)
            field.key: field.options.isNotEmpty
                ? field.options.first.value
                : SmartNumberParser.parse(field.defaultValue ?? '')!,
        };
        final result = ToolExecution.run(tool, inputs);
        expect(result.error, isNull, reason: result.mainResult);
        expect(result.mainResult, isNotEmpty);
        expect(
          '${result.mainResult}${result.secondaryResults}',
          isNot(contains('NaN')),
        );
        if (inputs.isNotEmpty) {
          inputs[inputs.keys.first] = double.infinity;
          expect(ToolExecution.run(tool, inputs).error, isNotNull);
        }
      });
    }
    test('Zero significant figures value is valid', () {
      expect(
        ToolExecution.run(ToolRegistry.byId('sig_figs'), {
          'x': 0,
          'n': 3,
        }).mainResult,
        'Rounded=0',
      );
    });
    test('Significant figures retains requested trailing zeroes', () {
      expect(
        ToolExecution.run(ToolRegistry.byId('sig_figs'), {
          'x': 1.2,
          'n': 4,
        }).mainResult,
        'Rounded=1.200',
      );
    });
    test('Percentage error is nonnegative for a negative reference', () {
      expect(
        ToolExecution.run(ToolRegistry.byId('percent_error'), {
          'measured': -9,
          'true': -10,
        }).mainResult,
        '% error=10%',
      );
    });
    final invalid = <String, Map<String, double>>{
      'complex_ops': {'a': 1, 'b': 1, 'c': 0, 'd': 0},
      'work_energy_power': {'F': 10, 'd': 5, 't': 0},
      'ac_power_basic': {'V': 230, 'I': 2, 'pf': 2},
      'sig_figs': {'x': 10, 'n': 1.5},
      'percent_error': {'measured': 10, 'true': 0},
      'ideal_gas': {'n': 1, 'T': -20, 'V': 1},
      'ohms_resistors': {'R1': 0, 'R2': 100, 'V': 12, 'mode': 1},
    };
    for (final entry in invalid.entries) {
      test(
        '${entry.key} rejects invalid domain',
        () => expect(
          ToolExecution.run(ToolRegistry.byId(entry.key), entry.value).error,
          isNotNull,
        ),
      );
    }
    test('Quadratic solver preserves a small root', () {
      final result = ToolExecution.run(ToolRegistry.byId('quadratic_solver'), {
        'a': 1,
        'b': 1e8,
        'c': 1,
      });
      expect(result.mainResult, contains('-1.0000e-8'));
    });
    test('Settings control display precision and notation', () {
      final tool = ToolRegistry.byId('numeric_derivative');
      final inputs = {'a': 1.0, 'b': 0.0, 'c': 0.0, 'x': 1.234567};
      expect(
        ToolExecution.run(tool, inputs, precision: 2).mainResult,
        "f'(x)=2.47",
      );
      expect(
        ToolExecution.run(
          tool,
          inputs,
          precision: 2,
          scientific: true,
        ).mainResult,
        "f'(x)=2.47e+0",
      );
    });
  });

  group('Unit conversion', () {
    int index(String symbol) =>
        UnitConversion.units.indexWhere((u) => u.symbol == symbol);
    test('Temperature offsets work both ways', () {
      expect(
        UnitConversion.convert(0, index('°C'), index('°F')),
        closeTo(32, 1e-9),
      );
      expect(
        UnitConversion.convert(212, index('°F'), index('°C')),
        closeTo(100, 1e-9),
      );
      expect(
        UnitConversion.convert(0, index('K'), index('°C')),
        closeTo(-273.15, 1e-9),
      );
    });
    test(
      'Metric and imperial length',
      () => expect(UnitConversion.convert(1, index('ft'), index('m')), 0.3048),
    );
    test(
      'Energy conversion',
      () => expect(UnitConversion.convert(1, index('kWh'), index('J')), 3.6e6),
    );
    test(
      'Incompatible dimensions rejected',
      () => expect(
        () => UnitConversion.convert(1, index('m'), index('kg')),
        throwsFormatException,
      ),
    );
    test(
      'Below absolute zero rejected',
      () => expect(
        () => UnitConversion.convert(-274, index('°C'), index('K')),
        throwsFormatException,
      ),
    );
    test('Every unit round trips', () {
      for (var i = 0; i < UnitConversion.units.length; i++) {
        expect(UnitConversion.convert(300, i, i), closeTo(300, 1e-8));
      }
    });
  });
}
