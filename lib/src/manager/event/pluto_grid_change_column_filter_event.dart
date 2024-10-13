import 'package:pluto_grid_plus/pluto_grid_plus.dart';

/// Event called when the value of the TextField
/// that handles the filter under the column changes.
class PlutoGridChangeColumnFilterEvent extends PlutoGridEvent {
  final PlutoColumn column;
  final PlutoFilterType filterType;
  final String filterValue;
  final dynamic filterValueObject;
  final int? debounceMilliseconds;

  PlutoGridChangeColumnFilterEvent({
    required this.column,
    required this.filterType,
    required this.filterValue,
    required this.filterValueObject,
    this.debounceMilliseconds,
  }) : super(
          type: PlutoGridEventType.debounce,
          duration: Duration(
            milliseconds: debounceMilliseconds == null
                ? PlutoGridSettings.debounceMillisecondsForColumnFilter
                : debounceMilliseconds < 0
                    ? 0
                    : debounceMilliseconds,
          ),
        );

  List<PlutoRow> _getFilterRows(PlutoGridStateManager? stateManager) {
    final List<PlutoRow> foundFilterRows =
        stateManager!.filterRowsByField(column.field);

    if (foundFilterRows.isEmpty) {
      return [
        ...stateManager.filterRows,
        FilterHelper.createFilterRow(
          columnField: column.field,
          filterType: filterType,
          filterValue: filterValue,
          filterValueObject: filterValueObject,
        ),
      ];
    }

    final PlutoCell? row =
        foundFilterRows.first.cells[FilterHelper.filterFieldValue];
    row?.value = filterValue;
    row?.filterValue = filterValueObject;

    return stateManager.filterRows;
  }

  @override
  void handler(PlutoGridStateManager stateManager) {
    stateManager.setFilterWithFilterRows(_getFilterRows(stateManager));
  }
}
