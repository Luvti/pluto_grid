import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  test('locating a far-away cell does not materialize other cell keys', () {
    final column = PlutoColumn(
      title: '',
      field: 'field',
      type: PlutoColumnType.text(),
    );
    final cells = List<_KeyReadCell>.generate(
      100,
      (index) => _KeyReadCell(value: index),
    );
    final rows = cells.map((cell) => PlutoRow(cells: {'field': cell})).toList();
    final focus = FocusNode();
    final manager = PlutoGridStateManager(
      columns: [column],
      rows: rows,
      gridFocusNode: focus,
      scroll: PlutoGridScrollController(),
    );
    final key = cells.last.key;
    final position = manager.cellPositionByCellKey(key);
    expect(position?.rowIdx, rows.length - 1);
    expect(position?.columnIdx, 0);
    expect(cells.fold<int>(0, (total, cell) => total + cell.keyReads), 1);
    manager.dispose();
    focus.dispose();
  });

  test('cell identity stays stable across editing and reinitialization', () {
    final cell = PlutoCell(value: 1);
    final key = cell.key;
    expect(cell.hasKey(key), isTrue);
    expect(cell.hasKey(UniqueKey()), isFalse);
    cell.value = 2;
    cell.clear();
    expect(cell.key, same(key));
    final suppliedKey = UniqueKey();
    expect(PlutoCell(key: suppliedKey).key, same(suppliedKey));
  });

  test('initializing rows defers conversion until a column is sorted', () {
    final type = _CountingTextType();
    final column = PlutoColumn(title: '', field: 'field', type: type);
    final rows = List<PlutoRow>.generate(
      100,
      (index) => PlutoRow(cells: {'field': PlutoCell(value: index)}),
    );
    PlutoGridStateManager.initializeRows([column], rows);
    expect(type.conversions, 0);
    final cell = rows.last.cells['field']!;
    expect(cell.valueForSorting, '99');
    expect(cell.valueForSorting, '99');
    expect(type.conversions, 1);
    cell.value = 101;
    expect(cell.valueForSorting, '101');
    expect(type.conversions, 2);
    cell.clear();
    cell.setColumn(column);
    expect(type.conversions, 2);
    expect(cell.valueForSorting, '101');
    expect(type.conversions, 3);
  });

  test('deferred comparison preserves the pre-format initial value', () {
    final column = PlutoColumn(
      title: '',
      field: 'number',
      type: PlutoColumnType.number(format: '#,###.0', locale: 'en'),
    );
    final cell = PlutoCell(value: '1234.567');
    final expected = column.type.makeCompareValue(cell.currentValue);
    cell.setColumn(column);
    expect(cell.valueFormatted, 1234.6);
    expect(cell.valueForSorting, expected);
    cell.value = '20.2';
    expect(cell.valueForSorting, column.type.makeCompareValue('20.2'));
  });

  test('clearing a cell releases column comparison objects before reuse', () {
    final type = _CountingTextType();
    final cell = PlutoCell(value: 7);
    cell.setColumn(PlutoColumn(title: '', field: 'text', type: type));
    expect(cell.valueForSorting, '7');
    cell.clear();
    expect(cell.valueForSorting, 7);
    cell.setColumn(
      PlutoColumn(title: '', field: 'number', type: PlutoColumnType.number()),
    );
    expect(cell.valueForSorting, 7);
  });
}

class _CountingTextType extends PlutoColumnTypeText {
  int conversions = 0;

  @override
  dynamic makeCompareValue(dynamic value) {
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
