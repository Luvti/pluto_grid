import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import '../../../mock/mock_methods.dart';
import '../../../mock/shared_mocks.mocks.dart';

// flutter test test/src/manager/state/reproduction_filter_issue_test.dart
void main() {
  late PlutoGridStateManager stateManager;
  late List<PlutoColumn> columns;
  late List<PlutoRow> rows;
  late MockMethods listener;

  setUp(() {
    columns = [
      PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.text(),
      ),
    ];
    rows = [
      PlutoRow(cells: {'column': PlutoCell(value: 'abc')}),
      PlutoRow(cells: {'column': PlutoCell(value: 'def')}),
      PlutoRow(cells: {'column': PlutoCell(value: 'ghi')}),
    ];

    // MockMethods is a helper class created in the test suite
    listener = MockMethods();

    stateManager = PlutoGridStateManager(
      columns: columns,
      rows: rows,
      gridFocusNode: MockFocusNode(),
      scroll: MockPlutoGridScrollController(),
    );

    // Add listener to verify notifications
    stateManager.addListener(listener.noParamReturnVoid);

    // Enable Pagination
    stateManager.setPageSize(10);
    stateManager.setPage(1);
  });

  test('Reproduce 1: No filter -> Set Type:Contains, Value:a', () {
    // 1. Verify initial state (all rows)
    expect(stateManager.refRows.length, 3);

    // 2. Set Filter
    stateManager.setFilterWithFilterRows([
      PlutoRow(
        cells: {
          FilterHelper.filterFieldColumn: PlutoCell(value: 'column'),
          FilterHelper.filterFieldType: PlutoCell(
            value: const PlutoFilterTypeContains(),
          ),
          FilterHelper.filterFieldValue: PlutoCell(value: 'a'),
        },
      ),
    ]);

    // 3. Verify filtered state
    expect(stateManager.rows.length, 1);
    expect(stateManager.rows.first.cells['column']!.value, 'abc');

    // Verify notification was sent
    verify(listener.noParamReturnVoid()).called(greaterThan(0));
  });

  test(
    'Reproduce 2: Has Filter (Contains "a") -> Set Filter (Contains "d")',
    () {
      // Setup initial filter
      stateManager.setFilterWithFilterRows([
        PlutoRow(
          cells: {
            FilterHelper.filterFieldColumn: PlutoCell(value: 'column'),
            FilterHelper.filterFieldType: PlutoCell(
              value: const PlutoFilterTypeContains(),
            ),
            FilterHelper.filterFieldValue: PlutoCell(value: 'a'),
          },
        ),
      ]);
      expect(stateManager.rows.length, 1);
      reset(listener); // Clear previous calls

      // Change to 'd'
      stateManager.setFilterWithFilterRows([
        PlutoRow(
          cells: {
            FilterHelper.filterFieldColumn: PlutoCell(value: 'column'),
            FilterHelper.filterFieldType: PlutoCell(
              value: const PlutoFilterTypeContains(),
            ),
            FilterHelper.filterFieldValue: PlutoCell(value: 'd'),
          },
        ),
      ]);

      // Verify
      expect(stateManager.rows.length, 1);
      expect(stateManager.rows.first.cells['column']!.value, 'def');

      // Verify notification was sent
      verify(listener.noParamReturnVoid()).called(greaterThan(0));
    },
  );

  test(
    'Reproduce 3: Has Filter (Contains "a") -> Set Filter (Equals "abc")',
    () {
      // Setup initial filter
      stateManager.setFilterWithFilterRows([
        PlutoRow(
          cells: {
            FilterHelper.filterFieldColumn: PlutoCell(value: 'column'),
            FilterHelper.filterFieldType: PlutoCell(
              value: const PlutoFilterTypeContains(),
            ),
            FilterHelper.filterFieldValue: PlutoCell(value: 'a'),
          },
        ),
      ]);
      expect(stateManager.rows.length, 1);
      reset(listener);

      // Change to Equals 'abc'
      stateManager.setFilterWithFilterRows([
        PlutoRow(
          cells: {
            FilterHelper.filterFieldColumn: PlutoCell(value: 'column'),
            FilterHelper.filterFieldType: PlutoCell(
              value: const PlutoFilterTypeEquals(),
            ),
            FilterHelper.filterFieldValue: PlutoCell(value: 'abc'),
          },
        ),
      ]);

      // Verify
      expect(stateManager.rows.length, 1);
      expect(stateManager.rows.first.cells['column']!.value, 'abc');

      // Verify notification was sent
      verify(listener.noParamReturnVoid()).called(greaterThan(0));
    },
  );
}
