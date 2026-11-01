// Characterization of row order after sorting, filtering, paging, row groups
// and list changes under a filter, recorded before sorting and filtering were
// reworked. Equal values keep the order the sort algorithm gave them.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  test('row order after sorting, filtering and list changes', () {
    final List<String> out = <String>[];
    final _Grid g = _Grid();
    String ids(Iterable<PlutoRow<dynamic>> rows) =>
        rows.map(_Grid.id).join(',');

    for (final PlutoColumn column in g.columns.skip(1)) {
      g.manager.sortAscending(column, notify: false);
      out.add('asc ${column.field} | ${ids(g.manager.refRows)}');
      g.manager.sortDescending(column, notify: false);
      out.add('desc ${column.field} | ${ids(g.manager.refRows)}');
    }
    g.manager.sortBySortIdx(g.columns[1], notify: false);
    out.add('sortIdx | ${ids(g.manager.refRows)}');

    g.filter('number', const PlutoFilterTypeGreaterThan(), '3');
    out.add('filter number>3 | ${ids(g.manager.refRows)}');
    out.add(
      'states after filter | ${g.manager.refRows.originalListView.map((PlutoRow<dynamic> r) => r.state.name).toSet().join(',')}',
    );
    g.manager.sortAscending(g.columns[2], notify: false);
    out.add(
      'filtered asc text | ${ids(g.manager.refRows)} | original ${ids(g.manager.refRows.originalListView)}',
    );
    g.manager.sortDescending(g.columns[3], notify: false);
    out.add('filtered desc date | ${ids(g.manager.refRows)}');

    // An edited row that no longer matches stays visible.
    final PlutoRow<dynamic> edited = g.manager.refRows.first;
    g.manager.changeCellValue(edited.cells['number']!, 0, force: true);
    out.add(
      'after edit state=${edited.state.name} visible=${g.manager.refRows.contains(edited)}',
    );
    g.manager.appendRows(_Grid.newRows(<int>[1, 9, 5]));
    out.add('append under filter | ${ids(g.manager.refRows)}');
    g.manager.insertRows(2, _Grid.newRows(<int>[8, 2]), notify: false);
    out.add('insert under filter | ${ids(g.manager.refRows)}');
    g.manager.removeRows(<PlutoRow<dynamic>>[
      g.manager.refRows[3],
      g.manager.refRows.last,
    ], notify: false);
    out.add(
      'remove under filter | ${ids(g.manager.refRows)} | original ${ids(g.manager.refRows.originalListView)}',
    );
    g.manager.sortAscending(g.columns[1], notify: false);
    out.add('filtered asc number after changes | ${ids(g.manager.refRows)}');
    g.manager.toggleAllRowChecked(true, notify: false);
    out.add(
      'checked under filter | ${g.manager.checkedRows.length} of ${g.manager.refRows.originalLength}',
    );
    g.filter(null, null, null);
    out.add('filter cleared | ${ids(g.manager.refRows)}');
    out.add(
      'states after clear | ${g.manager.refRows.originalListView.map((PlutoRow<dynamic> r) => r.state.name).toSet().join(',')}',
    );

    // Pagination.
    final _Grid p = _Grid();
    p.manager.setPageSize(25, notify: false);
    p.manager.setPage(2, notify: false);
    out.add('page 2 | ${ids(p.manager.refRows)}');
    p.manager.sortDescending(p.columns[1], notify: false);
    out.add('page 2 desc number | ${ids(p.manager.refRows)}');
    p.filter('text', const PlutoFilterTypeContains(), 'b');
    out.add(
      'page after filter text~b | page ${p.manager.page} | ${ids(p.manager.refRows)}',
    );
    p.manager.sortAscending(p.columns[3], notify: false);
    out.add('page filtered asc date | ${ids(p.manager.refRows)}');

    // Row groups by the select column.
    final _Grid r = _Grid();
    r.manager.setRowGroup(
      PlutoRowGroupByColumnDelegate(columns: <PlutoColumn>[r.columns[4]]),
    );
    String groups() => r.manager.iterateAllRowAndGroup
        .map(
          (PlutoRow<dynamic> row) => row.type.isGroup
              ? 'G(${row.cells['select']!.currentValue})'
              : _Grid.id(row),
        )
        .join(',');
    out.add('groups | ${groups()}');
    r.manager.sortAscending(r.columns[1], notify: false);
    out.add('groups asc number | ${groups()}');
    r.manager.sortDescending(r.columns[2], notify: false);
    out.add('groups desc text | ${groups()}');
    r.filter('number', const PlutoFilterTypeLessThan(), '4');
    out.add(
      'groups filtered | ${r.manager.refRows.map((PlutoRow<dynamic> row) => row.type.isGroup ? 'G' : _Grid.id(row)).join(',')}',
    );

    expect(out, _Expected.lines);
    g.dispose();
    p.dispose();
    r.dispose();
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

  static int _next = 1000;

  static String id(PlutoRow<dynamic> row) => '${row.cells['id']!.currentValue}';

  static List<PlutoRow<dynamic>> newRows(List<int> numbers) =>
      <PlutoRow<dynamic>>[
        for (final int number in numbers) _row(_next++, number),
      ];

  static PlutoRow<dynamic> _row(int id, int number) => PlutoRow<dynamic>(
    cells: <String, PlutoCell>{
      'id': PlutoCell(value: id),
      'number': PlutoCell(value: number == 6 ? null : number + (id % 3) / 10),
      'text': PlutoCell(value: <String>['b', 'a', 'B', 'ab', 'b2', ''][id % 6]),
      'date': PlutoCell(value: '2026-01-0${1 + id % 5}'),
      'select': PlutoCell(value: <String>['x', 'y', 'z'][id % 3]),
    },
  );

  final FocusNode _focus = FocusNode();
  final List<PlutoColumn> columns = <PlutoColumn>[
    PlutoColumn(title: 'id', field: 'id', type: PlutoColumnType.number()),
    PlutoColumn(
      title: 'number',
      field: 'number',
      type: PlutoColumnType.number(format: '#,###.0', locale: 'en'),
    ),
    PlutoColumn(title: 'text', field: 'text', type: PlutoColumnType.text()),
    PlutoColumn(title: 'date', field: 'date', type: PlutoColumnType.date()),
    PlutoColumn(
      title: 'select',
      field: 'select',
      type: PlutoColumnType.select(<String>['z', 'x', 'y']),
    ),
  ];
  late final List<PlutoRow<dynamic>> rows = <PlutoRow<dynamic>>[
    for (int index = 0; index < 120; index++) _row(index, index % 7),
  ];
  late final PlutoGridStateManager manager;

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

