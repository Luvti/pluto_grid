import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

abstract class IFilteringRowState {
  List<PlutoRow> get filterRows;

  bool get hasFilter;

  void setFilter(FilteredListFilter<PlutoRow>? filter, {bool notify = true});

  void setFilterWithFilterRows(List<PlutoRow> rows, {bool notify = true});

  void setFilterRows(List<PlutoRow> rows);

  List<PlutoRow> filterRowsByField(String columnField);

  /// Check if the column is in a state with filtering applied.
  bool isFilteredColumn(PlutoColumn column);

  void removeColumnsInFilterRows(
    List<PlutoColumn> columns, {
    bool notify = true,
  });

  void showFilterPopup(BuildContext context, {PlutoColumn? calledColumn});

  FilteredListFilter<PlutoRow>? savedFilter;
}

class _State {
  /// use PlutoRowFilterX extension for PlutoRow (cells with filter info)
  /// current applied filters for rows
  List<PlutoRow> _filterRows = <PlutoRow>[];

  /// based on change filter in columns
  List<PlutoRow> _filterColumns = <PlutoRow>[];
}

extension PlutoRowFilterX on PlutoRow {
  PlutoColumn? get filterColumn =>
      cells[FilterHelper.filterFieldColumn]?.originalValue as PlutoColumn;
  PlutoFilterType? get filterType =>
      cells[FilterHelper.filterFieldType]?.originalValue as PlutoFilterType;
  String? get filterValue =>
      cells[FilterHelper.filterFieldValue]?.originalValue?.toString();
  // can be null
  dynamic get filterValueObject =>
      cells[FilterHelper.filterFieldValue]?.originalValue;

  bool get canApplyFilter =>
      filterType is PlutoFilterTypeIsEmpty ||
      filterType is PlutoFilterTypeIsEmptySet ||
      filterType is PlutoFilterTypeIsNotEmpty ||
      filterType is PlutoFilterTypeIsNotEmptySet ||
      (filterValue != null && filterValue!.isNotEmpty);
}

mixin FilteringRowState implements IPlutoGridState {
  final _State _state = _State();

  /// current applied filters for rows (with canApplyFilter)
  @override
  List<PlutoRow> get filterRows => _state._filterRows;

  /// based on changed filter in columns or default filters with value
  List<PlutoRow> get filterColumns => _state._filterColumns;

  @override
  bool get hasFilter =>
      refRows.hasFilter || (filterOnlyEvent && filterRows.isNotEmpty);

  @override
  void setFilter(
    FilteredListFilter<PlutoRow>? filter, {
    bool notify = true,
    List<PlutoRow>? filterRowsApply,
  }) {
    if (filterRowsApply != null) {
      setFilterRows(filterRowsApply);
    }
    // fix for save empty custom filters
    if (filter == null && filterColumns.isEmpty) {
      setFilterRows(<PlutoRow>[]);
    }

    if (filterOnlyEvent) {
      eventManager!.addEvent(
        PlutoGridSetColumnFilterEvent(filterRows: filterRows),
      );
      return;
    }

    for (final PlutoRow row in iterateAllRowAndGroup) {
      row.setState(PlutoRowState.none);
    }

    savedFilter = filter;

    if (filter != null) {
      savedFilter = (PlutoRow row) {
        return !row.state.isNone || filter(row);
      };
    }

    if (enabledRowGroups) {
      setRowGroupFilter(savedFilter);
    } else {
      refRows.setFilter(savedFilter);
    }

    resetCurrentState(notify: false);

    notifyListeners(notify, setFilter.hashCode);
  }

  @override
  void setFilterWithFilterRows(List<PlutoRow> rows, {bool notify = true}) {
    setFilterRows(rows);

    setFilter(
      FilterHelper.convertRowsToFilter(filterRows, refColumns),
      notify: isPaginated ? false : notify,
    );

    if (isPaginated) {
      resetPage(notify: notify);
    }
  }

  @override
  void setFilterRows(List<PlutoRow> rows) {
    _state._filterColumns = rows;
    _state._filterRows = rows
        .where((PlutoRow element) => element.canApplyFilter)
        .toList();
    final PlutoGridSetColumnFilterEvent event = PlutoGridSetColumnFilterEvent(
      filterRows: rows,
    );
    onFiltered?.call(event);
  }

  @override
  List<PlutoRow> filterRowsByField(String columnField) {
    return filterColumns
        .where(
          (PlutoRow element) =>
              element.cells[FilterHelper.filterFieldColumn]!.originalValue ==
              columnField,
        )
        .toList();
  }

  @override
  bool isFilteredColumn(PlutoColumn column) {
    return hasFilter && FilterHelper.isFilteredColumn(column, filterRows);
  }

  @override
  void removeColumnsInFilterRows(
    List<PlutoColumn> columns, {
    bool notify = true,
  }) {
    if (filterRows.isEmpty) {
      return;
    }

    final Set<String> columnFields = Set.from(
      columns.map((PlutoColumn e) => e.field),
    );

    filterRows.removeWhere((PlutoRow filterRow) {
      return columnFields.contains(
        filterRow.cells[FilterHelper.filterFieldColumn]!.originalValue,
      );
    });

    setFilterWithFilterRows(filterRows, notify: notify);
  }

  @override
  void showFilterPopup(
    BuildContext context, {
    PlutoColumn? calledColumn,
    void Function()? onClosed,
  }) {
    bool shouldProvideDefaultFilterRow =
        filterColumns.isEmpty && calledColumn != null;

    List<PlutoRow> rows = shouldProvideDefaultFilterRow
        ? <PlutoRow>[
            FilterHelper.createFilterRow(
              columnField: calledColumn.enableFilterMenuItem
                  ? calledColumn.field
                  : FilterHelper.filterFieldAllColumns,
              filterType: calledColumn.defaultFilter,
            ),
          ]
        : filterColumns;

    FilterHelper.filterPopup(
      FilterPopupState(
        context: context,
        configuration: configuration.copyWith(
          style: configuration.style.copyWith(
            gridBorderRadius: configuration.style.gridPopupBorderRadius,
            enableRowColorAnimation: false,
            oddRowColor: const PlutoOptional(null),
            evenRowColor: const PlutoOptional(null),
          ),
        ),
        handleAddNewFilter: (PlutoGridStateManager? filterState) {
          filterState!.appendRows(<PlutoRow>[FilterHelper.createFilterRow()]);
        },
        handleApplyFilter: (PlutoGridStateManager? filterState) {
          setFilterWithFilterRows(filterState!.rows);
        },
        columns: columns,
        filterRows: rows,
        focusFirstFilterValue: shouldProvideDefaultFilterRow,
        onClosed: onClosed,
      ),
    );
  }
}
