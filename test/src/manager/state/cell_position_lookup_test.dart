import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  test('a position by key reads the cells of one row only', () {
    final List<PlutoColumn> columns = <PlutoColumn>[
      for (int index = 0; index < 10; index++)
        PlutoColumn(
          title: 'c$index',
          field: 'c$index',
          type: PlutoColumnType.number(),
        ),
    ];
    final List<_CountingCells> cells = <_CountingCells>[
      for (int row = 0; row < 1000; row++)
        _CountingCells(<String, PlutoCell>{
          for (final PlutoColumn column in columns)
            column.field: PlutoCell(value: row),
        }),
    ];
    final FocusNode focus = FocusNode();
    final PlutoGridStateManager manager = PlutoGridStateManager(
      columns: columns,
      rows: <PlutoRow<dynamic>>[
        for (final _CountingCells rowCells in cells)
          PlutoRow<dynamic>(cells: rowCells),
      ],
      gridFocusNode: focus,
      scroll: PlutoGridScrollController(),
    );
    addTearDown(() {
      manager.dispose();
      focus.dispose();
    });

    final Key key = cells[700]['c9']!.key;
    _CountingCells.reads = 0;
    final PlutoGridCellPosition? position = manager.cellPositionByCellKey(key);

    expect((position?.rowIdx, position?.columnIdx), (700, 9));
    // One row of ten cells instead of 701 rows of ten.
    expect(_CountingCells.reads, lessThanOrEqualTo(columns.length));
  });
}

class _CountingCells extends MapBase<String, PlutoCell> {
  _CountingCells(this._cells);

  static int reads = 0;

  final Map<String, PlutoCell> _cells;

  @override
  PlutoCell? operator [](Object? key) {
    reads++;
    return _cells[key];
  }

  @override
  void operator []=(String key, PlutoCell value) => _cells[key] = value;

  @override
  void clear() => _cells.clear();

  @override
  Iterable<String> get keys => _cells.keys;

  @override
  PlutoCell? remove(Object? key) => _cells.remove(key);
}
