import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:pluto_grid_plus/src/ui/ui.dart';

import '../../helper/column_helper.dart';
import '../../helper/row_helper.dart';

void main() {
  late PlutoGridStateManager stateManager;

  Widget buildGrid({
    required List<PlutoColumn> columns,
    required List<PlutoRow> rows,
  }) {
    return MaterialApp(
      home: Material(
        child: PlutoGrid(
          columns: columns,
          rows: rows,
          onLoaded: (e) {
            stateManager = e.stateManager;
            stateManager.setShowColumnFilter(true);
          },
        ),
      ),
    );
  }

  Finder findFilterTextField() {
    return find.descendant(
      of: find.byType(PlutoColumnFilter),
      matching: find.byType(TextField),
    );
  }

  Future<void> tapAndEnterTextColumnFilter(
    WidgetTester tester,
    String? enterText,
  ) async {
    final textField = findFilterTextField();

    // Focus
    await tester.tap(textField);
    await tester.pump();

    // Enter text
    if (enterText != null) {
      await tester.enterText(textField, enterText);
      await tester.testTextInput.receiveAction(TextInputAction.done);
    }
  }

  group('Filter State Management Regression Tests', () {
    testWidgets(
      'Should successfully apply a second filter after the first one is applied',
      (tester) async {
        // Regression test for issue where second filter change was ignored.
        final columns = ColumnHelper.textColumn('column');
        final rows = RowHelper.count(20, columns);

        await tester.pumpWidget(buildGrid(columns: columns, rows: rows));
        await tester.pump();

        // 1. Apply first filter 'value 1'
        await tapAndEnterTextColumnFilter(tester, 'value 1');
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        expect(
          stateManager.refRows.length,
          11,
          reason: "First filter 'value 1' failed",
        );
        expect(find.text('column0 value 1'), findsOneWidget);

        // 2. Change filter to 'value 2'
        await tapAndEnterTextColumnFilter(tester, 'value 2');
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        expect(
          stateManager.refRows.length,
          1,
          reason: "Second filter 'value 2' failed to apply",
        );
        expect(find.text('column0 value 2'), findsOneWidget);
      },
    );

    testWidgets(
      'Filter TextField should remain enabled after Type -> Clear -> Type sequence',
      (tester) async {
        // Regression test for issue where TextField became disabled after clearing text.
        final columns = ColumnHelper.textColumn('column');
        final rows = RowHelper.count(20, columns);

        await tester.pumpWidget(buildGrid(columns: columns, rows: rows));
        await tester.pump();

        final textField = findFilterTextField();

        // 1. Type "a"
        await tester.tap(textField);
        await tester.pump();
        await tester.enterText(textField, 'a');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        expect(stateManager.filterRowsByField('column0').length, 1);

        // 2. Clear text
        await tester.tap(textField);
        await tester.enterText(textField, '');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        // 3. Type "b"
        await tester.tap(textField);
        await tester.enterText(textField, 'b');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        expect(
          stateManager.filterRowsByField('column0').length,
          1,
          reason:
              "Should have 1 filter row, preventing duplicate composite filters",
        );

        // Verify TextField is enabled
        final TextField widget = tester.widget(textField);
        expect(widget.enabled, true, reason: "TextField should remain enabled");
      },
    );
  });
}
