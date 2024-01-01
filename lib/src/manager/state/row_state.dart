import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

abstract class IRowState {
  List<PlutoRow> get rows;

  /// [refRows] is a List<PlutoRow> type and holds the entire row data.
  ///
  /// [refRows] returns a list of final results
  /// according to pagination and filtering status.
  /// If the total number of rows is 100 and paginated in size 10,
  /// [refRows] returns a list of 10 of the current page.
  ///
  /// [refRows.originalList] to get the entire row data with pagination or filtering.
  ///
  /// A list with pagination and filtering applied and pagination not applied
  /// can be obtained with [refRows.filterOrOriginalList].
  ///
  /// Directly accessing [refRows] to process insert, remove, etc. may cause unexpected behavior.
  /// It is preferable to use the methods
  /// such as insertRows and removeRows of the built-in [PlutoGridStateManager] to handle it.
  FilteredList<PlutoRow> get refRows;

  List<PlutoRow> get checkedRows;

  List<PlutoRow> get unCheckedRows;

  bool get hasCheckedRow;

  bool get hasUnCheckedRow;

  /// Property for [tristate] value in [Checkbox] widget.
  bool? get tristateCheckedRow;

  /// Row index of currently selected cell.
  int? get currentRowIdx;

  /// Row of currently selected cell.
  PlutoRow? get currentRow;

  PlutoRowColorCallback? get rowColorCallback;

  int? getRowIdxByOffset(double offset);

  PlutoRow? getRowByIdx(int rowIdx);

  PlutoRow getNewRow();

  List<PlutoRow> getNewRows({
    int count = 1,
  });

  void setRowChecked(
    PlutoRow row,
    bool flag, {
    bool notify = true,
  });

  void insertRows(
    int rowIdx,
    List<PlutoRow> rows, {
    bool notify = true,
  });

  void prependNewRows({
    int count = 1,
  });

  void prependRows(List<PlutoRow> rows);

  void appendNewRows({
    int count = 1,
  });

  void appendRows(List<PlutoRow> rows);

  void removeCurrentRow();

  void removeRows(List<PlutoRow> rows);

  void removeAllRows({bool notify = true});

  void moveRowsByOffset(
    List<PlutoRow> rows,
    double offset, {
    bool notify = true,
  });

  void moveRowsByIndex(
    List<PlutoRow> rows,
    int index, {
    bool notify = true,
  });

  void toggleAllRowChecked(
    bool flag, {
    bool notify = true,
  });
}

