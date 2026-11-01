// Characterization of every filter type on unrendered cells, recorded before
// filter conversions were optimized. One line per column kind and filter type:
// search => indexes of the rows the filter keeps.
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  test('rows kept by each filter type', () {
    final List<String> actual = <String>[];
    final Map<String, PlutoFilterType> filters = {
      'contains': const PlutoFilterTypeContains(),
      'notContains': const PlutoFilterTypeNotContains(),
      'equals': const PlutoFilterTypeEquals(),
      'notEquals': const PlutoFilterTypeNotEquals(),
      'startsWith': const PlutoFilterTypeStartsWith(),
      'endsWith': const PlutoFilterTypeEndsWith(),
      'greaterThan': const PlutoFilterTypeGreaterThan(),
      'greaterThanOrEqualTo': const PlutoFilterTypeGreaterThanOrEqualTo(),
      'lessThan': const PlutoFilterTypeLessThan(),
      'lessThanOrEqualTo': const PlutoFilterTypeLessThanOrEqualTo(),
      'between': const PlutoFilterTypeBetween(),
      'isEmpty': const PlutoFilterTypeIsEmpty(),
      'isNotEmpty': const PlutoFilterTypeIsNotEmpty(),
      'containsSet': const PlutoFilterTypeContainsSet(),
      'notContainsSet': const PlutoFilterTypeNotContainsSet(),
      'isEmptySet': const PlutoFilterTypeIsEmptySet(),
      'isNotEmptySet': const PlutoFilterTypeIsNotEmptySet(),
    };
    final Map<
      String,
      (PlutoColumnType, List<Object?>, List<Object?>, List<String>)
    >
    data = {
      // type, cell values, cell filterValues, searches
      'text': (
        PlutoColumnType.text(),
        ['Apple', 'apple pie', 'Banana', '', null, 'a.b', 'A(1)'],
        [null, null, null, null, null, null, null],
        ['apple', 'A', 'a.b', '(1)', 'ban,app', 'B', ''],
      ),
      'number': (
        PlutoColumnType.number(),
        [5, 10, 1234.5, -3, null, 0],
        [null, null, null, null, null, null],
        ['5', '1,234', '1235', '10', '-3', '0,10', '1'],
      ),
      'double': (
        PlutoColumnType.double(),
        [1.5, 2.25, 10, null],
        [null, null, null, null],
        ['1.5', '2.3', '10', ''],
      ),
      'date': (
        PlutoColumnType.date(),
        ['2026-01-02', '2026-02-10', '2025-12-31', null],
        [null, null, null, null],
        ['2026-01-02', '2026-01', '2026-01-01,2026-01-31', '2026'],
      ),
      'select': (
        PlutoColumnType.select(['b', 'a', 'c']),
        ['a', 'b', 'c', null],
        [null, null, null, null],
        ['a', 'b', 'a,c', 'z'],
      ),
      'set': (
        PlutoColumnType.text(),
        ['', '', '', '', ''],
        [
          <String>{'x', 'y'},
          <String?>{'y', null},
          <String>{},
          null,
          <String>{'z'},
        ],
        ['x', 'y', 'x;z', '{y}', ''],
      ),
    };
    for (final entry in data.entries) {
      final (type, values, filterValues, searches) = entry.value;
      final column = PlutoColumn(title: 'f', field: 'f', type: type);
      final rows = <PlutoRow>[
        for (int i = 0; i < values.length; i++)
          PlutoRow(
            cells: {
              'f': PlutoCell(value: values[i], filterValue: filterValues[i]),
            },
          ),
      ];
      PlutoGridStateManager.initializeRows([column], rows);
      for (final f in filters.entries) {
        final results = <String>[];
        for (final search in searches) {
          String result;
          try {
            final filter = FilterHelper.convertRowsToFilter(
              [
                FilterHelper.createFilterRow(
                  columnField: 'f',
                  filterType: f.value,
                  filterValue: search,
                ),
              ],
              [column],
            )!;
            result = [
              for (int i = 0; i < rows.length; i++)
                if (filter(rows[i])) i,
            ].join(',');
          } catch (e) {
            result = 'throws ${e.runtimeType}';
          }
          results.add('$search=>$result');
        }
        actual.add('${entry.key} | ${f.key} | ${results.join(' ; ')}');
      }
    }
    // All-columns search.
    final a = PlutoColumn(title: 'a', field: 'a', type: PlutoColumnType.text());
    final b = PlutoColumn(
      title: 'b',
      field: 'b',
      type: PlutoColumnType.number(),
    );
    final rows = <PlutoRow>[
      PlutoRow(
        cells: {
          'a': PlutoCell(value: 'x10'),
          'b': PlutoCell(value: 5),
        },
      ),
      PlutoRow(
        cells: {
          'a': PlutoCell(value: 'y'),
          'b': PlutoCell(value: 10),
        },
      ),
      PlutoRow(
        cells: {
          'a': PlutoCell(value: 'z'),
          'b': PlutoCell(value: 1000),
        },
      ),
    ];
    PlutoGridStateManager.initializeRows([a, b], rows);
    for (final search in ['10', '1,000', 'y', '5']) {
      final filter = FilterHelper.convertRowsToFilter(
        [
          FilterHelper.createFilterRow(
            filterType: const PlutoFilterTypeContains(),
            filterValue: search,
          ),
        ],
        [a, b],
      )!;
      actual.add(
        'all-columns | contains | $search=>${[for (int i = 0; i < rows.length; i++)
          if (filter(rows[i])) i].join(',')}',
      );
    }
    expect(actual, _Expected.lines);
  });
}

