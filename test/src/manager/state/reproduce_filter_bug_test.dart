import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import '../../../mock/mock_methods.dart';
import '../../../mock/shared_mocks.mocks.dart';

void main() {
  List<PlutoColumn> columns;
  List<PlutoRow> rows;
  late PlutoGridStateManager stateManager;
  MockMethods listener;

  setUp(() {
    columns = [
      PlutoColumn(
        title: 'column1',
        field: 'column1',
        type: PlutoColumnType.text(),
        enableFilterMenuItem: false,
      ),
      PlutoColumn(
        title: 'column2',
        field: 'column2',
        type: PlutoColumnType.text(),
      ),
    ];

    rows = [
      PlutoRow(
        cells: {
          'column1': PlutoCell(value: 'abc'),
          'column2': PlutoCell(value: '123'),
        },
      ),
      PlutoRow(
        cells: {
          'column1': PlutoCell(value: 'def'),
          'column2': PlutoCell(value: '456'),
        },
      ),
      PlutoRow(
        cells: {
          'column1': PlutoCell(value: 'ghi'),
          'column2': PlutoCell(value: '789'),
        },
      ),
    ];

    stateManager = PlutoGridStateManager(
      columns: columns,
      rows: rows,
      gridFocusNode: MockFocusNode(),
      scroll: MockPlutoGridScrollController(),
    );

    listener = MockMethods();
    stateManager.addListener(listener.noParamReturnVoid);
  });

  test('setFilterWithFilterRows should filter rows correctly', () {
    // 1. Initial State
    // Ensure all rows are present initially
    expect(stateManager.refRows.length, 3);
    expect(stateManager.hasFilter, isFalse);

    // 2. Create a filter row: Column1 Contains "abc"
    final filterRows = [
      FilterHelper.createFilterRow(
        columnField: 'column1',
        filterType: const PlutoFilterTypeContains(),
        filterValue: 'abc',
      ),
    ];

    // 3. Apply the filter using setFilterWithFilterRows
    stateManager.setFilterWithFilterRows(filterRows);

    // 4. Verify results
    // The filter state should be updated
    expect(stateManager.hasFilter, isTrue, reason: 'hasFilter should be true');
    expect(
      stateManager.filterRows.length,
      1,
      reason: 'filterRows should have 1 item',
    );

    // The visual rows (refRows) should be filtered
    // This is the core of the bug report - distinct from just setting the filter state
    // We expect only 1 row ("abc") to remain suitable for display
    expect(
      stateManager.refRows.length,
      1,
      reason: 'refRows should contain exactly 1 filtered row',
    );
    expect(stateManager.refRows.first.cells['column1']!.value, 'abc');
  });
}
