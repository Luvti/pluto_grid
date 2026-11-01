// Characterization of PlutoCell callbacks, identity and back references,
// recorded before the cell fields were slimmed down.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  group('onChanged', () {
    test('runs once per changed value with the reference value', () {
      final List<String> calls = <String>[];
      final PlutoCell cell = PlutoCell(
        value: 1,
        referenceValue: 'reference',
        onChanged: ({Object? value, Object? referenceValue}) =>
            calls.add('$value/$referenceValue'),
      );

      cell.value = 1;
      expect(calls, isEmpty);
      cell
        ..value = 2
        ..referenceValue = 'other'
        ..value = 3;
      expect(calls, <String>['2/reference', '3/other']);
      expect(cell.onChanged, isNotNull);

      cell
        ..onChanged = null
        ..value = 4;
      expect(calls, hasLength(2));
      expect(PlutoCell(value: 1).onChanged, isNull);
    });

    test('runs for changes made through the state manager', () {
      final List<Object?> values = <Object?>[];
      final _Manager grid = _Manager.of(<PlutoRow<dynamic>>[
        PlutoRow<dynamic>(
          cells: <String, PlutoCell>{
            'number': PlutoCell(
              value: 1,
              onChanged: ({Object? value, Object? referenceValue}) => values.add(value),
            ),
            'text': PlutoCell(value: 'a'),
          },
        ),
      ]);
      addTearDown(grid.dispose);

      grid.manager.changeCellValue(
        grid.rows.first.cells['number']!,
        5,
        force: true,
      );
      expect(values, <Object?>[5]);
    });
  });

  group('keys', () {
    test('stay with their cells through sorting, filtering and clearing', () {
      final _Manager grid = _Manager.of(_Manager.numbers(<int>[3, 1, 2]));
      addTearDown(grid.dispose);
      final PlutoCell first = grid.rows.first.cells['number']!;
      final Key key = first.key;

      expect(first.hasKey(key), isTrue);
      expect(first.hasKey(UniqueKey()), isFalse);
      expect(
        grid.rows[1].cells['number']!.key,
        isNot(same(key)),
      );

      grid.manager.sortAscending(grid.numberColumn, notify: false);
      expect(first.key, same(key));
      expect(grid.manager.cellPositionByCellKey(key)?.rowIdx, 2);

      grid.manager.setFilterWithFilterRows(<PlutoRow<dynamic>>[
        FilterHelper.createFilterRow(
          columnField: 'number',
          filterType: const PlutoFilterTypeEquals(),
          filterValue: '3',
        ),
      ], notify: false);
      expect(grid.manager.refRows, hasLength(1));
      expect(grid.manager.cellPositionByCellKey(key)?.rowIdx, 0);

      first.clear();
      expect(first.key, same(key));
    });

    test('a supplied key is kept', () {
      final UniqueKey key = UniqueKey();
      expect(PlutoCell(key: key).key, same(key));
      expect(PlutoCell(key: key).hasKey(key), isTrue);
    });
  });

  group('column and row references', () {
    test('initializing rows links every cell to its column and row', () {
      final PlutoColumn number = _Manager.column('number');
      final PlutoColumn text = PlutoColumn(
        title: 'text',
        field: 'text',
        type: PlutoColumnType.text(),
      );
      final List<PlutoRow<dynamic>> rows = <PlutoRow<dynamic>>[
        for (final int value in <int>[1, 2])
          PlutoRow<dynamic>(
            cells: <String, PlutoCell>{
              'number': PlutoCell(value: value),
              'text': PlutoCell(value: '$value'),
            },
          ),
      ];
      expect(rows.first.initialized, isFalse);
      expect(rows.first.cells['number']!.initialized, isFalse);

      PlutoGridStateManager.initializeRows(<PlutoColumn>[number, text], rows);

      for (final PlutoRow<dynamic> row in rows) {
        expect(row.initialized, isTrue);
        expect(row.cells['number']!.column, same(number));
        expect(row.cells['number']!.row, same(row));
        expect(row.cells['text']!.column, same(text));
        expect(row.cells['text']!.row, same(row));
      }
    });

    test('asynchronous initialization links the same way', () async {
      final PlutoColumn number = _Manager.column('number');
      final List<PlutoRow<dynamic>> rows = _Manager.numbers(
        List<int>.generate(250, (int index) => index),
      );

      await PlutoGridStateManager.initializeRowsAsync(
        <PlutoColumn>[number],
        rows,
      );

      expect(rows.every((PlutoRow<dynamic> row) => row.initialized), isTrue);
      expect(rows.last.cells['number']!.row, same(rows.last));
      expect(rows.last.cells['number']!.column, same(number));
      expect(rows.last.cells['number']!.valueForSorting, 249);
    });

    test('appended, inserted and filled cells are linked', () {
      final _Manager grid = _Manager.of(_Manager.numbers(<int>[1, 2]));
      addTearDown(grid.dispose);

      final List<PlutoRow<dynamic>> appended = _Manager.numbers(<int>[7]);
      grid.manager.appendRows(appended);
      final List<PlutoRow<dynamic>> inserted = _Manager.numbers(<int>[8]);
      grid.manager.insertRows(0, inserted);

      for (final PlutoRow<dynamic> row in <PlutoRow<dynamic>>[
        ...appended,
        ...inserted,
      ]) {
        expect(row.cells['number']!.row, same(row));
        expect(row.cells['number']!.column, same(grid.numberColumn));
      }

      final PlutoColumn added = PlutoColumn(
        title: 'added',
        field: 'added',
        type: PlutoColumnType.number(defaultValue: 5),
      );
      grid.manager.insertColumns(1, <PlutoColumn>[added]);
      for (final PlutoRow<dynamic> row in grid.manager.refRows) {
        final PlutoCell cell = row.cells['added']!;
        expect(cell.column, same(added));
        expect(cell.row, same(row));
        expect(cell.currentValue, 5);
      }

      final PlutoCell removed = grid.manager.refRows.first.cells['added']!;
      grid.manager.removeColumns(<PlutoColumn>[added]);
      expect(grid.manager.refRows.first.cells.containsKey('added'), isFalse);
      // A removed column's cell keeps its references.
      expect(removed.initialized, isTrue);
    });

    test('clearing a cell releases its references', () {
      final PlutoColumn number = _Manager.column('number');
      final List<PlutoRow<dynamic>> rows = _Manager.numbers(<int>[1]);
      PlutoGridStateManager.initializeRows(<PlutoColumn>[number], rows);
      final PlutoCell cell = rows.first.cells['number']!..clear();

      expect(cell.initialized, isFalse);
      expect(rows.first.initialized, isFalse);
      expect(cell.currentValue, 1);
    });
  });
}

