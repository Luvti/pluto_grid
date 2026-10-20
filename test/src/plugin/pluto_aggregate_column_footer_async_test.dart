import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  PlutoRow<dynamic> row(Object? value) => PlutoRow<dynamic>(
    cells: <String, PlutoCell>{'value': PlutoCell(value: value)},
  );

  PlutoGridStateManager manager(
    List<PlutoRow<dynamic>> rows, {
    PlutoColumnType? columnType,
  }) {
    final FocusNode focus = FocusNode();
    final PlutoGridStateManager state = PlutoGridStateManager(
      columns: <PlutoColumn>[
        PlutoColumn(
          title: 'value',
          field: 'value',
          type: columnType ?? PlutoColumnType.number(),
        ),
      ],
      rows: rows,
      gridFocusNode: focus,
      scroll: PlutoGridScrollController(),
    );
    addTearDown(() {
      state.dispose();
      focus.dispose();
    });
    return state;
  }

  Widget footer(
    PlutoGridStateManager state, {
    PlutoAggregateColumnType type = PlutoAggregateColumnType.count,
    PlutoAggregateFilter? filter,
    String format = '#,###',
  }) => MaterialApp(
    home: PlutoAggregateColumnFooter(
      rendererContext: PlutoColumnFooterRendererContext(
        stateManager: state,
        column: state.columns.first,
      ),
      type: type,
      filter: filter,
      format: format,
    ),
  );

  testWidgets('incremental totals match synchronous helpers at edge cases', (
    WidgetTester tester,
  ) async {
    const String preciseFormat = '#,###.00000000';
    final List<(PlutoColumnType, List<Object?>, PlutoAggregateFilter?)> cases =
        <(PlutoColumnType, List<Object?>, PlutoAggregateFilter?)>[
          (PlutoColumnType.number(format: '#,###.00'), <Object?>[], null),
          (
            PlutoColumnType.number(format: '#,###.00'),
            <Object?>[1.125, -3.255, 1.125, 9],
            null,
          ),
          (
            PlutoColumnType.number(),
            <Object?>[null, 2, 4],
            (PlutoCell cell) => cell.currentValue != null,
          ),
          (
            PlutoColumnType.number(),
            <Object?>[2, 4],
            (PlutoCell cell) => false,
          ),
          (PlutoColumnType.double(), <Object?>[1.25, null, 3.75], null),
          (PlutoColumnType.text(), <Object?>['a', 'b', 'a'], null),
        ];
    for (final (
          PlutoColumnType columnType,
          List<Object?> values,
          PlutoAggregateFilter? filter,
        )
        in cases) {
      final PlutoGridStateManager state = manager(
        values.map(row).toList(),
        columnType: columnType,
      );
      for (final PlutoAggregateColumnType type
          in PlutoAggregateColumnType.values) {
        final num? Function({
          required Iterable<PlutoRow<dynamic>> rows,
          required PlutoColumn column,
          PlutoAggregateFilter? filter,
        })
        aggregate = switch (type) {
          PlutoAggregateColumnType.sum => PlutoAggregateHelper.sum,
          PlutoAggregateColumnType.average => PlutoAggregateHelper.average,
          PlutoAggregateColumnType.min => PlutoAggregateHelper.min,
          PlutoAggregateColumnType.max => PlutoAggregateHelper.max,
          PlutoAggregateColumnType.count => PlutoAggregateHelper.count,
          PlutoAggregateColumnType.uniqueCount =>
            PlutoAggregateHelper.uniqueCount,
        };
        final num? expected = aggregate(
          rows: state.refRows,
          column: state.columns.first,
          filter: filter,
        );
        await tester.pumpWidget(
          footer(state, type: type, filter: filter, format: preciseFormat),
        );
        await tester.pumpAndSettle();
        final Text text = tester.widget<Text>(
          find.descendant(
            of: find.byType(PlutoAggregateColumnFooter),
            matching: find.byType(Text),
          ),
        );
        expect(
          text.textSpan!.toPlainText(),
          expected == null ? '' : NumberFormat(preciseFormat).format(expected),
          reason: '$columnType $values $type',
        );
      }
    }
  });

  testWidgets('unrelated rebuilds and hover events do not recalculate totals', (
    WidgetTester tester,
  ) async {
    final PlutoGridStateManager state = manager(<PlutoRow<dynamic>>[
      row(1),
      row(2),
    ]);
    int visited = 0;
    bool filter(PlutoCell cell) {
      visited += 1;
      return true;
    }

    await tester.pumpWidget(footer(state, filter: filter));
    await tester.pumpAndSettle();
    expect(visited, 2);
    state.setHoveredRowIdx(0);
    await tester.pumpWidget(footer(state, filter: filter));
    await tester.pumpAndSettle();
    expect(visited, 2);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('all aggregate types finish with the expected result', (
    WidgetTester tester,
  ) async {
    final PlutoGridStateManager state = manager(<PlutoRow<dynamic>>[
      row(2),
      row(4),
      row(4),
    ]);
    final Map<PlutoAggregateColumnType, String> expected =
        <PlutoAggregateColumnType, String>{
          PlutoAggregateColumnType.count: '3',
          PlutoAggregateColumnType.uniqueCount: '2',
          PlutoAggregateColumnType.sum: '10',
          PlutoAggregateColumnType.average: '3',
          PlutoAggregateColumnType.min: '2',
          PlutoAggregateColumnType.max: '4',
        };
    for (final PlutoAggregateColumnType type in expected.keys) {
      await tester.pumpWidget(footer(state, type: type));
      await tester.pumpAndSettle();
      expect(find.text(expected[type]!), findsOneWidget);
    }
  });

  testWidgets('large footer yields and replaces work after rows change', (
    WidgetTester tester,
  ) async {
    final List<PlutoRow<dynamic>> rows = List<PlutoRow<dynamic>>.generate(
      PlutoGridSettings.calculationMaxStepsPerFrame * 2,
      row,
    );
    final PlutoGridStateManager state = manager(rows);
    int visited = 0;
    await tester.pumpWidget(
      footer(
        state,
        filter: (PlutoCell cell) {
          visited += 1;
          return true;
        },
      ),
    );
    expect(visited, 0);
    await tester.pump();
    expect(visited, greaterThan(0));
    expect(visited, lessThan(rows.length));

    state.refRows
      ..clearFromOriginal()
      ..addAll(<PlutoRow<dynamic>>[row(1), row(2)]);
    state.notifyListeners();
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'retains completed total while refreshing and cancels on dispose',
    (WidgetTester tester) async {
      final PlutoGridStateManager state = manager(<PlutoRow<dynamic>>[row(1)]);
      int visited = 0;
      await tester.pumpWidget(
        footer(
          state,
          filter: (PlutoCell cell) {
            visited += 1;
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      state.refRows.addAll(
        List<PlutoRow<dynamic>>.generate(
          PlutoGridSettings.calculationMaxStepsPerFrame * 2,
          row,
        ),
      );
      state.notifyListeners();
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      final int afterDispose = visited;
      await tester.pumpAndSettle();
      expect(visited, afterDispose);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('new state manager replaces subscriptions and pending work', (
    WidgetTester tester,
  ) async {
    final PlutoGridStateManager first = manager(<PlutoRow<dynamic>>[row(1)]);
    final PlutoGridStateManager second = manager(<PlutoRow<dynamic>>[
      row(1),
      row(2),
    ]);
    await tester.pumpWidget(footer(first));
    await tester.pumpWidget(footer(second));
    expect(find.text('1'), findsNothing);
    first.refRows.clearFromOriginal();
    first.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    second.refRows.add(row(3));
    second.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
  });
}
