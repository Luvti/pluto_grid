import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

typedef _Aggregate =
    num? Function({
      required Iterable<PlutoRow<dynamic>> rows,
      required PlutoColumn column,
      PlutoAggregateFilter? filter,
    });

void main() {
  group('single-pass numeric aggregates', () {
    final Map<String, (PlutoColumnType, _Aggregate)> cases =
        <String, (PlutoColumnType, _Aggregate)>{
          'sum': (
            PlutoColumnType.number(format: '#,###.###'),
            PlutoAggregateHelper.sum,
          ),
          'average': (
            PlutoColumnType.number(format: '#,###.###'),
            PlutoAggregateHelper.average,
          ),
          'double average': (
            PlutoColumnType.double(format: '#,###.###'),
            PlutoAggregateHelper.average,
          ),
        };
    for (final String name in cases.keys) {
      final (PlutoColumnType type, _Aggregate aggregate) = cases[name]!;
      final PlutoColumn column = PlutoColumn(
        title: 'value',
        field: 'value',
        type: type,
      );

      test('$name visits sparse lazy rows and applies the filter once', () {
        int visits = 0;
        int filterCalls = 0;
        final Iterable<PlutoRow<dynamic>> rows =
            List<double>.generate(8, (int index) => index.toDouble()).map(
              (double value) {
                visits += 1;
                return PlutoRow<dynamic>(
                  cells: <String, PlutoCell>{'value': PlutoCell(value: value)},
                );
              },
            );

        expect(
          aggregate(
            rows: rows,
            column: column,
            filter: (PlutoCell cell) {
              filterCalls += 1;
              return cell.currentValue == 7;
            },
          ),
          7,
        );
        expect(visits, 8);
        expect(filterCalls, 8);
      });

      test('$name skips nulls and retains column rounding', () {
        final List<PlutoRow<dynamic>> rows = <double?>[null, 1.1234, 2.6789]
            .map(
              (double? value) => PlutoRow<dynamic>(
                cells: <String, PlutoCell>{'value': PlutoCell(value: value)},
              ),
            )
            .toList();

        expect(
          aggregate(rows: rows, column: column),
          name == 'sum' ? 3.802 : 1.901,
        );
        expect(
          aggregate(
            rows: rows,
            column: column,
            filter: (PlutoCell cell) => false,
          ),
          name == 'sum' ? 0 : null,
        );
        expect(
          aggregate(rows: <PlutoRow<dynamic>>[rows.first], column: column),
          name == 'sum' ? 0 : null,
        );
        expect(
          aggregate(rows: <PlutoRow<dynamic>>[], column: column),
          name == 'double average' ? null : 0,
        );
      });

      test('$name preserves handling of a missing first field', () {
        final List<PlutoRow<dynamic>> rows = <PlutoRow<dynamic>>[
          PlutoRow<dynamic>(cells: <String, PlutoCell>{}),
          PlutoRow<dynamic>(
            cells: <String, PlutoCell>{'value': PlutoCell(value: 5.0)},
          ),
        ];
        expect(
          aggregate(rows: rows, column: column),
          name == 'double average' ? 5 : 0,
        );
      });
    }

    test('double average still reads the sorting value', () {
      final PlutoColumn column = PlutoColumn(
        title: 'value',
        field: 'value',
        type: PlutoColumnType.double(format: '#,###.###'),
      );
      final PlutoCell cell = PlutoCell(value: '2.5')..setColumn(column);
      expect(cell.currentValue, '2.5');
      expect(
        PlutoAggregateHelper.average(
          rows: <PlutoRow<dynamic>>[
            PlutoRow<dynamic>(cells: <String, PlutoCell>{'value': cell}),
          ],
          column: column,
        ),
        2.5,
      );
    });
  });

  group('sum', () {
    test('숫자 컬럼이 아닌경우 0이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.text(),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: '10.001')}),
        PlutoRow(cells: {'column': PlutoCell(value: '10.001')}),
        PlutoRow(cells: {'column': PlutoCell(value: '10.001')}),
        PlutoRow(cells: {'column': PlutoCell(value: '10.001')}),
        PlutoRow(cells: {'column': PlutoCell(value: '10.001')}),
      ];

      expect(PlutoAggregateHelper.sum(rows: rows, column: column), 0);
    });

    test('[양수] condition 이 없이 sum 을 호출 한 경우 전체 합계 값이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10)}),
        PlutoRow(cells: {'column': PlutoCell(value: 20)}),
        PlutoRow(cells: {'column': PlutoCell(value: 30)}),
        PlutoRow(cells: {'column': PlutoCell(value: 40)}),
        PlutoRow(cells: {'column': PlutoCell(value: 50)}),
      ];

      expect(PlutoAggregateHelper.sum(rows: rows, column: column), 150);
    });

    test('[음수] condition 이 없이 sum 을 호출 한 경우 전체 합계 값이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: -10)}),
        PlutoRow(cells: {'column': PlutoCell(value: -20)}),
        PlutoRow(cells: {'column': PlutoCell(value: -30)}),
        PlutoRow(cells: {'column': PlutoCell(value: -40)}),
        PlutoRow(cells: {'column': PlutoCell(value: -50)}),
      ];

      expect(PlutoAggregateHelper.sum(rows: rows, column: column), -150);
    });

    test('[소수] condition 이 없이 sum 을 호출 한 경우 전체 합계 값이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###.###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
      ];

      expect(PlutoAggregateHelper.sum(rows: rows, column: column), 50.005);
    });

    test('condition 이 있는 경우 조건에 맞는 아이템의 합계 값이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###.###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
      ];

      expect(
        PlutoAggregateHelper.sum(
          rows: rows,
          column: column,
          filter: (PlutoCell cell) => cell.value == 10.001,
        ),
        30.003,
      );
    });

    test('condition 이 있는 경우 조건에 맞는 아이템이 없다면 0이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###.###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
      ];

      expect(
        PlutoAggregateHelper.sum(
          rows: rows,
          column: column,
          filter: (PlutoCell cell) => cell.value == 10.003,
        ),
        0,
      );
    });
  });

  group('average', () {
    test('[양수] condition 이 없이 average 을 호출 한 경우 전체 합계 값이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10)}),
        PlutoRow(cells: {'column': PlutoCell(value: 20)}),
        PlutoRow(cells: {'column': PlutoCell(value: 30)}),
        PlutoRow(cells: {'column': PlutoCell(value: 40)}),
        PlutoRow(cells: {'column': PlutoCell(value: 50)}),
      ];

      expect(PlutoAggregateHelper.average(rows: rows, column: column), 30);
    });

    test('[음수] condition 이 없이 average 을 호출 한 경우 전체 합계 값이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: -10)}),
        PlutoRow(cells: {'column': PlutoCell(value: -20)}),
        PlutoRow(cells: {'column': PlutoCell(value: -30)}),
        PlutoRow(cells: {'column': PlutoCell(value: -40)}),
        PlutoRow(cells: {'column': PlutoCell(value: -50)}),
      ];

      expect(PlutoAggregateHelper.average(rows: rows, column: column), -30);
    });

    test('[소수] condition 이 없이 average 을 호출 한 경우 전체 합계 값이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###.###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.003)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.004)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.005)}),
      ];

      expect(PlutoAggregateHelper.average(rows: rows, column: column), 10.003);
    });
  });

  group('min', () {
    test('[양수] condition 이 없이 min 을 호출 한 경우 최소 값이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 101)}),
        PlutoRow(cells: {'column': PlutoCell(value: 102)}),
        PlutoRow(cells: {'column': PlutoCell(value: 103)}),
        PlutoRow(cells: {'column': PlutoCell(value: 104)}),
        PlutoRow(cells: {'column': PlutoCell(value: 105)}),
      ];

      expect(PlutoAggregateHelper.min(rows: rows, column: column), 101);
    });

    test('[음수] condition 이 없이 min 을 호출 한 경우 최소 값이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: -101)}),
        PlutoRow(cells: {'column': PlutoCell(value: -102)}),
        PlutoRow(cells: {'column': PlutoCell(value: -103)}),
        PlutoRow(cells: {'column': PlutoCell(value: -104)}),
        PlutoRow(cells: {'column': PlutoCell(value: -105)}),
      ];

      expect(PlutoAggregateHelper.min(rows: rows, column: column), -105);
    });

    test('[소수] condition 이 없이 min 을 호출 한 경우 최소 값이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###.###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.003)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.004)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.005)}),
      ];

      expect(PlutoAggregateHelper.min(rows: rows, column: column), 10.001);
    });

    test('condition 이 있는 경우 조건에 맞는 아이템이 있다면 조건내에서 최소값이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###.###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.003)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.004)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.005)}),
      ];

      expect(
        PlutoAggregateHelper.min(
          rows: rows,
          column: column,
          filter: (PlutoCell cell) => cell.value >= 10.003,
        ),
        10.003,
      );
    });

    test('condition 이 있는 경우 조건에 맞는 아이템이 없다면 null 이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###.###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
      ];

      expect(
        PlutoAggregateHelper.min(
          rows: rows,
          column: column,
          filter: (PlutoCell cell) => cell.value == 10.003,
        ),
        null,
      );
    });
  });

  group('max', () {
    test('condition 이 있는 경우 조건에 맞는 아이템이 있다면 조건내에서 최대값이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###.###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.003)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.004)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.005)}),
      ];

      expect(
        PlutoAggregateHelper.max(
          rows: rows,
          column: column,
          filter: (PlutoCell cell) => cell.value >= 10.003,
        ),
        10.005,
      );
    });

    test('condition 이 있는 경우 조건에 맞는 아이템이 없다면 null 이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###.###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.003)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.004)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.005)}),
      ];

      expect(
        PlutoAggregateHelper.max(
          rows: rows,
          column: column,
          filter: (PlutoCell cell) => cell.value >= 10.006,
        ),
        null,
      );
    });
  });

  group('count', () {
    final PlutoColumn countColumn = PlutoColumn(
      title: 'column',
      field: 'column',
      type: PlutoColumnType.number(),
    );

    test('empty rows and a missing first field do not call the filter', () {
      for (final List<PlutoRow<dynamic>> rows in <List<PlutoRow<dynamic>>>[
        <PlutoRow<dynamic>>[],
        <PlutoRow<dynamic>>[
          PlutoRow<dynamic>(cells: <String, PlutoCell>{}),
          PlutoRow<dynamic>(
            cells: <String, PlutoCell>{'column': PlutoCell(value: 1)},
          ),
        ],
      ]) {
        expect(PlutoAggregateHelper.count(rows: rows, column: countColumn), 0);
        expect(
          PlutoAggregateHelper.count(
            rows: rows,
            column: countColumn,
            filter: (_) => throw StateError('Unexpected filter call'),
          ),
          0,
        );
      }
    });

    test('filtered count visits lazy rows and their cells only once', () {
      int visits = 0;
      final List<Object?> values = <Object?>[];
      final Iterable<PlutoRow<dynamic>> rows = <int?>[null, 1, 2, 3].map((
        int? value,
      ) {
        visits += 1;
        return PlutoRow<dynamic>(
          cells: <String, PlutoCell>{'column': PlutoCell(value: value)},
        );
      });

      expect(
        PlutoAggregateHelper.count(
          rows: rows,
          column: countColumn,
          filter: (PlutoCell cell) {
            values.add(cell.currentValue);
            return cell.currentValue != null;
          },
        ),
        3,
      );
      expect(visits, 4);
      expect(values, <int?>[null, 1, 2, 3]);
    });

    test('count follows the filtered page and later cell edits', () {
      final FilteredList<PlutoRow<dynamic>> rows =
          FilteredList<PlutoRow<dynamic>>(
            initialList: List<PlutoRow<dynamic>>.generate(
              10,
              (int index) => PlutoRow<dynamic>(
                cells: <String, PlutoCell>{'column': PlutoCell(value: index)},
              ),
            ),
          )..setFilter(
            (PlutoRow<dynamic> row) =>
                (row.cells['column']!.currentValue as int).isEven,
          );
      final FilteredListRange range = FilteredListRange(1, 4);
      rows.setFilterRange(range);
      bool matches(PlutoCell cell) => (cell.currentValue as int) >= 4;

      expect(PlutoAggregateHelper.count(rows: rows, column: countColumn), 3);
      expect(
        PlutoAggregateHelper.count(
          rows: rows,
          column: countColumn,
          filter: matches,
        ),
        2,
      );
      rows[0].cells['column']!.value = 10;
      expect(
        PlutoAggregateHelper.count(
          rows: rows,
          column: countColumn,
          filter: matches,
        ),
        3,
      );
      range.setRange(4, 10);
      expect(PlutoAggregateHelper.count(rows: rows, column: countColumn), 1);
      expect(
        PlutoAggregateHelper.count(
          rows: rows,
          column: countColumn,
          filter: matches,
        ),
        1,
      );
    });

    test('condition 이 없는 경우 전체 리스트 개수가 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###.###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.003)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.004)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.005)}),
      ];

      expect(PlutoAggregateHelper.count(rows: rows, column: column), 5);
    });

    test('condition 이 있는 경우 조건에 맞는 아이템이 있다면 조건에 맞는 아이템 개수가 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###.###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.003)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.004)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.005)}),
      ];

      expect(
        PlutoAggregateHelper.count(
          rows: rows,
          column: column,
          filter: (PlutoCell cell) => cell.value >= 10.003,
        ),
        3,
      );
    });

    test('condition 이 있는 경우 조건에 맞는 아이템이 없다면 0 이 리턴 되어야 한다.', () {
      final column = PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(format: '#,###.###'),
      );

      final rows = [
        PlutoRow(cells: {'column': PlutoCell(value: 10.001)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.002)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.003)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.004)}),
        PlutoRow(cells: {'column': PlutoCell(value: 10.005)}),
      ];

      expect(
        PlutoAggregateHelper.count(
          rows: rows,
          column: column,
          filter: (PlutoCell cell) => cell.value >= 10.006,
        ),
        0,
      );
    });
  });
}
