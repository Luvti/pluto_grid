import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  test(
    '100000 cells allocate comparison values only for the sorted column',
    () {
      const int rowCount = 10000;
      final List<_CountingTextType> types = List<_CountingTextType>.generate(
        10,
        (int index) => _CountingTextType(),
      );
      final List<PlutoColumn> columns = List<PlutoColumn>.generate(
        types.length,
        (int index) =>
            PlutoColumn(title: '', field: 'field$index', type: types[index]),
      );
      final List<PlutoRow<dynamic>> rows = List<PlutoRow<dynamic>>.generate(
        rowCount,
        (int index) => PlutoRow<dynamic>(
          cells: <String, PlutoCell>{
            for (final PlutoColumn column in columns)
              column.field: _KeyReadCell(value: rowCount - index),
          },
        ),
      );
      final FocusNode focus = FocusNode();
      final PlutoGridStateManager manager = PlutoGridStateManager(
        columns: columns,
        rows: rows,
        gridFocusNode: focus,
        scroll: PlutoGridScrollController(),
      );
      try {
        expect(
          types.map((_CountingTextType type) => type.conversions),
          everyElement(0),
        );
        final PlutoCell target = rows.last.cells['field9']!;
        expect(manager.cellPositionByCellKey(target.key)?.rowIdx, rowCount - 1);
        expect(_keyReads(rows), 1);

        manager.sortAscending(columns.first);
        expect(types.first.conversions, rowCount);
        expect(
          types.skip(1).map((_CountingTextType type) => type.conversions),
          everyElement(0),
        );
        manager.sortDescending(columns.first);
        expect(types.first.conversions, rowCount);
        rows.last.cells['field0']!.value = 'edited';
        manager.sortAscending(columns.first);
        expect(types.first.conversions, rowCount + 1);
        expect(_keyReads(rows), 1);
      } finally {
        manager.dispose();
        focus.dispose();
      }
    },
  );
}

int _keyReads(List<PlutoRow<dynamic>> rows) => rows.fold<int>(
  0,
  (int total, PlutoRow<dynamic> row) =>
      total +
      row.cells.values.fold<int>(
        0,
        (int count, PlutoCell cell) => count + (cell as _KeyReadCell).keyReads,
      ),
);

class _CountingTextType extends PlutoColumnTypeText {
  int conversions = 0;

  @override
  Object? makeCompareValue(Object? value) {
    conversions++;
    return super.makeCompareValue(value);
  }
}

class _KeyReadCell extends PlutoCell {
  _KeyReadCell({super.value});
  int keyReads = 0;

  @override
  Key get key {
    keyReads++;
    return super.key;
  }
}