class _Expected {
  static const List<String> lines = <String>[
    r'asc number | 41,118,6,13,105,111,20,21,27,84,34,76,0,104,97,42,48,90,83,55,69,62,63,7,112,28,49,91,70,14,98,35,77,119,56,99,15,36,57,78,64,1,85,43,106,22,29,113,50,8,71,92,30,51,9,72,93,114,100,16,58,79,37,2,44,107,86,65,23,66,24,3,87,45,108,52,31,73,94,10,115,101,17,38,80,59,102,60,81,39,18,4,88,67,46,25,109,11,53,32,74,95,116,54,33,96,12,117,75,61,103,40,82,19,89,47,110,26,5,68',
    r'desc number | 68,5,26,110,47,89,19,82,40,103,61,12,117,75,96,33,54,116,95,74,32,53,11,109,25,4,67,88,46,18,39,81,60,102,59,80,38,101,17,10,115,94,73,52,31,66,108,45,87,3,24,23,65,2,44,107,86,100,16,58,79,37,30,51,72,93,114,9,92,71,8,50,29,113,22,106,43,85,1,64,99,15,36,57,78,56,119,77,35,98,14,70,91,49,28,112,7,63,62,69,55,83,90,48,42,97,104,41,76,34,84,27,21,20,111,105,13,6,118,0',
    r'asc text | 29,35,47,89,41,53,83,95,5,11,59,119,23,71,107,77,17,101,113,65,38,98,14,68,62,50,56,32,74,80,44,116,86,110,20,92,26,8,104,2,79,43,85,1,31,73,115,13,67,25,91,49,7,109,55,61,97,103,19,37,69,99,63,51,93,9,27,117,75,33,105,111,21,15,57,39,45,87,3,81,6,54,36,30,78,84,102,108,114,96,72,60,24,42,48,90,0,12,66,18,118,46,112,28,88,70,100,16,76,34,82,40,52,10,4,94,106,22,64,58',
    r'desc text | 100,64,22,106,94,4,10,52,40,82,34,76,16,70,88,28,112,46,118,58,18,66,6,54,36,12,78,84,102,108,114,96,72,60,24,42,48,90,0,30,81,33,21,27,69,39,57,15,87,111,45,105,3,75,117,9,93,51,63,99,43,37,19,103,97,61,79,85,109,7,49,25,55,13,115,73,31,1,67,91,14,68,62,50,56,32,74,80,44,116,86,110,20,92,26,8,104,2,98,38,65,113,101,17,77,107,71,23,119,59,11,5,95,83,53,41,89,47,35,29',
    r'asc date | 20,35,10,40,70,30,95,5,60,90,0,100,15,45,105,75,85,25,55,115,65,50,80,110,91,36,96,106,11,66,76,81,21,71,16,111,51,61,101,26,46,31,1,41,56,6,116,86,87,2,47,117,107,97,37,77,42,82,17,112,7,52,67,92,57,22,32,62,72,27,12,102,118,13,58,73,33,53,103,43,98,68,48,113,23,63,93,108,8,28,3,83,88,78,18,38,104,74,14,99,29,49,109,79,19,9,39,69,119,59,24,114,84,54,34,4,89,94,64,44',
    r'desc date | 44,64,94,89,4,34,54,84,114,24,59,119,69,39,9,19,79,109,49,29,99,14,74,104,43,18,78,88,83,3,28,8,108,93,63,23,113,48,68,38,98,103,53,33,73,58,13,118,112,2,47,117,107,97,37,77,42,82,17,87,7,52,67,92,57,22,32,62,72,27,102,12,86,116,6,56,41,1,31,91,46,101,61,51,111,16,71,21,81,76,66,11,106,96,36,26,110,80,50,65,115,55,25,85,75,105,45,15,100,0,90,60,5,95,30,70,40,10,35,20',
    r'asc select | 65,107,89,95,5,59,119,44,29,38,14,74,104,35,83,8,23,113,68,116,86,101,41,62,11,20,32,47,56,2,26,92,110,80,53,71,17,50,77,98,78,48,63,33,93,108,75,36,96,3,105,117,18,45,66,15,42,81,0,99,21,90,111,60,57,51,39,69,72,27,102,12,24,114,6,84,54,30,9,87,112,1,61,22,67,16,52,7,82,76,37,97,106,46,118,13,58,73,103,91,115,55,25,85,28,31,43,49,100,109,79,19,34,4,94,70,40,10,64,88',
    r'desc select | 37,91,88,112,1,61,22,67,16,52,7,82,76,64,97,106,46,118,13,58,73,103,115,55,25,10,28,31,43,49,100,109,79,19,34,4,94,70,40,85,87,39,63,33,93,108,75,36,96,3,105,117,18,45,66,15,42,81,0,99,21,90,111,60,57,51,48,69,72,27,102,12,24,114,6,84,54,30,9,78,95,5,59,119,44,29,38,14,74,104,35,83,89,23,113,68,116,107,101,98,41,62,11,20,32,47,56,2,26,92,110,80,53,71,17,50,77,65,8,86',
    r'sortIdx | 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119',
    r'filter number>3 | 4,5,10,11,12,17,18,19,25,26,31,32,33,38,39,40,46,47,52,53,54,59,60,61,67,68,73,74,75,80,81,82,88,89,94,95,96,101,102,103,109,110,115,116,117',
    r'states after filter | none',
    r'filtered asc text | 5,11,17,59,101,95,47,53,89,116,26,32,38,110,68,80,74,103,73,115,19,67,25,31,109,61,117,81,33,75,39,60,54,96,12,102,18,40,46,94,52,88,10,82,4 | original 119,5,11,113,17,59,23,107,29,35,101,41,95,47,53,89,65,83,71,77,20,98,116,26,8,104,32,38,2,44,50,92,14,56,110,68,80,86,62,74,103,73,115,37,19,97,43,7,67,85,13,49,25,31,109,91,55,61,1,79,87,57,51,63,93,111,3,45,21,69,117,99,81,9,33,75,105,27,15,39,0,72,84,66,48,60,90,54,96,42,12,114,24,78,30,102,18,108,36,6,100,40,46,34,94,76,106,52,58,22,88,16,112,28,70,10,82,4,118,64',
    r'filtered desc date | 39,59,4,89,74,54,19,94,109,38,33,18,68,88,103,73,53,67,52,47,102,32,12,82,17,117,81,61,46,31,26,96,116,101,11,60,40,75,25,115,80,110,10,95,5',
    r'after edit state=updated visible=true',
    r'append under filter | 39,59,4,89,74,54,19,94,109,38,33,18,68,88,103,73,53,67,52,47,102,32,12,82,17,117,81,61,46,31,26,96,116,101,11,60,40,75,25,115,80,110,10,95,5,1000,1001,1002',
    r'insert under filter | 39,59,1003,1004,4,89,74,54,19,94,109,38,33,18,68,88,103,73,53,67,52,47,102,32,12,82,17,117,81,61,46,31,26,96,116,101,11,60,40,75,25,115,80,110,10,95,5,1000,1001,1002',
    r'remove under filter | 39,59,1003,4,89,74,54,19,94,109,38,33,18,68,88,103,73,53,67,52,47,102,32,12,82,17,117,81,61,46,31,26,96,116,101,11,60,40,75,25,115,80,110,10,95,5,1000,1001 | original 79,64,39,119,69,59,99,29,1003,4,24,114,9,104,89,14,74,54,84,34,44,19,94,109,49,93,78,63,38,98,33,3,43,118,18,108,68,88,48,113,83,103,73,53,13,23,58,8,28,67,97,37,22,52,62,92,72,27,112,2,47,87,57,102,32,42,77,12,82,107,17,117,7,81,76,111,1,61,106,46,51,36,91,31,66,86,16,56,26,96,116,71,41,101,11,21,6,90,60,0,20,100,40,15,105,75,45,55,25,85,115,80,110,50,65,70,10,95,35,5,1000,1001,30',
    r'filtered asc number after changes | 39,1000,73,31,115,94,52,10,17,59,80,38,101,81,18,60,102,25,88,46,4,67,109,53,11,32,116,74,95,12,33,75,54,117,96,19,61,82,40,103,26,47,68,89,5,110,1003,1001',
    r'checked under filter | 48 of 123',
    r'filter cleared | 118,55,39,105,69,20,0,90,6,21,104,84,34,111,76,42,63,27,62,48,41,83,97,13,70,91,49,112,28,7,56,35,119,98,77,14,99,57,78,15,36,43,22,1,106,85,1000,64,50,29,71,113,8,92,9,114,30,93,51,72,37,100,58,79,16,44,65,107,23,86,2,24,66,3,108,87,45,73,31,115,94,52,10,17,59,80,38,101,81,18,60,102,25,88,46,4,67,109,53,11,32,116,74,95,12,33,75,54,117,96,19,61,82,40,103,26,47,68,89,5,110,1003,1001',
    r'states after clear | none',
    r'page 2 | 25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49',
    r'page 2 desc number | 67,25,4,88,102,60,39,18,81,59,38,80,17,101,115,31,52,73,10,94,3,87,108,24,45',
    r'page after filter text~b | page 2 | 10,94,3,87,108,24,45,66,86,2,44,16,100,58,9,114,30,72,93,51,92,50,8,64,22',
    r'page filtered asc date | 21,86,66,96,56,111,36,52,117,2,57,62,102,42,87,27,12,72,22,82,92,112,32,118,8',
    r'groups | G(x),0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54,57,60,63,66,69,72,75,78,81,84,87,90,93,96,99,102,105,108,111,114,117,G(y),1,4,7,10,13,16,19,22,25,28,31,34,37,40,43,46,49,52,55,58,61,64,67,70,73,76,79,82,85,88,91,94,97,100,103,106,109,112,115,118,G(z),2,5,8,11,14,17,20,23,26,29,32,35,38,41,44,47,50,53,56,59,62,65,68,71,74,77,80,83,86,89,92,95,98,101,104,107,110,113,116,119',
    r'groups asc number | G(x),90,6,21,27,111,0,42,48,63,69,105,84,99,15,57,78,36,51,9,72,30,114,93,45,3,108,24,66,87,39,60,81,102,18,96,117,54,33,12,75,G(y),13,76,34,55,118,97,112,7,28,49,70,91,22,1,43,64,85,106,100,58,37,79,16,10,73,94,52,31,115,67,4,25,88,46,109,61,82,40,103,19,G(z),41,20,104,62,83,14,35,98,56,77,119,113,8,29,50,92,71,107,23,2,44,65,86,17,101,38,80,59,53,95,32,11,116,74,68,89,47,26,110,5',
    r'groups desc text | G(x),72,6,12,54,96,0,42,48,102,60,66,84,24,90,114,78,36,30,108,18,51,57,93,45,3,75,99,105,87,39,69,81,63,15,111,117,27,33,21,9,G(y),58,76,34,40,118,82,112,88,28,4,70,52,22,10,16,64,94,106,100,46,37,79,43,13,73,19,91,31,115,67,49,25,7,1,109,61,97,55,103,85,G(z),74,20,104,62,14,2,98,56,8,50,92,38,110,32,26,68,80,86,44,116,23,65,107,17,101,5,71,59,53,95,41,11,113,29,119,89,47,77,83,35',
    r'groups filtered | G,G,G',
  ];
}
