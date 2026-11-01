// Characterization of sorting, filtering and aggregates in a mounted grid,
// recorded before the cell fields were slimmed down.
//
// Rows 0-2 are rendered, so their cells were formatted by `valueFormatted`;
// rows 37-39 stay outside the viewport with their initial values. Filters read
// `currentValue`, so the two groups can match differently.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  for (final _Scenario scenario in _Scenario.all) {
    testWidgets('${scenario.name}: rendered and offscreen rows', (
      WidgetTester tester,
    ) async {
      final DebugPrintCallback previousDebugPrint = debugPrint;
      // Filtering offscreen dates prints parse errors of their unformatted values.
      debugPrint = (String? message, {int? wrapWidth}) {};
      try {
        await _Grid.check(tester, scenario);
      } finally {
        debugPrint = previousDebugPrint;
      }
    });
  }

  testWidgets('bool: false sorts before true', (WidgetTester tester) async {
    final _Grid grid = await _Grid.pump(tester, _Scenario.boolean);
    // Equal values keep no particular order: check the groups only.
    grid.manager.sortAscending(grid.column);
    expect(grid.sampleValuesInOrder(), 'false,false,false,true,true,true');
    grid.manager.sortDescending(grid.column);
    expect(grid.sampleValuesInOrder(), 'true,true,true,false,false,false');
  });
}

class _Grid {
  _Grid(this.rows, this.column, this.manager);

  static const String field = 'value';
  static const List<int> sample = <int>[0, 1, 2, 37, 38, 39];
  static const Map<String, PlutoFilterType> filterTypes =
      <String, PlutoFilterType>{
        'equals': PlutoFilterTypeEquals(),
        'contains': PlutoFilterTypeContains(),
        'greater': PlutoFilterTypeGreaterThan(),
        'lessOrEqual': PlutoFilterTypeLessThanOrEqualTo(),
      };

  final List<PlutoRow<dynamic>> rows;
  final PlutoColumn column;
  final PlutoGridStateManager manager;

  static Future<_Grid> pump(WidgetTester tester, _Scenario scenario) async {
    final PlutoColumn column = PlutoColumn(
      title: field,
      field: field,
      type: scenario.type(),
    );
    final List<PlutoRow<dynamic>> rows = <PlutoRow<dynamic>>[
      for (int index = 0; index < 40; index++)
        PlutoRow<dynamic>(
          cells: <String, PlutoCell>{
            field: PlutoCell(
              value: index < 3
                  ? scenario.values[index]
                  : index >= 37
                  ? scenario.values[index - 34]
                  : scenario.filler(index),
            ),
          },
        ),
    ];
    late PlutoGridStateManager manager;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            height: 300,
            child: PlutoGrid(
              columns: <PlutoColumn>[column],
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) =>
                  manager = event.stateManager,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return _Grid(rows, column, manager);
  }

  static Future<void> check(WidgetTester tester, _Scenario scenario) async {
    final _Grid grid = await _Grid.pump(tester, scenario);

    expect(grid.currentValues(), scenario.currentValues);

    for (final MapEntry<String, Map<String, String>> filter
        in scenario.filters.entries) {
      for (final MapEntry<String, String> search in filter.value.entries) {
        grid.filter(_Grid.filterTypes[filter.key], search.key);
        expect(
          grid.visibleSampleRows(),
          search.value,
          reason: '${filter.key} ${search.key}',
        );
      }
    }
    grid.filter(null, null);

    grid.manager.sortAscending(grid.column);
    expect(grid.sampleOrder(), scenario.ascending);
    grid.manager.sortDescending(grid.column);
    expect(grid.sampleOrder(), scenario.descending);
    grid.manager.sortBySortIdx(grid.column);
    expect(grid.sampleOrder(), '0,1,2,37,38,39');

    if (scenario.aggregates != null) {
      expect(grid.aggregates(), scenario.aggregates);
    }

    grid.manager.changeCellValue(
      grid.rows[39].cells[_Grid.field]!,
      scenario.editedValue,
      force: true,
    );
    grid.manager.sortAscending(grid.column);
    expect(
      '${grid.sampleOrder()} current=${grid.rows[39].cells[_Grid.field]!.currentValue}',
      scenario.ascendingAfterEdit,
    );
  }

  bool _isSample(PlutoRow<dynamic> row) => sample.contains(rows.indexOf(row));

  String currentValues() => sample
      .map((int index) => '${rows[index].cells[field]!.currentValue}')
      .join(',');