mixin RowState implements IPlutoGridState {
  @override
  List<PlutoRow> get rows => <PlutoRow>[...refRows];

  @override
  List<PlutoRow> get checkedRows =>
      refRows.where((PlutoRow row) => row.checked!).toList(
            growable: false,
          );

  @override
  List<PlutoRow> get unCheckedRows =>
      refRows.where((PlutoRow row) => !row.checked!).toList(
            growable: false,
          );

  @override
  bool get hasCheckedRow =>
      refRows.firstWhereOrNull((PlutoRow element) => element.checked!) != null;

  @override
  bool get hasUnCheckedRow =>
      refRows.firstWhereOrNull((PlutoRow element) => !element.checked!) != null;

  @override
  bool? get tristateCheckedRow {
    final int length = refRows.length;

    if (length == 0) {
      return false;
    }

    int countTrue = 0;

    int countFalse = 0;

    for (int i = 0; i < length; i += 1) {
      (refRows[i].checked ?? false) ? ++countTrue : ++countFalse;

      if (countTrue > 0 && countFalse > 0) {
        return null;
      }
    }

    return countTrue == length;
  }

  @override
  int? get currentRowIdx => currentCellPosition?.rowIdx;

  @override
  PlutoRow? get currentRow {
    if (currentRowIdx == null) {
      return null;
    }

    return refRows[currentRowIdx!];
  }

  @override
  int? getRowIdxByOffset(double offset) {
    offset -= bodyTopOffset - scroll.verticalOffset;

    double currentOffset = 0.0;

    int? indexToMove;

    final int rowsLength = refRows.length;

    for (int i = 0; i < rowsLength; i += 1) {
      if (currentOffset <= offset && offset < currentOffset + rowTotalHeight) {
        indexToMove = i;
        break;
      }

      currentOffset += rowTotalHeight;
    }

    return indexToMove;
  }

  @override
  PlutoRow? getRowByIdx(int? rowIdx) {
    if (rowIdx == null || rowIdx < 0 || refRows.length - 1 < rowIdx) {
      return null;
    }

    return refRows[rowIdx];
  }

  @override
  PlutoRow getNewRow() {
    final Map<String, PlutoCell> cells = <String, PlutoCell>{};

    for (PlutoColumn column in refColumns) {
      cells[column.field] = PlutoCell(
        value: column.type.defaultValue,
      );
    }

    return PlutoRow(cells: cells);
  }

  @override
  List<PlutoRow> getNewRows({
    int count = 1,
  }) {
    final List<PlutoRow> rows = <PlutoRow>[];

    for (int i = 0; i < count; i += 1) {
      rows.add(getNewRow());
    }

    if (rows.isEmpty) {
      return <PlutoRow>[];
    }

    return rows;
  }

  @override
  void setRowChecked(
    PlutoRow row,
    bool flag, {
    bool notify = true,
  }) {
    final PlutoRow? findRow = refRows.firstWhereOrNull(
      (PlutoRow element) => element.key == row.key,
    );

    if (findRow == null) {
      return;
    }

    findRow.setChecked(flag);

    notifyListeners(notify, setRowChecked.hashCode);
  }

  @override
  void insertRows(
    int rowIdx,
    List<PlutoRow> rows, {
    bool notify = true,
  }) {
    _insertRows(rowIdx, rows);

    /// Update currentRowIdx
    if (currentCell != null) {
      updateCurrentCellPosition(notify: false);

      // todo : whether to apply scrolling.
    }

    /// Update currentSelectingPosition
    if (currentSelectingPosition != null &&
        rowIdx <= currentSelectingPosition!.rowIdx!) {
      setCurrentSelectingPosition(
        cellPosition: PlutoGridCellPosition(
          columnIdx: currentSelectingPosition!.columnIdx,
          rowIdx: rows.length + currentSelectingPosition!.rowIdx!,
        ),
        notify: false,
      );
    }

    notifyListeners(notify, insertRows.hashCode);
  }

  @override
  void prependNewRows({
    int count = 1,
  }) {
    prependRows(getNewRows(count: count));
  }

  @override
  void prependRows(List<PlutoRow> rows) {
    _insertRows(0, rows);

    /// Update currentRowIdx
    if (currentCell != null) {
      setCurrentCellPosition(
        PlutoGridCellPosition(
          columnIdx: currentCellPosition!.columnIdx,
          rowIdx: rows.length + currentRowIdx!,
        ),
        notify: false,
      );

      final double offsetToMove = rows.length * rowTotalHeight;

      scrollByDirection(PlutoMoveDirection.up, offsetToMove);
    }

    /// Update currentSelectingPosition
    if (currentSelectingPosition != null) {
      setCurrentSelectingPosition(
        cellPosition: PlutoGridCellPosition(
          columnIdx: currentSelectingPosition!.columnIdx,
          rowIdx: rows.length + currentSelectingPosition!.rowIdx!,
        ),
        notify: false,
      );
    }

    notifyListeners(true, prependRows.hashCode);
  }

  @override
  void appendNewRows({
    int count = 1,
  }) {
    appendRows(getNewRows(count: count));
  }

  @override
  void appendRows(List<PlutoRow> rows) {
    _insertRows(refRows.length, rows);

    notifyListeners(true, appendRows.hashCode);
  }

  @override
  void removeCurrentRow() {
    if (currentRowIdx == null) {
      return;
    }

    if (enabledRowGroups) {
      removeRowAndGroupByKey(<Key>[currentRow!.key]);
    } else {
      refRows.removeAt(currentRowIdx!);
    }

    resetCurrentState(notify: false);

    notifyListeners(true, removeCurrentRow.hashCode);
  }

  @override
  void removeRows(
    List<PlutoRow> rows, {
    bool notify = true,
  }) {
    if (rows.isEmpty) {
      return;
    }

    final Set<Key> removeKeys = Set.from(rows.map((PlutoRow e) => e.key));

    if (currentRowIdx != null &&
        refRows.length > currentRowIdx! &&
        removeKeys.contains(refRows[currentRowIdx!].key)) {
      resetCurrentState(notify: false);
    }

    Key? selectingCellKey;

    if (hasCurrentSelectingPosition) {
      selectingCellKey = refRows
          .originalList[currentSelectingPosition!.rowIdx!].cells.entries
          .elementAt(currentSelectingPosition!.columnIdx!)
          .value
          .key;
    }

    if (enabledRowGroups) {
      removeRowAndGroupByKey(removeKeys);
    } else {
      refRows.removeWhereFromOriginal(
          (PlutoRow row) => removeKeys.contains(row.key));
    }

    updateCurrentCellPosition(notify: false);

    setCurrentSelectingPositionByCellKey(selectingCellKey, notify: false);

    currentSelectingRows
        .removeWhere((PlutoRow row) => removeKeys.contains(row.key));

    notifyListeners(notify, removeRows.hashCode);
  }

  @override
  void removeAllRows({bool notify = true}) {
    if (refRows.originalList.isEmpty) {
      return;
    }

    refRows.clearFromOriginal();

    resetCurrentState(notify: false);

    notifyListeners(notify, removeAllRows.hashCode);
  }

  @override
  void moveRowsByOffset(
    List<PlutoRow> rows,
    double offset, {
    bool notify = true,
  }) {
    final int? indexToMove = getRowIdxByOffset(offset);

    moveRowsByIndex(rows, indexToMove, notify: notify);
  }

  @override
  void moveRowsByIndex(
    List<PlutoRow> rows,
    int? indexToMove, {
    bool notify = true,
  }) {
    if (rows.isEmpty || indexToMove == null) {
      return;
    }

    if (indexToMove + rows.length > refRows.length) {
      indexToMove = refRows.length - rows.length;
    }

    if (isPaginated &&
        page > 1 &&
        indexToMove + pageRangeFrom > refRows.originalLength - 1) {
      indexToMove = refRows.originalLength - 1;
    }

    final Set<Key> removeKeys = Set.from(rows.map((PlutoRow e) => e.key));

    refRows.removeWhereFromOriginal((PlutoRow e) => removeKeys.contains(e.key));

    refRows.insertAll(indexToMove, rows);

    int sortIdx = 0;

    for (PlutoRow element in refRows.originalList) {
      element.sortIdx = sortIdx++;
    }

    updateCurrentCellPosition(notify: false);

    if (onRowsMoved != null) {
      onRowsMoved!(PlutoGridOnRowsMovedEvent(
        idx: indexToMove,
        rows: rows,
      ));
    }

    notifyListeners(notify, moveRowsByIndex.hashCode);
  }

  @override
  void toggleAllRowChecked(
    bool? flag, {
    bool notify = true,
  }) {
    for (final PlutoRow row in iterateRowAndGroup) {
      row.setChecked(flag == true);
    }

    notifyListeners(notify, toggleAllRowChecked.hashCode);
  }

  void _insertRows(int index, List<PlutoRow> rows) {
    if (rows.isEmpty) {
      return;
    }

    final int safetyIndex = _getSafetyIndexForInsert(index);

    if (enabledRowGroups) {
      insertRowGroup(safetyIndex, rows);
    } else {
      final bool append = refRows.isNotEmpty && index >= refRows.length;
      final int targetIdx = append ? refRows.length - 1 : safetyIndex;
      final PlutoRow? target = refRows.isEmpty ? null : refRows[targetIdx];
      int sortIdx = target?.sortIdx ?? 0;
      if (append) {
        ++sortIdx;
      }

      _setSortIdx(rows: rows, start: sortIdx);

      if (hasSortedColumn) {
        _increaseSortIdxGreaterThanOrEqual(
          rows: refRows.originalList,
          compare: sortIdx,
          increase: rows.length,
        );
      } else if (!append) {
        _increaseSortIdx(
          rows: refRows.originalList,
          start: target == null ? 0 : refRows.originalList.indexOf(target),
          increase: rows.length,
        );
      }

      for (final PlutoRow row in rows) {
        row.setState(PlutoRowState.added);
      }

      refRows.insertAll(safetyIndex, rows);

      PlutoGridStateManager.initializeRows(
        refColumns,
        rows,
        forceApplySortIdx: false,
      );
    }

    if (isPaginated) {
      resetPage(notify: false);
    }
  }

  int _getSafetyIndexForInsert(int index) {
    if (index < 0) {
      return 0;
    }

    if (index > refRows.length) {
      return refRows.length;
    }

    return index;
  }

  void _setSortIdx({
    required List<PlutoRow> rows,
    int start = 0,
  }) {
    for (final PlutoRow row in rows) {
      row.sortIdx = start++;
    }
  }

  void _increaseSortIdx({
    required List<PlutoRow> rows,
    int start = 0,
    int increase = 1,
  }) {
    final int length = rows.length;

    for (int i = start; i < length; i += 1) {
      rows[i].sortIdx += increase;
    }
  }

  void _increaseSortIdxGreaterThanOrEqual({
    required List<PlutoRow> rows,
    int compare = 0,
    int increase = 1,
  }) {
    for (final PlutoRow row in rows) {
      if (row.sortIdx < compare) {
        continue;
      }

      row.sortIdx += increase;
    }
  }
}
