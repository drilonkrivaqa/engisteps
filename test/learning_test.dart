import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:engisteps/src/core/theme/app_theme.dart';
import 'package:engisteps/src/core/navigation/app_router.dart';
import 'package:engisteps/src/app/engisteps_app.dart';
import 'package:engisteps/src/features/learn/data/learning_repository.dart';
import 'package:engisteps/src/features/learn/domain/circuit_course.dart';
import 'package:engisteps/src/features/learn/presentation/learning_screens.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('All authored answers agree with independently calculated values', () {
    const expected = [
      300,
      550,
      3200,
      570,
      3000,
      50,
      110,
      75,
      500,
      200,
      8,
      5,
      3,
      6,
      2,
    ];
    expect(circuitProblems.map((p) => p.id).toSet().length, 15);
    for (var i = 0; i < circuitProblems.length; i++) {
      final p = circuitProblems[i];
      expect(p.answer, closeTo(expected[i], 0.000001), reason: p.id);
      expect(p.accepts(expected[i].toDouble()), isTrue);
      expect(p.accepts(expected[i] * 1.01), isFalse);
      expect(p.accepts(double.nan), isFalse);
      expect(p.accepts(double.infinity), isFalse);
    }
    expect(findProblem('series-2')!.feedback(3.2), contains('kΩ'));
    expect(findProblem('divider-2')!.feedback(6), contains('R1'));
  });
  test(
    'Progress survives recreation and concurrent writes do not lose answers',
    () async {
      final container = ProviderContainer();
      await container.read(learningProvider.future);
      final controller = container.read(learningProvider.notifier);
      await Future.wait([
        controller.save(
          'series-example',
          const LearningAttempt(completed: true),
        ),
        controller.save(
          'series-1',
          const LearningAttempt(
            methodDone: true,
            helped: true,
            hintShown: true,
          ),
        ),
      ]);
      container.dispose();
      final restored = ProviderContainer();
      addTearDown(restored.dispose);
      final progress = await restored.read(learningProvider.future);
      expect(progress.attempt('series-example').completed, isTrue);
      expect(progress.attempt('series-1').methodDone, isTrue);
      expect(progress.attempt('series-1').hintShown, isTrue);
      expect(progress.independentCount, 0);
      expect(progress.next!.id, 'series-1');
    },
  );
  test(
    'Malformed records are skipped and unsupported IDs do not affect progress',
    () async {
      SharedPreferences.setMockInitialValues({
        LearningController.storageKey: jsonEncode({
          'topic': 'missing',
          'attempts': {
            'series-1': {'completed': true, 'independent': true},
            'series-2': 'broken',
            'unknown': {'completed': true},
          },
        }),
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final p = await container.read(learningProvider.future);
      expect(p.topic, 'series');
      expect(p.independentCount, 1);
      expect(p.attempts.length, 1);
    },
  );
  test('Review queue excludes guided examples and independent answers', () {
    final p = LearningProgress(
      attempts: {
        'series-example': const LearningAttempt(completed: true, helped: true),
        'series-1': const LearningAttempt(completed: true, independent: true),
        'series-2': const LearningAttempt(completed: true, helped: true),
      },
    );
    expect(p.review.map((p) => p.id), ['series-2']);
    expect(p.independentCount, 1);
  });

  Future<ProviderContainer> showProblem(WidgetTester tester, String id) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: ProblemScreen(problemId: id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Wrong method and unit feedback prevent an independent score', (
    tester,
  ) async {
    final container = await showProblem(tester, 'series-2');
    await tapText(tester, 'Combine branches: (R1 × R2) / (R1 + R2)');
    expect(
      container.read(learningProvider).requireValue.attempt('series-2').helped,
      isTrue,
    );
    await tapText(tester, 'Add the resistances: R1 + R2');
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '3.2');
    await tapText(tester, 'Check answer');
    expect(find.textContaining('Your value looks like kΩ'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '3200');
    await tapText(tester, 'Check answer');
    final result = container
        .read(learningProvider)
        .requireValue
        .attempt('series-2');
    expect(result.completed, isTrue);
    expect(result.independent, isFalse);
    expect(find.text('You worked through it.'), findsOneWidget);
  });
  testWidgets('Correct practice earns credit; retry and reveal do not', (
    tester,
  ) async {
    final container = await showProblem(tester, 'parallel-2');
    await tapText(tester, 'Combine branches: (R1 × R2) / (R1 + R2)');
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '100*300/400');
    await tapText(tester, 'Check answer');
    expect(container.read(learningProvider).requireValue.independentCount, 1);
    await tapText(tester, 'Try again from the start');
    expect(container.read(learningProvider).requireValue.independentCount, 0);
    await tapText(tester, 'Show worked solution');
    expect(container.read(learningProvider).requireValue.independentCount, 0);
    expect(
      container.read(learningProvider).requireValue.review.single.id,
      'parallel-2',
    );
  });
  for (final width in [360.0, 1200.0]) {
    for (final dark in [false, true]) {
      testWidgets('Learning screens fit $width with large text, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 950);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        for (final screen in [
          const LearnScreen(),
          const TopicScreen(topicId: 'divider'),
          const ProblemScreen(problemId: 'divider-example'),
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
          await tester.drag(find.byType(ListView).first, const Offset(0, -800));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
  testWidgets(
    'New student can start, complete example, and continue to practice',
    (tester) async {
      router.go('/learn');
      await tester.pumpWidget(const ProviderScope(child: EngiStepsApp()));
      await tester.pumpAndSettle();
      await tapText(tester, 'Solve my first circuit');
      await tapText(tester, 'Add the resistances: R1 + R2');
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '300');
      await tapText(tester, 'Check answer');
      await tapText(tester, 'Try the next problem');
      expect(find.text('Combine two resistors'), findsOneWidget);
      expect(find.textContaining('STEP 1 OF 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.go('/learn');
      await tester.pumpAndSettle();
    },
  );
  testWidgets('A direct activity link has a route back to learning', (
    tester,
  ) async {
    router.go('/learn/problem/divider-example');
    await tester.pumpWidget(const ProviderScope(child: EngiStepsApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Know where to start.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