  void filter(PlutoFilterType? type, String? value) {
    manager.setFilterWithFilterRows(
      type == null
          ? <PlutoRow<dynamic>>[]
          : <PlutoRow<dynamic>>[
              FilterHelper.createFilterRow(
                columnField: field,
                filterType: type,
                filterValue: value,
              ),
            ],
    );
  }

  String visibleSampleRows() =>
      manager.refRows.where(_isSample).map(rows.indexOf).join(',');

  String sampleOrder() =>
      manager.refRows.where(_isSample).map(rows.indexOf).join(',');

  String sampleValuesInOrder() => manager.refRows
      .where(_isSample)
      .map((PlutoRow<dynamic> row) => '${row.cells[field]!.currentValue}')
      .join(',');

  String aggregates() {
    final Iterable<PlutoRow<dynamic>> sampleRows = rows.where(_isSample);
    return 'sum=${PlutoAggregateHelper.sum(rows: sampleRows, column: column)} '
        'avg=${PlutoAggregateHelper.average(rows: sampleRows, column: column)} '
        'min=${PlutoAggregateHelper.min(rows: sampleRows, column: column)} '
        'max=${PlutoAggregateHelper.max(rows: sampleRows, column: column)}';
  }
}

class _Scenario {
  const _Scenario({
    required this.name,
    required this.type,
    required this.values,
    required this.filler,
    required this.currentValues,
    required this.filters,
    required this.ascending,
    required this.descending,
    required this.editedValue,
    required this.ascendingAfterEdit,
    this.aggregates,
  });

  final String name;
  final PlutoColumnType Function() type;

  /// Values of rows 0, 1, 2, 37, 38 and 39.
  final List<Object> values;
  final Object Function(int index) filler;
  final String currentValues;

  /// Filter type → search text → sample rows left visible.
  final Map<String, Map<String, String>> filters;
  final String ascending;
  final String descending;
  final String? aggregates;
  final Object editedValue;
  final String ascendingAfterEdit;

  static const List<num> _numbers = <num>[1.4, 1.2, 1.456, 2, 1.6, 1.45];

  static Object _largeNumber(int index) => 100 + index;

  static Object _lateText(int index) => 'z$index';

  static Object _lateDate(int index) => '01.01.2027';

  static Object _true(int index) => true;

