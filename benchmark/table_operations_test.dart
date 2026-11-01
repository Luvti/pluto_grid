// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

/// Times user actions on a 160k x 48 table, the size of ASO.dev's worldwide
/// Keywords table: sorting, filtering and changing rows under a filter.
///
/// Prints the best of two rounds in `flutter test` (JIT); compare runs of the
/// same machine before and after a change.
void main() {
  test('table operations on 160k rows', () {
    final _Table table = _Table();
    final Map<String, int> best = <String, int>{};
    for (int round = 0; round < 2; round++) {
      table.run().forEach((String name, int ms) {
        best[name] = best.containsKey(name) && best[name]! < ms
            ? best[name]!
            : ms;
      });
    }
    table.dispose();
    print('TABLE_OPERATIONS_MS ${jsonEncode(best)}');
  }, timeout: const Timeout(Duration(minutes: 10)));
}

class _Table {
  _Table() {
    manager = PlutoGridStateManager(
      columns: columns,
      rows: rows,
      gridFocusNode: _focus,
      scroll: PlutoGridScrollController(),
    );
  }

  static const int rowCount = 160000;
  static const int columnCount = 48;

  final FocusNode _focus = FocusNode();
  final List<PlutoColumn> columns = <PlutoColumn>[
    for (int index = 0; index < columnCount; index++)
      PlutoColumn(
        title: 'c$index',
        field: 'c$index',
        type: PlutoColumnType.number(),
      ),
  ];
  late final List<PlutoRow<dynamic>> rows = <PlutoRow<dynamic>>[
    for (int row = 0; row < rowCount; row++)
      PlutoRow<dynamic>(
        cells: <String, PlutoCell>{
          for (final PlutoColumn column in columns)
            column.field: PlutoCell(value: (row * 7919) % 1000),
        },
      ),
  ];
  late final PlutoGridStateManager manager;

  static int _ms(void Function() action) {
    final Stopwatch watch = Stopwatch()..start();
    action();
    return watch.elapsedMilliseconds;
  }

  List<PlutoRow<dynamic>> _extraRows() => <PlutoRow<dynamic>>[
    for (int row = 0; row < 10; row++)
      PlutoRow<dynamic>(
        cells: <String, PlutoCell>{
          for (final PlutoColumn column in columns)
            column.field: PlutoCell(value: row),
        },
      ),
  ];

  Map<String, int> run() {
    final List<PlutoRow<dynamic>> filter = <PlutoRow<dynamic>>[
      FilterHelper.createFilterRow(
        columnField: 'c0',
        filterType: const PlutoFilterTypeGreaterThan(),
        filterValue: '500',
      ),
    ];
    final List<PlutoRow<dynamic>> extra = _extraRows();
    return <String, int>{
      'sort': _ms(() => manager.sortAscending(columns[3], notify: false)),
      'sortDescending': _ms(
        () => manager.sortDescending(columns[4], notify: false),
      ),
      'sortBySortIdx': _ms(
        () => manager.sortBySortIdx(columns[4], notify: false),
      ),
      'filter': _ms(
        () => manager.setFilterWithFilterRows(filter, notify: false),
      ),
      'sortFiltered': _ms(
        () => manager.sortAscending(columns[5], notify: false),
      ),
      'appendFiltered': _ms(() => manager.appendRows(extra)),
      'removeFiltered': _ms(() => manager.removeRows(extra, notify: false)),
      'clearFilter': _ms(
        () => manager.setFilterWithFilterRows(
          <PlutoRow<dynamic>>[],
          notify: false,
        ),
      ),
      'checkAll': _ms(() => manager.toggleAllRowChecked(true, notify: false)),
      'checkedRows': _ms(() => manager.checkedRows.length),
    };
  }

  void dispose() {
    manager.dispose();
    _focus.dispose();
  }
}
