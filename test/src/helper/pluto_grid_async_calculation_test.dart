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