  static PlutoColumnType _currency() =>
      PlutoColumnType.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);

  static PlutoColumnType _date() => PlutoColumnType.date(format: 'dd.MM.yyyy');

  static const Map<String, Map<String, String>> _doubleFilters =
      <String, Map<String, String>>{
        'equals': <String, String>{
          '1': '',
          '1.4': '0',
          '1.45': '39',
          '2': '37',
        },
        'contains': <String, String>{
          '1': '0,1,2,38,39',
          '1.4': '0,2,39',
          '1.45': '39',
          '2': '1,37',
        },
        'greater': <String, String>{
          '1': '0,1,2,37,38,39',
          '1.4': '2,37,38,39',
          '1.45': '2,37,38',
          '2': '',
        },
        'lessOrEqual': <String, String>{
          '1': '',
          '1.4': '0,1',
          '1.45': '0,1,39',
          '2': '0,1,2,37,38,39',
        },
      };

  static const _Scenario boolean = _Scenario(
    name: 'bool',
    type: PlutoColumnType.bool,
    values: <Object>[true, false, true, false, true, false],
    filler: _true,
    currentValues: 'true,false,true,false,true,false',
    filters: <String, Map<String, String>>{
      'equals': <String, String>{'true': '0,2,38', 'false': '1,37,39'},
      'contains': <String, String>{'true': '0,2,38', 'false': '1,37,39'},
      'greater': <String, String>{'true': '', 'false': '0,2,38'},
      'lessOrEqual': <String, String>{
        'true': '0,1,2,37,38,39',
        'false': '1,37,39',
      },
    },
    // Equal values: checked separately by group.
    ascending: '',
    descending: '',
    editedValue: true,
    ascendingAfterEdit: '',
  );

  static final List<_Scenario> all = <_Scenario>[
    // Rendered rows show (and keep) 1; sorting still uses the raw numbers.
    const _Scenario(
      name: 'number #,###',
      type: PlutoColumnType.number,
      values: _numbers,
      filler: _largeNumber,
      currentValues: '1,1,1,2,1.6,1.45',
      filters: <String, Map<String, String>>{
        'equals': <String, String>{
          '1': '0,1,2,39',
          '1.4': '',
          '1.45': '39',
          '2': '37,38',
        },
        'contains': <String, String>{
          '1': '0,1,2,38,39',
          '1.4': '39',
          '1.45': '39',
          '2': '37,38',
        },
        'greater': <String, String>{
          '1': '37,38,39',
          '1.4': '37,38,39',
          '1.45': '37,38',
          '2': '',
        },
        'lessOrEqual': <String, String>{
          '1': '0,1,2,39',
          '1.4': '0,1,2,39',
          '1.45': '0,1,2,39',
          '2': '0,1,2,37,38,39',
        },
      },
      ascending: '1,0,39,2,38,37',
      descending: '37,38,2,39,0,1',
      aggregates: 'sum=8 avg=1 min=1 max=2',
      editedValue: 0.5,
      // Row 39 sorts by its edited value.
      ascendingAfterEdit: '39,1,0,2,38,37 current=1',
    ),
    const _Scenario(
      name: 'double',
      type: PlutoColumnType.double,
      values: _numbers,
      filler: _largeNumber,
      currentValues: '1.4,1.2,1.46,2,1.6,1.45',
      filters: _doubleFilters,
      ascending: '1,0,39,2,38,37',
      descending: '37,38,2,39,0,1',
      aggregates: 'sum=0 avg=1.52 min=null max=null',
      editedValue: 0.5,
      // Row 39 sorts by its edited value.
      ascendingAfterEdit: '39,1,0,2,38,37 current=0.5',
    ),
    const _Scenario(
      name: 'currency',
      type: _currency,
      values: _numbers,
      filler: _largeNumber,
      currentValues: '1.4,1.2,1.46,2,1.6,1.45',
      filters: _doubleFilters,
      ascending: '1,0,39,2,38,37',
      descending: '37,38,2,39,0,1',
      aggregates: 'sum=9.11 avg=1.52 min=1.2 max=2',
      editedValue: 0.5,
      ascendingAfterEdit: '39,1,0,2,38,37 current=0.5',
    ),
    const _Scenario(
      name: 'text',
      type: PlutoColumnType.text,
      values: <Object>['b10', 'b2', 'a', 'B', 'b1', 'c'],
      filler: _lateText,
      currentValues: 'b10,b2,a,B,b1,c',
      filters: <String, Map<String, String>>{
        'equals': <String, String>{'b': '37', 'b1': '38', 'B': '37'},
        'contains': <String, String>{
          'b': '0,1,37,38',
          'b1': '0,38',
          'B': '0,1,37,38',
        },
        'greater': <String, String>{
          'b': '0,1,38,39',
          'b1': '0,1,39',
          'B': '0,1,2,38,39',
        },
        'lessOrEqual': <String, String>{
          'b': '2,37',
          'b1': '2,37,38',
          'B': '37',
        },
      },
      ascending: '37,2,38,0,1,39',
      descending: '39,1,0,38,2,37',
      editedValue: 'a0',
      ascendingAfterEdit: '37,2,39,38,0,1 current=a0',
    ),
    // Rendered dates show the column format; offscreen ones keep ISO strings.
    const _Scenario(
      name: 'date dd.MM.yyyy',
      type: _date,
      values: <Object>[
        '2026-01-10',
        '2026-01-02',
        '2025-12-31',
        '2026-02-01',
        '2026-01-03',
        '2026-01-01',
      ],
      filler: _lateDate,
      currentValues:
          '10.01.2026,02.01.2026,31.12.2025,2026-02-01,2026-01-03,2026-01-01',
      filters: <String, Map<String, String>>{
        'equals': <String, String>{
          '2026-01-02': '',
          '02.01.2026': '1',
          '2026-01': '',
        },
        'contains': <String, String>{
          '2026-01-02': '',
          '02.01.2026': '1',
          '2026-01': '38,39',
        },
        'greater': <String, String>{
          '2026-01-02': '2,37,38',
          '02.01.2026': '0,2,37,38,39',
          '2026-01': '2,37,38,39',
        },
        'lessOrEqual': <String, String>{
          '2026-01-02': '0,1,39',
          '02.01.2026': '1',
          '2026-01': '0,1',
        },
      },
      ascending: '2,39,1,38,0,37',
      descending: '37,0,38,1,39,2',
      editedValue: '2020-01-01',
      ascendingAfterEdit: '2,39,1,38,0,37 current=01.01.2026',
    ),
  ];
}