class _Expected {
  static const List<String> lines = <String>[
    r'text | contains | apple=>0,1 ; A=>0,1,2,5,6 ; a.b=>5 ; (1)=>6 ; ban,app=> ; B=>2,5 ; =>0,1,2,3,4,5,6',
    r'text | notContains | apple=>2,3,4,5,6 ; A=>3,4 ; a.b=>0,1,2,3,4,6 ; (1)=>0,1,2,3,4,5 ; ban,app=>0,1,2,3,4,5,6 ; B=>0,1,3,4,6 ; =>',
    r'text | equals | apple=>0 ; A=> ; a.b=>5 ; (1)=> ; ban,app=> ; B=> ; =>3,4',
    r'text | notEquals | apple=>1,2,3,4,5,6 ; A=>0,1,2,3,4,5,6 ; a.b=>0,1,2,3,4,6 ; (1)=>0,1,2,3,4,5,6 ; ban,app=>0,1,2,3,4,5,6 ; B=>0,1,2,3,4,5,6 ; =>0,1,2,5,6',
    r'text | startsWith | apple=>0,1 ; A=>0,1,5,6 ; a.b=>5 ; (1)=> ; ban,app=> ; B=>2 ; =>0,1,2,3,4,5,6',
    r'text | endsWith | apple=>0 ; A=>2 ; a.b=>5 ; (1)=>6 ; ban,app=> ; B=>5 ; =>0,1,2,3,4,5,6',
    r'text | greaterThan | apple=>1 ; A=>0,1,2,5,6 ; a.b=>1 ; (1)=>0,1,2,5,6 ; ban,app=> ; B=>1,2,5 ; =>0,1,2,5,6',
    r'text | greaterThanOrEqualTo | apple=>1 ; A=>0,1,2,5,6 ; a.b=>1,5 ; (1)=>0,1,2,5,6 ; ban,app=> ; B=>1,2,5 ; =>0,1,2,3,4,5,6',
    r'text | lessThan | apple=>0,2,3,4,5,6 ; A=>3,4 ; a.b=>0,2,3,4,6 ; (1)=>3,4 ; ban,app=>0,1,2,3,4,5,6 ; B=>0,3,4,6 ; =>',
    r'text | lessThanOrEqualTo | apple=>0,2,3,4,5,6 ; A=>3,4 ; a.b=>0,2,3,4,5,6 ; (1)=>3,4 ; ban,app=>0,1,2,3,4,5,6 ; B=>0,3,4,6 ; =>3,4',
    r'text | between | apple=>1 ; A=>0,1,2,5,6 ; a.b=>1,5 ; (1)=>0,1,2,5,6 ; ban,app=> ; B=>1,2,5 ; =>0,1,2,5,6',
    r'text | isEmpty | apple=>3,4 ; A=>3,4 ; a.b=>3,4 ; (1)=>3,4 ; ban,app=>3,4 ; B=>3,4 ; =>3,4',
    r'text | isNotEmpty | apple=>0,1,2,5,6 ; A=>0,1,2,5,6 ; a.b=>0,1,2,5,6 ; (1)=>0,1,2,5,6 ; ban,app=>0,1,2,5,6 ; B=>0,1,2,5,6 ; =>0,1,2,5,6',
    r'text | containsSet | apple=>0,1,2,3,4,5,6 ; A=>0,1,2,3,4,5,6 ; a.b=>0,1,2,3,4,5,6 ; (1)=>0,1,2,3,4,5,6 ; ban,app=>0,1,2,3,4,5,6 ; B=>0,1,2,3,4,5,6 ; =>0,1,2,3,4,5,6',
    r'text | notContainsSet | apple=>0,1,2,3,4,5,6 ; A=>0,1,2,3,4,5,6 ; a.b=>0,1,2,3,4,5,6 ; (1)=>0,1,2,3,4,5,6 ; ban,app=>0,1,2,3,4,5,6 ; B=>0,1,2,3,4,5,6 ; =>0,1,2,3,4,5,6',
    r'text | isEmptySet | apple=>3,4 ; A=>3,4 ; a.b=>3,4 ; (1)=>3,4 ; ban,app=>3,4 ; B=>3,4 ; =>3,4',
    r'text | isNotEmptySet | apple=>0,1,2,5,6 ; A=>0,1,2,5,6 ; a.b=>0,1,2,5,6 ; (1)=>0,1,2,5,6 ; ban,app=>0,1,2,5,6 ; B=>0,1,2,5,6 ; =>0,1,2,5,6',
    r'number | contains | 5=>0,2 ; 1,234=> ; 1235=> ; 10=>1 ; -3=>3 ; 0,10=> ; 1=>1,2',
    r'number | notContains | 5=>1,3,4,5 ; 1,234=>0,1,2,3,4,5 ; 1235=>0,1,2,3,4,5 ; 10=>0,2,3,4,5 ; -3=>0,1,2,4,5 ; 0,10=>0,1,2,3,4,5 ; 1=>0,3,4,5',
    r'number | equals | 5=>0 ; 1,234=> ; 1235=> ; 10=>1 ; -3=>3 ; 0,10=> ; 1=>',
    r'number | notEquals | 5=>1,2,3,4,5 ; 1,234=>0,1,2,3,4,5 ; 1235=>0,1,2,3,4,5 ; 10=>0,2,3,4,5 ; -3=>0,1,2,4,5 ; 0,10=>0,1,2,3,4,5 ; 1=>0,1,2,3,4,5',
    r'number | startsWith | 5=>0 ; 1,234=> ; 1235=> ; 10=>1 ; -3=>3 ; 0,10=> ; 1=>1,2',
    r'number | endsWith | 5=>0,2 ; 1,234=> ; 1235=> ; 10=>1 ; -3=>3 ; 0,10=> ; 1=>',
    r'number | greaterThan | 5=>1,2 ; 1,234=>2 ; 1235=> ; 10=>2 ; -3=>0,1,2,4,5 ; 0,10=>2 ; 1=>0,1,2',
    r'number | greaterThanOrEqualTo | 5=>0,1,2 ; 1,234=>2 ; 1235=>2 ; 10=>1,2 ; -3=>0,1,2,3,4,5 ; 0,10=>1,2 ; 1=>0,1,2',
    r'number | lessThan | 5=>3,4,5 ; 1,234=>0,1,3,4,5 ; 1235=>0,1,2,3,4,5 ; 10=>0,3,4,5 ; -3=> ; 0,10=>0,3,4,5 ; 1=>3,4,5',
    r'number | lessThanOrEqualTo | 5=>0,3,4,5 ; 1,234=>0,1,3,4,5 ; 1235=>0,1,2,3,4,5 ; 10=>0,1,3,4,5 ; -3=>3 ; 0,10=>0,1,3,4,5 ; 1=>3,4,5',
    r'number | between | 5=>0,1,2 ; 1,234=>0,1 ; 1235=>2 ; 10=>1,2 ; -3=>0,1,2,3,4,5 ; 0,10=>0,1,4,5 ; 1=>0,1,2',
    r'number | isEmpty | 5=>4 ; 1,234=>4 ; 1235=>4 ; 10=>4 ; -3=>4 ; 0,10=>4 ; 1=>4',
    r'number | isNotEmpty | 5=>0,1,2,3,4,5 ; 1,234=>0,1,2,3,4,5 ; 1235=>0,1,2,3,4,5 ; 10=>0,1,2,3,4,5 ; -3=>0,1,2,3,4,5 ; 0,10=>0,1,2,3,4,5 ; 1=>0,1,2,3,4,5',
    r'number | containsSet | 5=>0,1,2,3,4,5 ; 1,234=>0,1,2,3,4,5 ; 1235=>0,1,2,3,4,5 ; 10=>0,1,2,3,4,5 ; -3=>0,1,2,3,4,5 ; 0,10=>0,1,2,3,4,5 ; 1=>0,1,2,3,4,5',
    r'number | notContainsSet | 5=>0,1,2,3,4,5 ; 1,234=>0,1,2,3,4,5 ; 1235=>0,1,2,3,4,5 ; 10=>0,1,2,3,4,5 ; -3=>0,1,2,3,4,5 ; 0,10=>0,1,2,3,4,5 ; 1=>0,1,2,3,4,5',
    r'number | isEmptySet | 5=>4 ; 1,234=>4 ; 1235=>4 ; 10=>4 ; -3=>4 ; 0,10=>4 ; 1=>4',
    r'number | isNotEmptySet | 5=>0,1,2,3,4,5 ; 1,234=>0,1,2,3,4,5 ; 1235=>0,1,2,3,4,5 ; 10=>0,1,2,3,4,5 ; -3=>0,1,2,3,4,5 ; 0,10=>0,1,2,3,4,5 ; 1=>0,1,2,3,4,5',
    r'double | contains | 1.5=>0 ; 2.3=> ; 10=>2 ; =>0,1,2,3',
    r'double | notContains | 1.5=>1,2,3 ; 2.3=>0,1,2,3 ; 10=>0,1,3 ; =>',
    r'double | equals | 1.5=>0 ; 2.3=> ; 10=>2 ; =>3',
    r'double | notEquals | 1.5=>1,2,3 ; 2.3=>0,1,2,3 ; 10=>0,1,2,3 ; =>0,1,2,3',
    r'double | startsWith | 1.5=>0 ; 2.3=> ; 10=>2 ; =>0,1,2,3',
    r'double | endsWith | 1.5=>0 ; 2.3=> ; 10=>2 ; =>0,1,2,3',
    r'double | greaterThan | 1.5=>1,2 ; 2.3=>2 ; 10=> ; =>0,1,2',
    r'double | greaterThanOrEqualTo | 1.5=>0,1,2 ; 2.3=>2 ; 10=>2 ; =>0,1,2,3',
    r'double | lessThan | 1.5=>3 ; 2.3=>0,1,3 ; 10=>0,1,3 ; =>',
    r'double | lessThanOrEqualTo | 1.5=>0,3 ; 2.3=>0,1,3 ; 10=>0,1,2,3 ; =>3',
    r'double | between | 1.5=>0,1,2 ; 2.3=>2 ; 10=>2 ; =>0,1,2,3',
    r'double | isEmpty | 1.5=>3 ; 2.3=>3 ; 10=>3 ; =>3',
    r'double | isNotEmpty | 1.5=>0,1,2,3 ; 2.3=>0,1,2,3 ; 10=>0,1,2,3 ; =>0,1,2,3',
    r'double | containsSet | 1.5=>0,1,2,3 ; 2.3=>0,1,2,3 ; 10=>0,1,2,3 ; =>0,1,2,3',
    r'double | notContainsSet | 1.5=>0,1,2,3 ; 2.3=>0,1,2,3 ; 10=>0,1,2,3 ; =>0,1,2,3',
    r'double | isEmptySet | 1.5=>3 ; 2.3=>3 ; 10=>3 ; =>3',
    r'double | isNotEmptySet | 1.5=>0,1,2,3 ; 2.3=>0,1,2,3 ; 10=>0,1,2,3 ; =>0,1,2,3',
    r'date | contains | 2026-01-02=>0 ; 2026-01=>0 ; 2026-01-01,2026-01-31=> ; 2026=>0,1',
    r'date | notContains | 2026-01-02=>1,2,3 ; 2026-01=>1,2,3 ; 2026-01-01,2026-01-31=>0,1,2,3 ; 2026=>2,3',
    r'date | equals | 2026-01-02=>0 ; 2026-01=> ; 2026-01-01,2026-01-31=> ; 2026=>',
    r'date | notEquals | 2026-01-02=>1,2,3 ; 2026-01=>0,1,2,3 ; 2026-01-01,2026-01-31=>0,1,2,3 ; 2026=>0,1,2,3',
    r'date | startsWith | 2026-01-02=>0 ; 2026-01=>0 ; 2026-01-01,2026-01-31=> ; 2026=>0,1',
    r'date | endsWith | 2026-01-02=>0 ; 2026-01=> ; 2026-01-01,2026-01-31=> ; 2026=>',
    r'date | greaterThan | 2026-01-02=>1 ; 2026-01=>0,1 ; 2026-01-01,2026-01-31=>0,1 ; 2026=>0,1',
    r'date | greaterThanOrEqualTo | 2026-01-02=>0,1 ; 2026-01=>0,1 ; 2026-01-01,2026-01-31=>0,1 ; 2026=>0,1',
    r'date | lessThan | 2026-01-02=>2,3 ; 2026-01=>2,3 ; 2026-01-01,2026-01-31=>2,3 ; 2026=>2,3',
    r'date | lessThanOrEqualTo | 2026-01-02=>0,2,3 ; 2026-01=>2,3 ; 2026-01-01,2026-01-31=>2,3 ; 2026=>2,3',
    r'date | between | 2026-01-02=>0,1 ; 2026-01=>0,1 ; 2026-01-01,2026-01-31=>0 ; 2026=>0,1',
    r'date | isEmpty | 2026-01-02=>3 ; 2026-01=>3 ; 2026-01-01,2026-01-31=>3 ; 2026=>3',
    r'date | isNotEmpty | 2026-01-02=>0,1,2 ; 2026-01=>0,1,2 ; 2026-01-01,2026-01-31=>0,1,2 ; 2026=>0,1,2',
    r'date | containsSet | 2026-01-02=>0,1,2,3 ; 2026-01=>0,1,2,3 ; 2026-01-01,2026-01-31=>0,1,2,3 ; 2026=>0,1,2,3',
    r'date | notContainsSet | 2026-01-02=>0,1,2,3 ; 2026-01=>0,1,2,3 ; 2026-01-01,2026-01-31=>0,1,2,3 ; 2026=>0,1,2,3',
    r'date | isEmptySet | 2026-01-02=>3 ; 2026-01=>3 ; 2026-01-01,2026-01-31=>3 ; 2026=>3',
    r'date | isNotEmptySet | 2026-01-02=>0,1,2 ; 2026-01=>0,1,2 ; 2026-01-01,2026-01-31=>0,1,2 ; 2026=>0,1,2',
    r'select | contains | a=>0 ; b=>1 ; a,c=> ; z=>',
    r'select | notContains | a=>1,2,3 ; b=>0,2,3 ; a,c=>0,1,2,3 ; z=>0,1,2,3',
    r'select | equals | a=>0 ; b=>1 ; a,c=> ; z=>',
    r'select | notEquals | a=>1,2,3 ; b=>0,2,3 ; a,c=>0,1,2,3 ; z=>0,1,2,3',
    r'select | startsWith | a=>0 ; b=>1 ; a,c=> ; z=>',
    r'select | endsWith | a=>0 ; b=>1 ; a,c=> ; z=>',
    r'select | greaterThan | a=>2 ; b=>0,2 ; a,c=>0,1,2 ; z=>0,1,2',
    r'select | greaterThanOrEqualTo | a=>0,2 ; b=>0,1,2 ; a,c=>0,1,2,3 ; z=>0,1,2,3',
    r'select | lessThan | a=>1,3 ; b=>3 ; a,c=> ; z=>',
    r'select | lessThanOrEqualTo | a=>0,1,3 ; b=>1,3 ; a,c=>3 ; z=>3',
    r'select | between | a=>0,2 ; b=>0,1,2 ; a,c=>0,2 ; z=>0,1,2',
    r'select | isEmpty | a=>3 ; b=>3 ; a,c=>3 ; z=>3',
    r'select | isNotEmpty | a=>0,1,2 ; b=>0,1,2 ; a,c=>0,1,2 ; z=>0,1,2',
    r'select | containsSet | a=>0,1,2,3 ; b=>0,1,2,3 ; a,c=>0,1,2,3 ; z=>0,1,2,3',
    r'select | notContainsSet | a=>0,1,2,3 ; b=>0,1,2,3 ; a,c=>0,1,2,3 ; z=>0,1,2,3',
    r'select | isEmptySet | a=>3 ; b=>3 ; a,c=>3 ; z=>3',
    r'select | isNotEmptySet | a=>0,1,2 ; b=>0,1,2 ; a,c=>0,1,2 ; z=>0,1,2',
    r'set | contains | x=> ; y=> ; x;z=> ; {y}=> ; =>0,1,2,3,4',
    r'set | notContains | x=>0,1,2,3,4 ; y=>0,1,2,3,4 ; x;z=>0,1,2,3,4 ; {y}=>0,1,2,3,4 ; =>',
    r'set | equals | x=> ; y=> ; x;z=> ; {y}=> ; =>0,1,2,3,4',
    r'set | notEquals | x=>0,1,2,3,4 ; y=>0,1,2,3,4 ; x;z=>0,1,2,3,4 ; {y}=>0,1,2,3,4 ; =>',
    r'set | startsWith | x=> ; y=> ; x;z=> ; {y}=> ; =>0,1,2,3,4',
    r'set | endsWith | x=> ; y=> ; x;z=> ; {y}=> ; =>0,1,2,3,4',
    r'set | greaterThan | x=> ; y=> ; x;z=> ; {y}=> ; =>',
    r'set | greaterThanOrEqualTo | x=> ; y=> ; x;z=> ; {y}=> ; =>0,1,2,3,4',
    r'set | lessThan | x=>0,1,2,3,4 ; y=>0,1,2,3,4 ; x;z=>0,1,2,3,4 ; {y}=>0,1,2,3,4 ; =>',
    r'set | lessThanOrEqualTo | x=>0,1,2,3,4 ; y=>0,1,2,3,4 ; x;z=>0,1,2,3,4 ; {y}=>0,1,2,3,4 ; =>0,1,2,3,4',
    r'set | between | x=> ; y=> ; x;z=> ; {y}=> ; =>',
    r'set | isEmpty | x=>0,1,2,3,4 ; y=>0,1,2,3,4 ; x;z=>0,1,2,3,4 ; {y}=>0,1,2,3,4 ; =>0,1,2,3,4',
    r'set | isNotEmpty | x=> ; y=> ; x;z=> ; {y}=> ; =>',
    r'set | containsSet | x=>0,3 ; y=>0,1,3 ; x;z=>0,3,4 ; {y}=>0,1,3 ; =>0,1,2,3,4',
    r'set | notContainsSet | x=>1,2,3,4 ; y=>2,3,4 ; x;z=>1,2,3 ; {y}=>2,3,4 ; =>0,1,2,3,4',
    r'set | isEmptySet | x=>2,3 ; y=>2,3 ; x;z=>2,3 ; {y}=>2,3 ; =>2,3',
    r'set | isNotEmptySet | x=>0,1,4 ; y=>0,1,4 ; x;z=>0,1,4 ; {y}=>0,1,4 ; =>0,1,4',
    r'all-columns | contains | 10=>0,1,2',
    r'all-columns | contains | 1,000=>2',
    r'all-columns | contains | y=>1',
    r'all-columns | contains | 5=>0',
  ];
}
