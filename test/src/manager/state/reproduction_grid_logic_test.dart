import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import '../../../mock/mock_methods.dart';
import '../../../mock/shared_mocks.mocks.dart';

// flutter test test/src/manager/state/reproduction_grid_logic_test.dart

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
        type: PlutoColumnType.number(),
        defaultFilter: const PlutoFilterTypeBetween(),
      ),
      PlutoColumn(
        title: 'tags',
        field: 'tags', // BaseGridRenderer.colorTagColumnName proxy
        type: PlutoColumnType.text(),
      ),
    ];
    rows = [
      PlutoRow(
        cells: {
          'column': PlutoCell(value: 1),
          'tags': PlutoCell(value: 'A'),
        },
      ),
      PlutoRow(
        cells: {
          'column': PlutoCell(value: 2),
          'tags': PlutoCell(value: 'B'),
        },
      ),
      PlutoRow(
        cells: {
          'column': PlutoCell(value: 3),
          'tags': PlutoCell(value: 'A'),
        },
      ),
    ];

    listener = MockMethods();

    stateManager = PlutoGridStateManager(
      columns: columns,
      rows: rows,
      gridFocusNode: MockFocusNode(),
      scroll: MockPlutoGridScrollController(),
    );

    stateManager.addListener(listener.noParamReturnVoid);
  });

  test(
    'Reproduction: setFilterWithFilterRows fails to update filter when mutating filter rows',
    () {
      // 1. Initial State: 3 rows (values: 1, 2, 3)
      expect(stateManager.refRows.length, 3);

      // 2. Apply First Filter: column > 1
      // Matches '2' and '3'
      var filterRows = [
        PlutoRow(
          cells: {
            FilterHelper.filterFieldColumn: PlutoCell(value: 'column'),
            FilterHelper.filterFieldType: PlutoCell(
              value: const PlutoFilterTypeGreaterThan(),
            ),
            FilterHelper.filterFieldValue: PlutoCell(value: '1'),
          },
        ),
      ];

      stateManager.setFilterWithFilterRows(filterRows);

      // Verify first filter worked
      expect(
        stateManager.rows.length,
        2,
        reason: 'Filter > 1 should return 2 rows',
      );
      expect(stateManager.rows[0].cells['column']!.value, 2);
      expect(stateManager.rows[1].cells['column']!.value, 3);

      // 3. Apply Second Filter: column > 2
      // Mutation: Update the value in the EXISTING filterRows list
      filterRows[0].cells[FilterHelper.filterFieldValue]!.value = '2';

      stateManager.setFilterWithFilterRows(filterRows);

      // Verify second filter worked
      // Matches '3' only
      expect(
        stateManager.rows.length,
        1,
        reason: 'Filter > 2 should return 1 row',
      );
      expect(stateManager.rows.first.cells['column']!.value, 3);
    },
  );
}
