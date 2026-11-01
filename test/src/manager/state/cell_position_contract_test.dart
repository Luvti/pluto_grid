// Characterization of cell positions found by key, recorded before the
// lookup searched the cell's own row instead of every cell of the grid.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  late _Grid grid;

  setUp(() => grid = _Grid());
  tearDown(() => grid.dispose());

  test('sorting and filtering clear the current cell', () {
    grid.manager.setCurrentCell(
      grid.cell(row: 10, field: 'b'),
      10,
      notify: false,
    );
    grid.manager.sortDescending(grid.columns.first, notify: false);
    expect(grid.manager.currentCell, isNull);
    expect(grid.manager.currentCellPosition, isNull);

    grid.manager.setCurrentCell(
      grid.cell(row: 30, field: 'c'),
      30,
      notify: false,
    );
    grid.filter('a', const PlutoFilterTypeGreaterThanOrEqualTo(), '20');
    expect(grid.manager.currentCell, isNull);
  });

  test('inserted rows move the current cell', () {
    final PlutoCell cell = grid.cell(row: 10, field: 'b');
    grid.manager.setCurrentCell(cell, 10, notify: false);

    grid.manager.insertRows(0, _Grid.newRows(5), notify: false);
    expect(grid.position(), (15, 1));
    grid.manager.appendRows(_Grid.newRows(3));
    expect(grid.position(), (15, 1));
    expect(grid.manager.currentCell, same(cell));
  });

  test('a moved column moves the current cell', () {
    final PlutoCell cell = grid.cell(row: 40, field: 'a');
    grid.manager.setCurrentCell(cell, 40, notify: false);

    grid.manager.moveColumn(
      column: grid.columns[0],
      targetColumn: grid.columns[2],
    );
    expect(grid.position(), (40, 2));
  });

  test('a filtered out cell has no position', () {
    final PlutoCell cell = grid.cell(row: 30, field: 'c');
    grid.filter('a', const PlutoFilterTypeLessThan(), '20');
    expect(grid.manager.cellPositionByCellKey(cell.key), isNull);
    grid.filter(null, null, null);
    expect(grid.manager.cellPositionByCellKey(cell.key)?.rowIdx, 30);
  });

  test('cells other than the current one are found by key', () {
    grid.manager.setCurrentCell(
      grid.cell(row: 0, field: 'a'),
      0,
      notify: false,
    );
    final PlutoCell other = grid.cell(row: 77, field: 'c');
    final PlutoGridCellPosition? position = grid.manager.cellPositionByCellKey(
      other.key,
    );
    expect((position?.rowIdx, position?.columnIdx), (77, 2));
    expect(grid.manager.cellPositionByCellKey(UniqueKey()), isNull);
  });

  test('removing rows updates the current cell and the selection', () {
    final PlutoCell current = grid.cell(row: 50, field: 'b');
    grid.manager
      ..setSelectingMode(PlutoGridSelectingMode.cell, notify: false)
      ..setCurrentCell(current, 50, notify: false)
      ..setCurrentSelectingPosition(
        cellPosition: const PlutoGridCellPosition(columnIdx: 2, rowIdx: 60),
        notify: false,
      );

    grid.manager.removeRows(<PlutoRow<dynamic>>[
      grid.rows[0],
      grid.rows[1],
      grid.rows[2],
    ], notify: false);

    expect(grid.position(), (47, 1));
    expect(
      (
        grid.manager.currentSelectingPosition?.rowIdx,
        grid.manager.currentSelectingPosition?.columnIdx,
      ),
      (57, 2),
    );

    grid.manager.removeRows(<PlutoRow<dynamic>>[grid.rows[50]], notify: false);
    expect(grid.manager.currentCellPosition, isNull);
  });
}

class _Grid {
  _Grid() {
    manager = PlutoGridStateManager(
      columns: columns,
      rows: rows,
      gridFocusNode: _focus,
      scroll: PlutoGridScrollController(),
    );
  }

  final FocusNode _focus = FocusNode();

  final List<PlutoColumn> columns = <PlutoColumn>[
    for (final String field in <String>['a', 'b', 'c'])
      PlutoColumn(title: field, field: field, type: PlutoColumnType.number()),
  ];

  final List<PlutoRow<dynamic>> rows = <PlutoRow<dynamic>>[
    for (int index = 0; index < 100; index++)
      PlutoRow<dynamic>(
        cells: <String, PlutoCell>{
          'a': PlutoCell(value: index),
          'b': PlutoCell(value: index * 2),
          'c': PlutoCell(value: index * 3),
        },
      ),
  ];

  late final PlutoGridStateManager manager;

  PlutoCell cell({required int row, required String field}) =>
      rows[row].cells[field]!;

  (int?, int?) position() => (
    manager.currentCellPosition?.rowIdx,
    manager.currentCellPosition?.columnIdx,
  );

  static List<PlutoRow<dynamic>> newRows(int count) => <PlutoRow<dynamic>>[
    for (int index = 0; index < count; index++)
      PlutoRow<dynamic>(
        cells: <String, PlutoCell>{
          'a': PlutoCell(value: -1),
          'b': PlutoCell(value: -2),
          'c': PlutoCell(value: -3),
        },
      ),
  ];

  void filter(String? field, PlutoFilterType? type, String? value) {
    manager.setFilterWithFilterRows(
      field == null
          ? <PlutoRow<dynamic>>[]
          : <PlutoRow<dynamic>>[
              FilterHelper.createFilterRow(
                columnField: field,
                filterType: type,
                filterValue: value,
              ),
            ],
      notify: false,
    );
  }

  void dispose() {
    manager.dispose();
    _focus.dispose();
  }
}
