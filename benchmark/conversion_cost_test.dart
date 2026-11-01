// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

/// Times filtering, sorting and formatting on 100k unrendered cells.
///
/// These paths convert values to strings and back for every row: compare the
/// printed times of the same run before and after a change. Timings in
/// `flutter test` (JIT) are higher than in a release build.
void main() {
  test('conversion cost of 100k rows', () {
    final _Bench bench = _Bench();
    final Map<String, int> best = <String, int>{};
    for (int round = 0; round < 3; round++) {
      bench.run().forEach((String name, int ms) {
        best[name] = best.containsKey(name) && best[name]! < ms
            ? best[name]!
            : ms;
      });
    }
    print('CONVERSION_COST_MS ${jsonEncode(best)}');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

class _Bench {
  static const int rowCount = 100000;

  final PlutoColumn number = PlutoColumn(
    title: 'number',
    field: 'number',
    type: PlutoColumnType.number(),
  );
  final PlutoColumn text = PlutoColumn(
    title: 'text',
    field: 'text',
    type: PlutoColumnType.text(),
  );
  final PlutoColumn date = PlutoColumn(
    title: 'date',
    field: 'date',
    type: PlutoColumnType.date(),
  );
  final PlutoColumn set = PlutoColumn(
    title: 'set',
    field: 'set',
    type: PlutoColumnType.text(),
  );

  final PlutoColumn rank = PlutoColumn(
    title: 'rank',
    field: 'rank',
    type: PlutoColumnType.number(),
  );
  final PlutoColumn week = PlutoColumn(
    title: 'week',
    field: 'week',
    type: PlutoColumnType.date(format: 'dd.MM.yyyy'),
  );

  late final List<PlutoRow<dynamic>> rows = _rows();

  static Object _weekDate(int index) => '2026-10-0${1 + index % 7}';

  /// Fresh initialized cells, so every pass converts each cell once.
  List<PlutoCell> _repeatedCells(
    PlutoColumn column,
    Object Function(int) value,
  ) {
    final List<PlutoRow<dynamic>> fresh = <PlutoRow<dynamic>>[
      for (int index = 0; index < rowCount; index++)
        PlutoRow<dynamic>(
          cells: <String, PlutoCell>{
            column.field: PlutoCell(value: value(index)),
          },
        ),
    ];
    PlutoGridStateManager.initializeRows(<PlutoColumn>[column], fresh);
    return <PlutoCell>[
      for (final PlutoRow<dynamic> row in fresh) row.cells[column.field]!,
    ];
  }

  List<PlutoRow<dynamic>> _rows() {
    final List<PlutoRow<dynamic>> result = <PlutoRow<dynamic>>[
      for (int index = 0; index < rowCount; index++)
        PlutoRow<dynamic>(
          cells: <String, PlutoCell>{
            'number': PlutoCell(value: index * 1.5),
            'text': PlutoCell(value: 'keyword number $index'),
            'date': PlutoCell(
              value:
                  DateTime(
                        2020,
                      )
                      .add(Duration(days: index % 2000))
                      .toIso8601String()
                      .substring(0, 10),
            ),
            'set': PlutoCell(
              value: '',
              filterValue: <String?>{'a$index', 'b${index % 10}'},
            ),
            'rank': PlutoCell(value: 1 + index % 200),
          },
        ),
    ];
    PlutoGridStateManager.initializeRows(<PlutoColumn>[
      number,
      text,
      date,
      set,
      rank,
    ], result);
    return result;
  }

  int _filter(PlutoColumn column, PlutoFilterType type, String search) {
    final FilteredListFilter<PlutoRow<dynamic>?> filter =
        FilterHelper.convertRowsToFilter(
          <PlutoRow<dynamic>>[
            FilterHelper.createFilterRow(
              columnField: column.field,
              filterType: type,
              filterValue: search,
            ),
          ],
          <PlutoColumn>[number, text, date, set, rank],
        )!;
    int kept = 0;
    for (final PlutoRow<dynamic> row in rows) {
      if (filter(row)) {
        kept++;
      }
    }
    return kept;
  }

  static int _ms(void Function() action) {
    final Stopwatch watch = Stopwatch()..start();
    action();
    return watch.elapsedMilliseconds;
  }

  Map<String, int> run() {
    final List<dynamic> dates = rows
        .map((PlutoRow<dynamic> row) => row.cells['date']!.valueForSorting)
        .toList();
    final List<dynamic> numbers = rows
        .map((PlutoRow<dynamic> row) => row.cells['number']!.valueForSorting)
        .toList();
    return <String, int>{
      'numberContains': _ms(
        () => _filter(number, const PlutoFilterTypeContains(), '15'),
      ),
      'numberEquals': _ms(
        () => _filter(number, const PlutoFilterTypeEquals(), '15'),
      ),
      'numberGreaterThan': _ms(
        () => _filter(number, const PlutoFilterTypeGreaterThan(), '1000'),
      ),
      'textContains': _ms(
        () => _filter(text, const PlutoFilterTypeContains(), 'number 99'),
      ),
      'setContains': _ms(
        () => _filter(set, const PlutoFilterTypeContainsSet(), 'b3'),
      ),
      'dateSort': _ms(() => dates.sort(date.type.compare)),
      'numberSort': _ms(() => numbers.sort(number.type.compare)),
      'numberFormat': _ms(() {
        for (final PlutoRow<dynamic> row in rows) {
          number.type.applyFormat(row.cells['number']!.currentValue);
        }
      }),
      'numberToNumber': _ms(() {
        final PlutoColumnTypeWithNumberFormat type =
            number.type as PlutoColumnTypeWithNumberFormat;
        for (int index = 0; index < rowCount; index++) {
          type.toNumber('${index * 1.5}');
        }
      }),
      'numberCompareValue': _ms(() {
        for (int index = 0; index < rowCount; index++) {
          number.type.makeCompareValue(index * 1.5);
        }
      }),
      // Table values repeat: ranks 1-200 and seven dates for every keyword.
      'rankFormat': _ms(() {
        for (int index = 0; index < rowCount; index++) {
          number.type.applyFormat(1 + index % 200);
        }
      }),
      'rankEquals': _ms(
        () => _filter(rank, const PlutoFilterTypeEquals(), '15'),
      ),
      'rankFormatOnInit': _ms(() {
        for (final PlutoCell cell in _repeatedCells(
          rank,
          (int index) => 1 + index % 200,
        )) {
          cell.valueFormatted;
        }
      }),
      'weekDateSortValues': _ms(() {
        for (final PlutoCell cell in _repeatedCells(week, _weekDate)) {
          cell.valueForSorting;
        }
      }),
      'weekDateFormatOnInit': _ms(() {
        for (final PlutoCell cell in _repeatedCells(week, _weekDate)) {
          cell.valueFormatted;
        }
      }),
    };
  }
}