class _Manager {
  _Manager(this.rows, this.numberColumn, this.manager, this._focus);

  final List<PlutoRow<dynamic>> rows;
  final PlutoColumn numberColumn;
  final PlutoGridStateManager manager;
  final FocusNode _focus;

  static PlutoColumn column(String field) =>
      PlutoColumn(title: field, field: field, type: PlutoColumnType.number());

  static List<PlutoRow<dynamic>> numbers(List<int> values) => values
      .map(
        (int value) => PlutoRow<dynamic>(
          cells: <String, PlutoCell>{'number': PlutoCell(value: value)},
        ),
      )
      .toList();

  // ignore: prefer_constructors_over_static_methods
  static _Manager of(List<PlutoRow<dynamic>> rows) {
    final PlutoColumn number = column('number');
    final List<PlutoColumn> columns = <PlutoColumn>[
      number,
      if (rows.first.cells.containsKey('text'))
        PlutoColumn(title: 'text', field: 'text', type: PlutoColumnType.text()),
    ];
    final FocusNode focus = FocusNode();
    final PlutoGridStateManager manager = PlutoGridStateManager(
      columns: columns,
      rows: rows,
      gridFocusNode: focus,
      scroll: PlutoGridScrollController(),
    );
    return _Manager(rows, number, manager, focus);
  }

  void dispose() {
    manager.dispose();
    _focus.dispose();
  }
}
