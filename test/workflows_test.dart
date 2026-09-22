import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:engisteps/src/core/theme/app_theme.dart';
import 'package:engisteps/src/features/tools/presentation/tools_screens.dart';
import 'package:engisteps/src/features/history/data/history_repository.dart';
import 'package:engisteps/src/features/notes/presentation/notes_screen.dart';
import 'package:engisteps/src/features/notes/data/notes_repository.dart';
import 'package:engisteps/src/app/engisteps_app.dart';
import 'package:engisteps/src/core/navigation/app_router.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> show(
    WidgetTester tester,
    Widget screen, {
    ProviderContainer? container,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container ?? ProviderContainer(),
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Search clear resets both text and results', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await show(
      tester,
      const Scaffold(body: ToolsHomeScreen()),
      container: container,
    );
    await tester.enterText(find.byType(TextField), 'no matching tool');
    await tester.pumpAndSettle();
    expect(find.text('0 tools'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('26 tools'), findsOneWidget);
  });
  testWidgets('Editing invalidates output and prevents stale saves', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await show(
      tester,
      const ToolDetailScreen(toolId: 'quadratic_solver'),
      container: container,
    );
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save result'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save result'));
    await tester.pumpAndSettle();
    expect(container.read(historyProvider), hasLength(1));
    final firstInput = find.byType(TextField).first;
    await tester.ensureVisible(firstInput);
    await tester.enterText(firstInput, '2');
    await tester.pumpAndSettle();
    expect(find.text('Save result'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Inputs changed. Calculate again to update your result.'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Inputs changed. Calculate again to update your result.'),
      findsOneWidget,
    );
  });
  testWidgets('Restored units and choices reproduce the saved result', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final restore = HistoryEntry(
      id: 'test',
      toolId: 'ohms_resistors',
      timestamp: DateTime(2026),
      inputs: {'V': '12', 'R1': '1', 'R2': '1'},
      units: {'R1': 'kΩ', 'R2': 'kΩ'},
      options: {'mode': 1},
      output: 'Req=500 Ω',
    );
    await show(
      tester,
      ToolDetailScreen(toolId: 'ohms_resistors', restore: restore),
      container: container,
    );
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Req=500 Ω'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Req=500 Ω'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Invalid input produces an error, not a save action', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await show(
      tester,
      const ToolDetailScreen(toolId: 'work_energy_power'),
      container: container,
    );
    await tester.enterText(find.byType(TextField).last, '0');
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Check your inputs'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Save result'), findsNothing);
    expect(find.text('t must be greater than zero.'), findsOneWidget);
  });
  testWidgets('Unsaved notes survive rebuilds and provider updates', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await show(
      tester,
      const Scaffold(body: NotesScreen()),
      container: container,
    );
    await tester.enterText(find.byType(TextField), 'My unsaved derivation');
    await container.read(notesProvider.notifier).save('Background update');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'My unsaved derivation',
    );
    await tester.tap(find.text('Save notes'));
    await tester.pumpAndSettle();
    expect(container.read(notesProvider), 'My unsaved derivation');
  });
  testWidgets('Converter quantity switch and example reset remain consistent', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await show(
      tester,
      const ToolDetailScreen(toolId: 'unit_converter'),
      container: container,
    );
    await tester.ensureVisible(find.text('Length'));
    await tester.tap(find.text('Length'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Temperature').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '273.15');
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('0 °C'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('0 °C'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset example'));
    await tester.pumpAndSettle();
    expect(find.text('Length'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Legacy history can be copied without missing-mode exceptions', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final restore = HistoryEntry(
      id: 'legacy',
      toolId: 'ohms_resistors',
      timestamp: DateTime(2026),
      inputs: {'V': '12', 'R1': '1', 'R2': '1'},
      output: 'Old result',
      version: 1,
    );
    await show(
      tester,
      ToolDetailScreen(toolId: 'ohms_resistors', restore: restore),
      container: container,
    );
    await tester.scrollUntilVisible(
      find.text('Copy working'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy working'));
    await tester.pumpAndSettle();
    expect(copied, contains('Not recorded'));
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 1200.0]) {
    testWidgets('Workbench fits $width px with enlarged text', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: const Scaffold(body: ToolsHomeScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Navigation reaches settings and dark mode changes the app', (
    tester,
  ) async {
    router.go('/tools');
    await tester.pumpWidget(const ProviderScope(child: EngiStepsApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Dark mode'), findsOneWidget);
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    final material = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(material.themeMode, ThemeMode.dark);
    router.go('/tools');
    await tester.pumpAndSettle();
  });
}
