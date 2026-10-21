import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  testWidgets('yields between frames and shares work between calculations', (
    WidgetTester tester,
  ) async {
    const int rowCount = PlutoGridSettings.calculationMaxStepsPerFrame * 2;
    int processed = 0;
    int? processedWhenSecondStarted;
    bool complete = false;
    PlutoGridAsyncCalculation(
      steps: () sync* {
        for (int index = 0; index < rowCount; index += 1) {
          processed += 1;
          yield null;
        }
      },
      onCompleted: () => complete = true,
    );
    PlutoGridAsyncCalculation(
      steps: () sync* {
        processedWhenSecondStarted = processed;
        yield null;
      },
      onCompleted: () {},
    );

    expect(processed, 0);
    await tester.pump();
    expect(processed, lessThan(rowCount));
    expect(complete, isFalse);
    await tester.pumpAndSettle();
    expect(processed, rowCount);
    expect(complete, isTrue);
    expect(
      processedWhenSecondStarted,
      lessThanOrEqualTo(PlutoGridSettings.calculationBatchSize),
    );
  });

  testWidgets('long calculations yield every frame and keep their results', (
    WidgetTester tester,
  ) async {
    const int rowCount = PlutoGridSettings.calculationMaxStepsPerFrame * 3;
    final List<List<int>> columns = <List<int>>[
      for (int column = 0; column < 3; column += 1)
        <int>[for (int row = 0; row < rowCount; row += 1) row * (column + 1)],
    ];
    final List<int> expected = <int>[
      for (final List<int> values in columns)
        values.reduce((int a, int b) => a + b),
    ];
    final List<int?> published = List<int?>.filled(columns.length, null);
    int processed = 0;
    for (int column = 0; column < columns.length; column += 1) {
      int? result;
      PlutoGridAsyncCalculation(
        steps: () sync* {
          int sum = 0;
          for (final int value in columns[column]) {
            sum += value;
            processed += 1;
            yield null;
          }
          result = sum;
        },
        onCompleted: () => published[column] = result,
      );
    }

    int frames = 0;
    while (published.contains(null)) {
      final int before = processed;
      await tester.pump();
      frames += 1;
      expect(
        processed - before,
        inInclusiveRange(1, PlutoGridSettings.calculationMaxStepsPerFrame),
      );
    }
    expect(frames, greaterThanOrEqualTo(columns.length * 3));
    expect(processed, rowCount * columns.length);
    expect(published, expected);
    await tester.pumpAndSettle();
    expect(processed, rowCount * columns.length);
  });

  testWidgets('expensive steps are not batched past the frame budget', (
    WidgetTester tester,
  ) async {
    // Each step is slower than 1/8 of the budget, so the budget is checked
    // after every step even when earlier steps were cheap.
    final Duration stepCost = PlutoGridSettings.calculationFrameBudget * 0.15;
    final int perFrame =
        PlutoGridSettings.calculationFrameBudget.inMicroseconds ~/
            stepCost.inMicroseconds +
        1;
    const int cheapSteps = PlutoGridSettings.calculationBatchSize * 4;
    int processed = 0;
    bool complete = false;
    PlutoGridAsyncCalculation(
      steps: () sync* {
        for (int index = 0; index < cheapSteps; index += 1) {
          processed += 1;
          yield null;
        }
        for (
          int index = 0;
          index < PlutoGridSettings.calculationBatchSize + perFrame * 3;
          index += 1
        ) {
          final Stopwatch busy = Stopwatch()..start();
          while (busy.elapsed < stepCost) {}
          processed += 1;
          yield null;
        }
      },
      onCompleted: () => complete = true,
    );

    // The first frame meets the expensive steps with a run sized for cheap
    // ones (at most one batch); every later frame stays within the budget.
    await tester.pump();
    expect(complete, isFalse);
    while (!complete) {
      final int before = processed;
      await tester.pump();
      expect(processed - before, lessThanOrEqualTo(perFrame));
    }
  });

  testWidgets('cancelled and superseded calculations do no more work', (
    WidgetTester tester,
  ) async {
    int processed = 0;
    bool complete = false;
    final PlutoGridAsyncCalculation calculation = PlutoGridAsyncCalculation(
      steps: () sync* {
        for (
          int index = 0;
          index < PlutoGridSettings.calculationMaxStepsPerFrame * 2;
          index += 1
        ) {
          processed += 1;
          yield null;
        }
      },
      onCompleted: () => complete = true,
    );
    await tester.pump();
    final int beforeCancel = processed;
    calculation.cancel();
    await tester.pumpAndSettle();
    expect(processed, beforeCancel);
    expect(complete, isFalse);

    PlutoGridAsyncCalculation(
      steps: () sync* {
        processed += 1;
        yield null;
      },
      onCompleted: () => complete = true,
    ).cancel();
    await tester.pumpAndSettle();
    expect(processed, beforeCancel);
    expect(complete, isFalse);
  });

  testWidgets('restarts a changed live list with a fresh accumulator', (
    WidgetTester tester,
  ) async {
    final List<int> rows = List<int>.filled(
      PlutoGridSettings.calculationMaxStepsPerFrame * 2,
      1,
      growable: true,
    );
    int attempts = 0;
    int? result;
    int? published;
    PlutoGridAsyncCalculation(
      steps: () sync* {
        attempts += 1;
        int sum = 0;
        for (final int row in rows) {
          sum += row;
          yield null;
        }
        result = sum;
      },
      onCompleted: () => published = result,
    );
    await tester.pump();
    expect(published, isNull);
    rows.removeLast();
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(published, rows.length);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports calculation errors and removes failed work', (
    WidgetTester tester,
  ) async {
    bool complete = false;
    PlutoGridAsyncCalculation(
      steps: () sync* {
        yield null;
        throw StateError('Invalid value');
      },
      onCompleted: () => complete = true,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isStateError);
    expect(complete, isFalse);
  });
}
