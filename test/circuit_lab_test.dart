import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:engisteps/src/app/engisteps_app.dart';
import 'package:engisteps/src/core/navigation/app_router.dart';
import 'package:engisteps/src/core/theme/app_theme.dart';
import 'package:engisteps/src/features/learn/domain/circuit_course.dart';
import 'package:engisteps/src/features/learn/domain/circuit_experiment.dart';
import 'package:engisteps/src/features/learn/presentation/circuit_lab_screen.dart';
import 'package:engisteps/src/features/learn/presentation/student_home_screen.dart';
import 'package:engisteps/src/features/home/presentation/work_screen.dart';
import 'package:engisteps/src/features/history/data/history_repository.dart';
import 'package:engisteps/src/features/tools/domain/tool_execution.dart';
import 'package:engisteps/src/features/tools/domain/tool_registry.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Circuit lab respects voltage, current and power relationships', () {
    final series = CircuitExperiment(kind: CircuitKind.series);
    expect(series.resistance, 3000);
    expect(series.current, closeTo(0.004, 1e-12));
    expect(series.output, 8);
    expect(series.power, closeTo(0.048, 1e-12));
    final parallel = series.copyWith(kind: CircuitKind.parallel);
    expect(parallel.resistance, closeTo(2000 / 3, 1e-9));
    expect(parallel.output, 12);
    expect(parallel.current, closeTo(0.018, 1e-12));
    expect(parallel.power, closeTo(0.216, 1e-12));
    expect(series.copyWith(r2: 4000).output, greaterThan(series.output));
    expect(parallel.copyWith(r2: 4000).output, parallel.output);
    expect(series.copyWith(r2: 4000).current, lessThan(series.current));
    expect(() => CircuitExperiment(r1: 0), throwsArgumentError);
    expect(() => CircuitExperiment(voltage: double.nan), throwsArgumentError);
    expect(() => CircuitExperiment(r2: 10001), throwsArgumentError);
  });
  test(
    'Saved lab configurations reproduce their results in existing calculators',
    () {
      for (final kind in CircuitKind.values) {
        final config = CircuitExperiment(
          kind: kind,
          voltage: 9,
          r1: 2200,
          r2: 3300,
        );
        final record = config.snapshot();
        final values = record.inputs.map(
          (key, value) => MapEntry(key, double.parse(value)),
        )..addAll(record.options);
        final result = ToolExecution.run(
          ToolRegistry.byId(record.toolId),
          values,
        );
        expect(result.error, isNull);
        expect(result.mainResult, record.output);
        if (kind != CircuitKind.divider) {
          expect(record.options['mode'], kind == CircuitKind.parallel ? 1 : 0);
        }
      }
    },
  );
  Future<void> tap(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Exact values validate, comparisons stay fixed, and saving persists',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: const CircuitLabScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Compare two setups');
      await tap(tester, 'Use current setup as reference');
      await tester.drag(find.byType(ListView), const Offset(0, 2200));
      await tester.pumpAndSettle();
      await tap(tester, '2000 Ω');
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a value in the allowed range.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '4k');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(container.read(circuitExperimentProvider).r2, 4000);
      expect(container.read(circuitBaselineProvider)!.r2, 2000);
      expect(container.read(circuitExperimentProvider).output, 9.6);
      expect(tester.takeException(), isNull);
      await tap(tester, 'Save calculation');
      expect(container.read(historyProvider), hasLength(1));
      expect(container.read(historyProvider).single.inputs['R2'], '4000.0');
      final restored = HistoryController();
      addTearDown(restored.dispose);
      await restored.load();
      expect(restored.state.single.output, 'Vout=9.6 V');
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Navigation has three destinations and notes survive tab switches',
    (tester) async {
      router.go('/learn');
      await tester.pumpWidget(const ProviderScope(child: EngiStepsApp()));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
        hasLength(3),
      );
      await tester.tap(find.text('My work').last);
      await tester.pumpAndSettle();
      await tap(tester, 'My notes');
      await tester.enterText(find.byType(TextField), 'My circuit explanation');
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('My work').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'My circuit explanation',
      );
      router.go('/notes');
      await tester.pumpAndSettle();
      expect(find.text('Your notebook'), findsOneWidget);
      router.go('/learn');
      await tester.pumpAndSettle();
    },
  );
  for (final width in [360.0, 1200.0]) {
    for (final dark in [false, true]) {
      testWidgets('Organized screens fit $width, enlarged text, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 950);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        for (final screen in [
          const WorkScreen(),
          const CourseScreen(),
          const ProgressScreen(),
          const CircuitLabScreen(),
        ]) {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 950),
                    textScaler: const TextScaler.linear(1.5),
                  ),
                  child: screen,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (screen is CircuitLabScreen) {
            await tap(tester, 'Why does it change?');
            await tap(tester, 'Compare two setups');
            await tap(tester, 'Use current setup as reference');
          }
          await tester.drag(find.byType(ListView).first, const Offset(0, -700));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: screen.runtimeType.toString(),
          );
        }
      });
    }
  }
}
