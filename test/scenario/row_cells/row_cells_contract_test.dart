// Characterization of grids whose rows keep their cells in maps other than a
// LinkedHashMap, recorded before rows could create their cells when first
// read. Every kind of cells map must give the same lines.
import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:pluto_grid_plus/src/ui/pluto_base_cell.dart';

/// Builds the cells map of one row from its values, one per field.
typedef _CellsOf = Map<String, PlutoCell> Function(
  List<String> fields,
  List<Object?> values,
);

final Map<String, _CellsOf> _cellMaps = <String, _CellsOf>{
  'linked': (List<String> fields, List<Object?> values) => <String, PlutoCell>{
    for (int index = 0; index < fields.length; index++)
      fields[index]: PlutoCell(value: values[index]),
  },
  'indexed': (List<String> fields, List<Object?> values) => _IndexedCells(
    fields,
    <PlutoCell?>[for (final Object? value in values) PlutoCell(value: value)],
  ),
  'lazy': _LazyCells.new,
};

void main() {
  for (final MapEntry<String, _CellsOf> cellMap in _cellMaps.entries) {
    test('${cellMap.key}: table operations', () {
      _expectLines(_operations(cellMap.value), _expectedOperations);
    });

    test('${cellMap.key}: row groups', () {
      _expectLines(_rowGroups(cellMap.value), _expectedRowGroups);
    });

    testWidgets('${cellMap.key}: a mounted grid', (WidgetTester tester) async {
      _expectLines(await _mounted(tester, cellMap.value), _expectedMounted);
    });
  }

  test('lazy rows: the grid creates only the cells it reads', () {
    _LazyCells.created = 0;
    final List<String> out = <String>[];
    final _Grid g = _Grid(_LazyCells.new);
    final PlutoGridStateManager m = g.manager;
    out.add(
      'init | created ${_LazyCells.created} | initialized '
      '${m.refRows.originalListView.where((PlutoRow<dynamic> row) => row.initialized).length}',
    );
    _LazyCells.peeked = 0;
    final num? sum = PlutoAggregateHelper.sum(
      rows: m.refRows,
      column: g.column('number'),
    );
    out.add(
      'aggregated number $sum | created ${_LazyCells.created} '
      'peeked ${_LazyCells.peeked}',
    );
    m.sortAscending(g.column('number'), notify: false);
    m.sortDescending(g.column('number'), notify: false);
    out.add('sorted number twice | created ${_LazyCells.created}');
    g.filter('text', const PlutoFilterTypeContains(), 'b');
    out.add('filtered text | created ${_LazyCells.created}');
    g.filter(null, null, null);
    m.setCurrentCell(m.refRows[4].cells['date'], 4, notify: false);
    m.moveCurrentCell(PlutoMoveDirection.right, notify: false);
    out.add(
      'current cell moved | created ${_LazyCells.created} | ${_current(m)}',
    );

    final PlutoRow<dynamic> removed = m.refRows[4];
    final PlutoCell date = removed.cells['date']!;
    m.removeRows(<PlutoRow<dynamic>>[removed], notify: false);
    out.add(
      'removed row | initialized ${removed.initialized} | read cell '
      'initialized ${date.initialized} | created ${_LazyCells.created}',
    );
    m.appendRows(<PlutoRow<dynamic>>[removed]);
    out.add(
      'appended again | initialized ${removed.initialized} | '
      '${_linked(removed, 'date', m)} ${_linked(removed, 'id', m)} | '
      'same date cell ${identical(removed.cells['date'], date)}',
    );
    g.dispose();
    expect(out, <String>[
      'init | created 0 | initialized 30',
      'aggregated number 127.8 | created 0 peeked 30',
      'sorted number twice | created 30',
      'filtered text | created 60',
      // The date and select cells, and the id cell read to find their column.
      'current cell moved | created 63 | 4 select=c same=true at 4,4',
      'removed row | initialized false | read cell initialized false | created 63',
      'appended again | initialized true | linked linked | same date cell true',
    ]);
  });

  testWidgets('lazy rows: a mounted grid creates the cells it renders', (
    WidgetTester tester,
  ) async {
    const int rowCount = 1000;
    _LazyCells.created = 0;
    final List<PlutoColumn> columns = _Grid.newColumns();
    late final PlutoGridStateManager m;
    await tester.binding.setSurfaceSize(const Size(900, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: _Grid.rows(_LazyCells.new, 0, rowCount),
            onLoaded: (PlutoGridOnLoadedEvent event) => m = event.stateManager,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final List<String> out = <String>[
      'rendered | created ${_LazyCells.created}',
    ];
    m.sortDescending(columns[1]);
    await tester.pumpAndSettle();
    out.add('sorted number | created ${_LazyCells.created}');
    m.setFilterWithFilterRows(<PlutoRow<dynamic>>[
      FilterHelper.createFilterRow(
        columnField: 'select',
        filterType: const PlutoFilterTypeEquals(),
        filterValue: 'b',
      ),
    ]);
    await tester.pumpAndSettle();
    out.add('filtered select | created ${_LazyCells.created}');
    expect(out, <String>[
      // 14 built rows of five cells, out of 5000 cells.
      'rendered | created 70',
      // The other 986 number cells and four cells of each of 13 new rows.
      'sorted number | created 1108',
      // The select cells not created yet and the cells of new rows.
      'filtered select | created 2108',
    ]);
  });
}

void _expectLines(List<String> actual, List<String> expected) {
  if (expected.isEmpty) {
    // ignore: avoid_print
    print(
      actual
          .map((String line) => "  '${line.replaceAll("'", r"\'")}',")
          .join('\n'),
    );
  }
  expect(actual, expected);
}

List<String> _operations(_CellsOf cellsOf) {
  final List<String> out = <String>[];
  final List<String> changes = <String>[];
  final _Grid g = _Grid(
    cellsOf,
    onChanged: (PlutoGridOnChangedEvent event) {
      changes.add(
        'changed row=${event.rowIdx} column=${event.columnIdx} '
        '${event.value} <- ${event.oldValue}',
      );
    },
  );
  final PlutoGridStateManager m = g.manager;

  out.add(
    'initialized rows ${m.refRows.originalListView.where((PlutoRow<dynamic> row) => row.initialized).length} of ${m.refRows.originalLength}',
  );

  for (final String field in <String>['number', 'text', 'date', 'select']) {
    m.sortAscending(g.column(field), notify: false);
    out.add('asc $field | ${_ids(m.refRows)}');
    m.sortDescending(g.column(field), notify: false);
    out.add('desc $field | ${_ids(m.refRows)}');
  }
  m.sortBySortIdx(g.column('number'), notify: false);
  out.add('sortIdx | ${_ids(m.refRows)}');

  for (final (String?, PlutoFilterType?, String?) filter
      in <(String?, PlutoFilterType?, String?)>[
        ('number', const PlutoFilterTypeGreaterThan(), '4'),
        ('text', const PlutoFilterTypeContains(), 'b'),
        ('date', const PlutoFilterTypeGreaterThanOrEqualTo(), '2026-10-15'),
        ('select', const PlutoFilterTypeEquals(), 'c'),
      ]) {
    g.filter(filter.$1, filter.$2, filter.$3);
    out.add('filter ${filter.$1} ${filter.$3} | ${_ids(m.refRows)}');
  }
  out.add(
    'null numbers | ${_ids(m.refRows.originalListView.where((PlutoRow<dynamic> row) => row.cells['number']!.currentValue == null))}',
  );
  g.filter(
    FilterHelper.filterFieldAllColumns,
    const PlutoFilterTypeContains(),
    '7',
  );
  out.add('filter all columns 7 | ${_ids(m.refRows)}');
  g.filter(null, null, null);
  for (final String field in <String>['number', 'id']) {
    final PlutoColumn column = g.column(field);
    final FilteredList<PlutoRow<dynamic>> rows = m.refRows;
    out.add(
      'aggregate $field sum=${PlutoAggregateHelper.sum(rows: rows, column: column)} '
      'avg=${PlutoAggregateHelper.average(rows: rows, column: column)} '
      'min=${PlutoAggregateHelper.min(rows: rows, column: column)} '
      'max=${PlutoAggregateHelper.max(rows: rows, column: column)} '
      'count=${PlutoAggregateHelper.count(rows: rows, column: column)}',
    );
  }
  g.filter('number', const PlutoFilterTypeLessThan(), '5');
  m.sortDescending(g.column('date'), notify: false);
  out.add('filtered desc date | ${_ids(m.refRows)}');
  g.filter(null, null, null);
  m.sortBySortIdx(g.column('date'), notify: false);

  final PlutoRow<dynamic> edited = m.refRows[5];
  m.changeCellValue(edited.cells['number']!, 99, force: true);
  out.add(
    'edited ${edited.data} number=${edited.cells['number']!.currentValue} '
    'state=${edited.state.name} ${changes.join(';')}',
  );
  m.sortDescending(g.column('number'), notify: false);
  out.add('desc number after edit | ${_ids(m.refRows)}');
  m.sortBySortIdx(g.column('number'), notify: false);

  m.setCurrentCell(m.refRows[3].cells['text'], 3, notify: false);
  out.add('current ${_current(m)}');
  m.moveCurrentCell(PlutoMoveDirection.right, notify: false);
  out.add('moved right ${_current(m)}');
  m.moveCurrentCell(PlutoMoveDirection.down, notify: false);
  out.add('moved down ${_current(m)}');
  final PlutoCell other = m.refRows[12].cells['select']!;
  final PlutoGridCellPosition? position = m.cellPositionByCellKey(other.key);
  out.add('position by key ${position?.rowIdx},${position?.columnIdx}');

  m.setSelectingMode(PlutoGridSelectingMode.cell, notify: false);
  m.setCurrentCell(m.refRows[2].cells['number'], 2, notify: false);
  m.setCurrentSelectingPosition(
    cellPosition: const PlutoGridCellPosition(columnIdx: 3, rowIdx: 4),
    notify: false,
  );
  out.add('selected text | ${m.currentSelectingText.replaceAll('\n', ' / ')}');
  m.clearCurrentSelecting(notify: false);
  m.setSelectingMode(PlutoGridSelectingMode.row, notify: false);
  m.setCurrentCell(m.refRows[1].cells['id'], 1, notify: false);
  m.setCurrentSelectingRowsByRange(1, 2, notify: false);
  out.add('selected rows | ${m.currentSelectingText.replaceAll('\n', ' / ')}');
  m.clearCurrentSelecting(notify: false);
  m.setSelectingMode(PlutoGridSelectingMode.cell, notify: false);

  m.insertColumns(2, <PlutoColumn>[
    PlutoColumn(title: 'extra', field: 'extra', type: PlutoColumnType.number()),
  ]);
  final PlutoRow<dynamic> first = m.refRows.first;
  out.add(
    'inserted column | keys ${first.cells.keys.join(',')} | '
    'extra=${first.cells['extra']?.currentValue} ${_linked(first, 'extra', m)}',
  );
  m.removeColumns(<PlutoColumn>[g.column('text')]);
  out.add(
    'removed column | keys ${first.cells.keys.join(',')} | '
    'contains text ${first.cells.containsKey('text')} | text ${first.cells['text']}',
  );

  m.appendRows(g.newRows(<int>[100, 101]));
  m.insertRows(1, g.newRows(<int>[102]), notify: false);
  final List<PlutoRow<dynamic>> added = <PlutoRow<dynamic>>[
    for (final PlutoRow<dynamic> row in m.refRows)
      if ((row.data as int) >= 100) row,
  ];
  out.add(
    'added rows | ${_ids(m.refRows)} | '
    '${added.map((PlutoRow<dynamic> row) => '${row.data}:${row.initialized}:${_linked(row, 'number', m)}:${_linked(row, 'extra', m)}').join(' ')}',
  );

  final PlutoRow<dynamic> removed = m.refRows[7];
  final PlutoCell readBefore = removed.cells['number']!;
  final Key readKey = readBefore.key;
  m.removeRows(<PlutoRow<dynamic>>[removed, m.refRows[8]], notify: false);
  out.add(
    'removed rows | ${_ids(m.refRows)} | read cell initialized ${readBefore.initialized} '
    'position ${m.cellPositionByCellKey(readKey)} | unread cell initialized '
    '${removed.cells['date']?.initialized}',
  );

  int linked = 0;
  int unlinked = 0;
  for (final PlutoRow<dynamic> row in m.refRows.originalListView) {
    for (final PlutoColumn column in m.refColumns.originalList) {
      _linked(row, column.field, m) == 'linked' ? linked++ : unlinked++;
    }
  }
  out.add('links | linked $linked unlinked $unlinked');
  for (final PlutoRow<dynamic> row in m.refRows.take(4)) {
    out.add(
      'values ${row.data} | ${m.refColumns.map((PlutoColumn column) => '${column.field}=${row.cells[column.field]?.valueFormatted}/${row.cells[column.field]?.valueForSorting}').join(' ')}',
    );
  }
  g.dispose();
  return out;
}

List<String> _rowGroups(_CellsOf cellsOf) {
  final List<String> out = <String>[];
  final _Grid g = _Grid(cellsOf);
  final PlutoGridStateManager m = g.manager;
  m.setRowGroup(
    PlutoRowGroupByColumnDelegate(columns: <PlutoColumn>[g.column('select')]),
  );
  for (final PlutoRow<dynamic> group in m.iterateAllRowGroup) {
    out.add(
      'group ${group.cells['select']?.currentValue} | '
      'keys ${group.cells.keys.join(',')} | '
      'children ${_ids(group.type.group.children)}',
    );
  }
  m.toggleExpandedRowGroup(rowGroup: m.refRows.first, notify: false);
  m.sortAscending(g.column('number'), notify: false);
  out.add(
    'expanded first, asc number | ${m.refRows.map((PlutoRow<dynamic> row) => row.type.isGroup ? 'g:${row.cells['select']?.currentValue}' : '${row.data}').join(',')}',
  );
  int linked = 0;
  for (final PlutoRow<dynamic> row in m.iterateAllRow) {
    for (final PlutoColumn column in m.refColumns.originalList) {
      if (_linked(row, column.field, m) == 'linked') {
        linked++;
      }
    }
  }
  out.add('links in group children | $linked');
  g.dispose();
  return out;
}

Future<List<String>> _mounted(WidgetTester tester, _CellsOf cellsOf) async {
  final List<String> out = <String>[];
  final List<PlutoColumn> columns = _Grid.newColumns();
  // Footers read one column of every row.
  const Map<String, PlutoAggregateColumnType> footerTypes =
      <String, PlutoAggregateColumnType>{
        'id': PlutoAggregateColumnType.average,
        'number': PlutoAggregateColumnType.sum,
        'text': PlutoAggregateColumnType.count,
        'select': PlutoAggregateColumnType.uniqueCount,
      };
  for (final PlutoColumn column in columns) {
    final PlutoAggregateColumnType? type = footerTypes[column.field];
    if (type != null) {
      column.footerRenderer = (PlutoColumnFooterRendererContext context) =>
          PlutoAggregateColumnFooter(
            rendererContext: context,
            type: type,
            format: '#,###.##',
          );
    }
  }
  final List<PlutoRow<dynamic>> rows = _Grid.rows(cellsOf, 0, _Grid.rowCount);
  late final PlutoGridStateManager m;
  await tester.binding.setSurfaceSize(const Size(900, 400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Material(
        child: PlutoGrid(
          columns: columns,
          rows: rows,
          onLoaded: (PlutoGridOnLoadedEvent event) => m = event.stateManager,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  String rendered() {
    final List<PlutoBaseCell> cells = tester
        .widgetList<PlutoBaseCell>(find.byType(PlutoBaseCell))
        .toList();
    final int same = cells
        .where(
          (PlutoBaseCell cell) =>
              identical(cell.cell, cell.row.cells[cell.column.field]) &&
              identical(cell.cell.row, cell.row) &&
              identical(cell.cell.column, cell.column),
        )
        .length;
    final List<String> texts = <String>[
      for (final PlutoBaseCell cell in cells)
        if (cell.rowIdx < 3)
          '${cell.row.data}:${cell.column.field}=${cell.cell.valueFormatted}',
    ]..sort();
    return 'rendered ${cells.length} cells, $same linked | ${texts.join(' ')}';
  }

  String footers() => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(PlutoAggregateColumnFooter),
          matching: find.byType(Text),
        ),
      )
      .map((Text text) => text.textSpan?.toPlainText() ?? text.data)
      .join(' ');

  out
    ..add(rendered())
    ..add('footers | ${footers()}');
  await tester.tap(find.text('item f1'));
  await tester.pump();
  out.add('tapped ${_current(m)}');
  m.sortDescending(columns[1]);
  await tester.pumpAndSettle();
  out.add('desc number | ${rendered()}');
  m.setFilterWithFilterRows(<PlutoRow<dynamic>>[
    FilterHelper.createFilterRow(
      columnField: 'select',
      filterType: const PlutoFilterTypeEquals(),
      filterValue: 'b',
    ),
  ]);
  await tester.pumpAndSettle();
  out
    ..add('filter select b | ${rendered()}')
    ..add('filtered footers | ${footers()}');
  return out;
}

String _ids(Iterable<PlutoRow<dynamic>> rows) =>
    rows.map((PlutoRow<dynamic> row) => row.data).join(',');

String _current(PlutoGridStateManager m) {
  final PlutoCell? cell = m.currentCell;
  final PlutoGridCellPosition? position = m.currentCellPosition;
  if (cell == null || position == null) {
    return 'none';
  }
  final PlutoRow<dynamic> row = m.refRows[position.rowIdx!];
  final PlutoColumn column = m.refColumns[position.columnIdx!];
  return '${row.data} ${column.field}=${cell.valueFormatted} '
      'same=${identical(cell, row.cells[column.field])} '
      'at ${position.rowIdx},${position.columnIdx}';
}

String _linked(PlutoRow<dynamic> row, String field, PlutoGridStateManager m) {
  final PlutoCell? cell = row.cells[field];
  if (cell == null) {
    return 'missing';
  }
  if (!cell.initialized) {
    return 'uninitialized';
  }
  final PlutoColumn? column = m.refColumns.originalList
      .where((PlutoColumn column) => column.field == field)
      .firstOrNull;
  return identical(cell.column, column) && identical(cell.row, row)
      ? 'linked'
      : 'other';
}

class _Grid {
  _Grid(this.cellsOf, {PlutoOnChangedEventCallback? onChanged}) {
    manager = PlutoGridStateManager(
      columns: columns,
      rows: rows(cellsOf, 0, rowCount),
      gridFocusNode: _focus,
      scroll: PlutoGridScrollController(),
      onChanged: onChanged,
    );
  }

  static const int rowCount = 30;
  static const List<String> fields = <String>[
    'id',
    'number',
    'text',
    'date',
    'select',
  ];

  final _CellsOf cellsOf;
  final FocusNode _focus = FocusNode();
  final List<PlutoColumn> columns = newColumns();
  late final PlutoGridStateManager manager;

  static List<PlutoColumn> newColumns() => <PlutoColumn>[
    PlutoColumn(title: 'id', field: 'id', type: PlutoColumnType.number()),
    PlutoColumn(
      title: 'number',
      field: 'number',
      type: PlutoColumnType.number(format: '#,###.#'),
    ),
    PlutoColumn(title: 'text', field: 'text', type: PlutoColumnType.text()),
    PlutoColumn(
      title: 'date',
      field: 'date',
      type: PlutoColumnType.date(format: 'yyyy-MM-dd'),
    ),
    PlutoColumn(
      title: 'select',
      field: 'select',
      type: PlutoColumnType.select(<String>['a', 'b', 'c']),
    ),
  ];

  static List<Object?> valuesOf(int id) => <Object?>[
    id,
    id % 11 == 0 ? null : (id * 7) % 10 + (id % 4) / 10,
    'item ${String.fromCharCode(97 + (id * 5) % 26)}${id % 3}',
    '2026-10-${'${1 + (id * 3) % 28}'.padLeft(2, '0')}',
    <String>['a', 'b', 'c'][(id * 2) % 3],
  ];

  static List<PlutoRow<dynamic>> rows(_CellsOf cellsOf, int from, int to) =>
      <PlutoRow<dynamic>>[
        for (int id = from; id < to; id++)
          PlutoRow<dynamic>(cells: cellsOf(fields, valuesOf(id)), data: id),
      ];

  List<PlutoRow<dynamic>> newRows(List<int> ids) => <PlutoRow<dynamic>>[
    for (final int id in ids)
      PlutoRow<dynamic>(cells: cellsOf(fields, valuesOf(id)), data: id),
  ];

  PlutoColumn column(String field) => columns.firstWhere(
    (PlutoColumn column) => column.field == field,
  );

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

/// Cells created from the row's values when first read.
class _LazyCells extends MapBase<String, PlutoCell> implements PlutoLazyCells {
  _LazyCells(this._fields, this._values)
    : _cells = List<PlutoCell?>.filled(_fields.length, null);

  /// Cells created by all lazy rows.
  static int created = 0;

  /// Cells made for one read and not kept.
  static int peeked = 0;

  /// Marks the cell of a removed field.
  static final PlutoCell _removed = PlutoCell();

  final List<String> _fields;
  final List<Object?> _values;
  final List<PlutoCell?> _cells;
  final Map<String, PlutoCell> _extra = <String, PlutoCell>{};
  PlutoRow<dynamic>? _row;
  Map<String, PlutoColumn>? _columns;

  @override
  bool get bound => _row != null;

  @override
  void bind(PlutoRow<dynamic> row, Map<String, PlutoColumn> columns) {
    _row = row;
    _columns = columns;
    for (int index = 0; index < _fields.length; index++) {
      final PlutoCell? cell = _cells[index];
      if (cell != null && !identical(cell, _removed)) {
        _link(_fields[index], cell);
      }
    }
    _extra.forEach(_link);
  }

  @override
  void unbind() {
    for (final PlutoCell cell in createdCells) {
      cell.clear();
    }
    _row = null;
    _columns = null;
  }

  @override
  Iterable<PlutoCell> get createdCells => <PlutoCell>[
    for (final PlutoCell? cell in _cells)
      if (cell != null && !identical(cell, _removed)) cell,
    ..._extra.values,
  ];

  @override
  PlutoCell? peek(String field) {
    final int index = _fields.indexOf(field);
    if (index < 0) {
      return _extra[field];
    }
    final PlutoCell? cell = _cells[index];
    if (cell != null) {
      return identical(cell, _removed) ? null : cell;
    }
    peeked++;
    final PlutoCell peekedCell = PlutoCell(value: _values[index]);
    final PlutoColumn? column = _columns?[field];
    if (column != null) {
      peekedCell.setColumn(column);
    }
    return peekedCell;
  }

  void _link(String field, PlutoCell cell) {
    final PlutoRow<dynamic>? row = _row;
    final PlutoColumn? column = _columns?[field];
    if (row != null && column != null) {
      cell
        ..setColumn(column)
        ..setRow(row);
    }
  }

  @override
  PlutoCell? operator [](Object? key) {
    final int index = _fields.indexOf(key as String? ?? '');
    if (index < 0) {
      return _extra[key];
    }
    final PlutoCell? cell = _cells[index];
    if (cell != null) {
      return identical(cell, _removed) ? null : cell;
    }
    created++;
    final PlutoCell newCell = _cells[index] = PlutoCell(value: _values[index]);
    _link(_fields[index], newCell);
    return newCell;
  }

  @override
  void operator []=(String key, PlutoCell value) {
    final int index = _fields.indexOf(key);
    if (index < 0) {
      _extra[key] = value;
    } else {
      _cells[index] = value;
    }
  }

  @override
  bool containsKey(Object? key) {
    final int index = _fields.indexOf(key as String? ?? '');
    return index < 0
        ? _extra.containsKey(key)
        : !identical(_cells[index], _removed);
  }

  @override
  void clear() {
    _cells.fillRange(0, _cells.length, _removed);
    _extra.clear();
  }

  @override
  Iterable<String> get keys => <String>[
    for (int index = 0; index < _fields.length; index++)
      if (!identical(_cells[index], _removed)) _fields[index],
    ..._extra.keys,
  ];

  @override
  PlutoCell? remove(Object? key) {
    final int index = _fields.indexOf(key as String? ?? '');
    if (index < 0) {
      return _extra.remove(key);
    }
    final PlutoCell? removed = this[key];
    _cells[index] = _removed;
    return removed;
  }
}

/// Cells by position in a field list shared by the rows, with an overflow map
/// for other fields, like ASO.dev's row cells.
class _IndexedCells extends MapBase<String, PlutoCell> {
  _IndexedCells(this._fields, this._cells);

  final List<String> _fields;
  final List<PlutoCell?> _cells;
  final Map<String, PlutoCell> _extra = <String, PlutoCell>{};

  @override
  PlutoCell? operator [](Object? key) {
    final int index = _fields.indexOf(key as String? ?? '');
    return index < 0 ? _extra[key] : _cells[index];
  }

  @override
  void operator []=(String key, PlutoCell value) {
    final int index = _fields.indexOf(key);
    if (index < 0) {
      _extra[key] = value;
    } else {
      _cells[index] = value;
    }
  }

  @override
  void clear() {
    _cells.fillRange(0, _cells.length, null);
    _extra.clear();
  }

  @override
  Iterable<String> get keys => <String>[
    for (int index = 0; index < _fields.length; index++)
      if (_cells[index] != null) _fields[index],
    ..._extra.keys,
  ];

  @override
  PlutoCell? remove(Object? key) {
    final int index = _fields.indexOf(key as String? ?? '');
    if (index < 0) {
      return _extra.remove(key);
    }
    final PlutoCell? removed = _cells[index];
    _cells[index] = null;
    return removed;
  }
}

const List<String> _expectedOperations = <String>[
  'initialized rows 30 of 30',
  'asc number | 0,11,20,22,10,13,3,23,16,6,26,9,29,19,12,2,5,25,15,8,28,18,1,21,4,24,14,17,7,27',
  'desc number | 7,27,17,14,4,24,1,21,18,8,28,15,5,25,2,12,19,9,29,6,26,16,3,23,13,10,0,11,20,22',
  'asc text | 0,26,21,16,11,6,27,1,22,17,12,7,28,2,23,18,13,8,3,29,24,19,14,9,4,25,20,15,10,5',
  'desc text | 5,10,15,20,25,4,9,14,19,24,29,3,8,13,18,23,2,28,7,12,17,22,1,27,6,11,16,21,26,0',
  'asc date | 28,0,19,10,29,1,20,11,2,21,12,3,22,13,4,23,14,5,24,15,6,25,16,7,26,17,8,27,18,9',
  'desc date | 9,18,27,8,17,26,7,16,25,6,15,24,5,14,23,4,13,22,3,12,21,2,11,20,29,1,10,19,28,0',
  'asc select | 9,18,27,6,15,24,3,12,21,0,8,17,26,5,14,23,2,11,20,29,7,16,25,4,13,22,1,10,19,28',
  'desc select | 7,16,25,4,13,22,1,10,19,28,8,17,26,5,14,23,2,11,20,29,9,18,27,6,15,24,3,12,21,0',
  'sortIdx | 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29',
  'filter number 4 | 1,2,4,5,7,8,14,15,17,18,21,24,25,27,28',
  'filter text b | 21',
  'filter date 2026-10-15 | 5,6,7,8,9,14,15,16,17,18,24,25,26,27',
  'filter select c | 1,4,7,10,13,16,19,22,25,28',
  'null numbers | 0,11,22',
  'filter all columns 7 | 1,2,7,17,18,21,24,27',
  'aggregate number sum=127.8 avg=4.7 min=0.0 max=9.3 count=30',
  'aggregate id sum=435 avg=15 min=0 max=29 count=30',
  'filtered desc date | 9,26,16,6,23,13,22,3,12,2,11,20,29,10,19,0',
  'edited 5 number=99 state=updated changed row=5 column=1 99 <- 5.1',
  'desc number after edit | 5,7,27,17,14,4,24,1,21,18,8,28,15,25,2,12,19,9,29,6,26,16,3,23,13,10,0,11,20,22',
  'current 3 text=item p0 same=true at 3,2',
  'moved right 3 date=2026-10-10 same=true at 3,3',
  'moved down 4 date=2026-10-13 same=true at 4,3',
  'position by key 12,4',
  'selected text | 4.2	item k2	2026-10-07 / 1.3	item p0	2026-10-10 / 8	item u1	2026-10-13',
  'selected rows | 1	7.1	item f1	2026-10-04	c / 2	4.2	item k2	2026-10-07	b',
  'inserted column | keys id,number,text,date,select,extra | extra=0 linked',
  'removed column | keys id,number,date,select,extra | contains text false | text null',
  'added rows | 0,102,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,100,101 | 102:true:linked:missing 100:true:linked:missing 101:true:linked:missing',
  'removed rows | 0,102,1,2,3,4,5,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,100,101 | read cell initialized false position null | unread cell initialized false',
  'links | linked 152 unlinked 3',
  'values 0 | id=0/0 number=0/0 extra=0/0 date=2026-10-01/2026-10-01 00:00:00.000 select=a/a',
  'values 102 | id=102/102 number=4.2/4.2 extra=null/null date=2026-10-27/2026-10-27 00:00:00.000 select=a/a',
  'values 1 | id=1/1 number=7.1/7.1 extra=0/0 date=2026-10-04/2026-10-04 00:00:00.000 select=c/c',
  'values 2 | id=2/2 number=4.2/4.2 extra=0/0 date=2026-10-07/2026-10-07 00:00:00.000 select=b/b',
];

const List<String> _expectedRowGroups = <String>[
  'group a | keys id,number,text,date,select | children 0,3,6,9,12,15,18,21,24,27',
  'group c | keys id,number,text,date,select | children 1,4,7,10,13,16,19,22,25,28',
  'group b | keys id,number,text,date,select | children 2,5,8,11,14,17,20,23,26,29',
  'expanded first, asc number | g:a,0,3,6,9,12,15,18,21,24,27,g:c,g:b',
  'links in group children | 150',
];

const List<String> _expectedMounted = <String>[
  'rendered 35 cells, 35 linked | 0:date=2026-10-01 0:id=0 0:number=0 0:select=a 0:text=item a0 1:date=2026-10-04 1:id=1 1:number=7.1 1:select=c 1:text=item f1 2:date=2026-10-07 2:id=2 2:number=4.2 2:select=b 2:text=item k2',
  'footers | 15 127.8 30 3',
  'tapped 1 text=item f1 same=true at 1,2',
  'desc number | rendered 35 cells, 35 linked | 17:date=2026-10-24 17:id=17 17:number=9.1 17:select=b 17:text=item h2 27:date=2026-10-26 27:id=27 27:number=9.3 27:select=a 27:text=item f0 7:date=2026-10-22 7:id=7 7:number=9.3 7:select=c 7:text=item j1',
  'filter select b | rendered 35 cells, 35 linked | 14:date=2026-10-15 14:id=14 14:number=8.2 14:select=b 14:text=item s2 17:date=2026-10-24 17:id=17 17:number=9.1 17:select=b 17:text=item h2 8:date=2026-10-25 8:id=8 8:number=6 8:select=b 8:text=item o2',
  'filtered footers | 16 39.2 10 1',
];
