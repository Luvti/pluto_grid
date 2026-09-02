import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:pluto_grid_plus/src/manager/event/pluto_grid_row_hover_event.dart';

import 'columns/pluto_column_resize_handle.dart';
import 'ui.dart';

class PlutoBaseRow extends StatelessWidget {
  final int rowIdx;

  final PlutoRow row;

  final List<PlutoColumn> columns;

  final PlutoGridStateManager stateManager;

  final bool visibilityLayout;

  final bool showTrailingResizeGutter;

  const PlutoBaseRow({
    required this.rowIdx,
    required this.row,
    required this.columns,
    required this.stateManager,
    this.visibilityLayout = false,
    this.showTrailingResizeGutter = false,
    super.key,
  });

  bool _checkSameDragRows(DragTargetDetails<PlutoRow> draggingRow) {
    final List<PlutoRow> selectedRows =
        stateManager.currentSelectingRows.isNotEmpty
        ? stateManager.currentSelectingRows
        : <PlutoRow>[draggingRow.data];

    final int end = rowIdx + selectedRows.length;

    for (int i = rowIdx; i < end; i += 1) {
      if (stateManager.refRows[i].key != selectedRows[i - rowIdx].key) {
        return false;
      }
    }

    return true;
  }

  bool _handleOnWillAccept(DragTargetDetails<PlutoRow> draggingRow) {
    return !_checkSameDragRows(draggingRow);
  }

  void _handleOnAccept(DragTargetDetails<PlutoRow> draggingRow) async {
    final List<PlutoRow> draggingRows =
        stateManager.currentSelectingRows.isNotEmpty
        ? stateManager.currentSelectingRows
        : <PlutoRow>[draggingRow.data];

    stateManager.eventManager!.addEvent(
      PlutoGridDragRowsEvent(
        rows: draggingRows,
        targetIdx: rowIdx,
      ),
    );
  }

  PlutoVisibilityLayoutId _makeCell(PlutoColumn column) {
    final int columnIndex = columns.indexWhere(
      (PlutoColumn candidate) => candidate.key == column.key,
    );
    final PlutoColumn? leadingResizeColumn = columnIndex > 0
        ? columns[columnIndex - 1]
        : null;

    // check exist and more readable warning
    if (!row.cells.containsKey(column.field)) {
      debugPrint(
        'PlutoGrid: The cell with field "${column.field}" does not exist in the row.',
      );
      PlutoCell cell =
          PlutoCell(
              key: ValueKey<String>('missingCell_${column.field}'),
            )
            ..setColumn(column)
            ..setRow(row);
      return PlutoVisibilityLayoutId(
        id: column.field,
        child: PlutoBaseCell(
          key: ValueKey<String>('missingCell_${column.field}'),
          cell: cell,
          column: column,
          leadingResizeColumn: leadingResizeColumn,
          rowIdx: rowIdx,
          row: row,
          stateManager: stateManager,
        ),
      );
    }
    return PlutoVisibilityLayoutId(
      id: column.field,
      child: PlutoBaseCell(
        key: row.cells[column.field]!.key,
        cell: row.cells[column.field]!,
        column: column,
        leadingResizeColumn: leadingResizeColumn,
        rowIdx: rowIdx,
        row: row,
        stateManager: stateManager,
      ),
    );
  }

  List<PlutoVisibilityLayoutId> _makeCells() {
    final List<PlutoVisibilityLayoutId> cells = columns
        .map(_makeCell)
        .toList(growable: true);

    if (showTrailingResizeGutter &&
        columns.isNotEmpty &&
        columns.last.enableDropToResize &&
        !stateManager.columnsResizeMode.isNone &&
        PlutoColumnResizeHandle.usesCellHandle(
          stateManager,
          columns.last,
        )) {
      final PlutoColumn trailingColumn = columns.last;
      cells.add(
        PlutoVisibilityLayoutId(
          id: PlutoColumnResizeGutter.layoutId,
          child: PlutoColumnResizeGutter(
            key: ValueKey<String>('cell_resize_trailing_gutter_$rowIdx'),
            handleKey: ValueKey<String>(
              'cell_resize_handle_end_gutter_'
              '${trailingColumn.field}_$rowIdx',
            ),
            stateManager: stateManager,
            column: trailingColumn,
            boundaryPosition: columns.fold<double>(
              0,
              (double width, PlutoColumn column) => width + column.width,
            ),
          ),
        ),
      );
    }

    return cells;
  }

  Widget _dragTargetBuilder(BuildContext dragContext, candidate, rejected) {
    final List<PlutoVisibilityLayoutId> cells = _makeCells();

    return _RowContainerWidget(
      stateManager: stateManager,
      rowIdx: rowIdx,
      row: row,
      enableRowColorAnimation:
          stateManager.configuration.style.enableRowColorAnimation,
      key: ValueKey('rowContainer_${row.key}'),
      child: visibilityLayout
          ? PlutoVisibilityLayout(
              key: ValueKey('rowContainer_${row.key}_row'),
              delegate: _RowCellsLayoutDelegate(
                stateManager: stateManager,
                columns: columns,
                textDirection: stateManager.textDirection,
                showTrailingResizeGutter: showTrailingResizeGutter,
              ),
              scrollController: stateManager.scroll.bodyRowsHorizontal!,
              initialViewportDimension: MediaQuery.sizeOf(dragContext).width,
              children: cells,
            )
          : CustomMultiChildLayout(
              key: ValueKey('rowContainer_${row.key}_row'),
              delegate: _RowCellsLayoutDelegate(
                stateManager: stateManager,
                columns: columns,
                textDirection: stateManager.textDirection,
                showTrailingResizeGutter: showTrailingResizeGutter,
              ),
              children: cells,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<PlutoRow>(
      onWillAcceptWithDetails: _handleOnWillAccept,
      onAcceptWithDetails: _handleOnAccept,
      builder: _dragTargetBuilder,
    );
  }
}

class _RowCellsLayoutDelegate extends MultiChildLayoutDelegate {
  final PlutoGridStateManager stateManager;

  final List<PlutoColumn> columns;

  final TextDirection textDirection;

  final bool showTrailingResizeGutter;

  _RowCellsLayoutDelegate({
    required this.stateManager,
    required this.columns,
    required this.textDirection,
    required this.showTrailingResizeGutter,
  }) : super(relayout: stateManager.resizingChangeNotifier);

  bool get _showTrailingResizeGutter =>
      showTrailingResizeGutter &&
      columns.isNotEmpty &&
      columns.last.enableDropToResize &&
      !stateManager.columnsResizeMode.isNone;

  double get _trailingGutterWidth => _showTrailingResizeGutter
      ? stateManager.style.columnResizeHandleWidth / 2
      : 0;

  @override
  Size getSize(BoxConstraints constraints) {
    double width = _trailingGutterWidth;
    for (final PlutoColumn column in columns) {
      width += column.width;
    }

    return Size(width, stateManager.rowHeight);
  }

  @override
  void performLayout(Size size) {
    final bool isLTR = textDirection == TextDirection.ltr;
    final Iterable<PlutoColumn> items = isLTR ? columns : columns.reversed;
    double dx = isLTR ? 0 : _trailingGutterWidth;

    for (PlutoColumn element in items) {
      double width = element.width;

      if (hasChild(element.field)) {
        layoutChild(
          element.field,
          BoxConstraints.tightFor(
            width: width,
            height: stateManager.rowHeight,
          ),
        );

        positionChild(
          element.field,
          Offset(dx, 0),
        );
      }

      dx += width;
    }

    if (_showTrailingResizeGutter &&
        hasChild(PlutoColumnResizeGutter.layoutId)) {
      layoutChild(
        PlutoColumnResizeGutter.layoutId,
        BoxConstraints.tightFor(
          width: _trailingGutterWidth,
          height: stateManager.rowHeight,
        ),
      );
      positionChild(
        PlutoColumnResizeGutter.layoutId,
        Offset(isLTR ? size.width - _trailingGutterWidth : 0, 0),
      );
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}

class _RowContainerWidget extends PlutoStatefulWidget {
  final PlutoGridStateManager stateManager;

  final int rowIdx;

  final PlutoRow row;

  final bool enableRowColorAnimation;

  final Widget child;

  const _RowContainerWidget({
    required this.stateManager,
    required this.rowIdx,
    required this.row,
    required this.enableRowColorAnimation,
    required this.child,
    super.key,
  });

  @override
  State<_RowContainerWidget> createState() => _RowContainerWidgetState();
}

class _RowContainerWidgetState extends PlutoStateWithChange<_RowContainerWidget>
    with
        AutomaticKeepAliveClientMixin,
        PlutoStateWithKeepAlive<_RowContainerWidget> {
  @override
  PlutoGridStateManager get stateManager => widget.stateManager;

  BoxDecoration _decoration = const BoxDecoration();

  bool _isHovered = false;

  Color get _oddRowColor => stateManager.configuration.style.oddRowColor == null
      ? stateManager.configuration.style.rowColor
      : stateManager.configuration.style.oddRowColor!;

  Color get _evenRowColor =>
      stateManager.configuration.style.evenRowColor == null
      ? stateManager.configuration.style.rowColor
      : stateManager.configuration.style.evenRowColor!;

  @override
  void initState() {
    super.initState();

    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  @override
  void updateState(PlutoNotifierEvent event) {
    _decoration = update<BoxDecoration>(
      _decoration,
      _getBoxDecoration(),
    );

    setKeepAlive(
      stateManager.isSelecting && stateManager.currentRowIdx == widget.rowIdx,
    );
  }

  Color _getDefaultRowColor() {
    if (stateManager.rowColorCallback == null) {
      return widget.rowIdx % 2 == 0 ? _oddRowColor : _evenRowColor;
    }

    return stateManager.rowColorCallback!(
      PlutoRowColorContext(
        rowIdx: widget.rowIdx,
        row: widget.row,
        stateManager: stateManager,
      ),
    );
  }

  Color _getRowColor({
    required bool isDragTarget,
    required bool isFocusedCurrentRow,
    required bool isSelecting,
    required bool hasCurrentSelectingPosition,
    required bool isCheckedRow,
    required bool isHovered,
  }) {
    Color color = _getDefaultRowColor();

    if (isDragTarget) {
      color = stateManager.configuration.style.cellColorInReadOnlyState;
    } else {
      final bool checkCurrentRow =
          !stateManager.selectingMode.isRow &&
          isFocusedCurrentRow &&
          (!isSelecting && !hasCurrentSelectingPosition);

      final bool checkSelectedRow =
          stateManager.selectingMode.isRow &&
          stateManager.isSelectedRow(widget.row.key);

      if (checkCurrentRow || checkSelectedRow) {
        color = stateManager.configuration.style.activatedColor;
      } else {
        // If the row is checked, the hover color is not applied.
        // If the row is hovered and hover color is enabled,
        // the configuration hover color is used.
        bool enableRowHoverColor =
            stateManager.configuration.style.enableRowHoverColor;
        if (isHovered && enableRowHoverColor) {
          color = stateManager.configuration.style.rowHoveredColor;
        }
      }
    }

    return isCheckedRow
        ? Color.alphaBlend(
            stateManager.configuration.style.rowCheckedColor,
            color,
          )
        : color;
  }

  BoxDecoration _getBoxDecoration() {
    final bool isCurrentRow = stateManager.currentRowIdx == widget.rowIdx;

    final bool isSelecting = stateManager.isSelecting;

    final bool isCheckedRow = widget.row.checked == true;

    final bool alreadyTarget =
        stateManager.dragRows.firstWhereOrNull(
          (PlutoRow element) => element.key == widget.row.key,
        ) !=
        null;

    final bool isDraggingRow = stateManager.isDraggingRow;

    final bool isDragTarget =
        isDraggingRow &&
        !alreadyTarget &&
        stateManager.isRowIdxDragTarget(widget.rowIdx);

    final bool isTopDragTarget =
        isDraggingRow && stateManager.isRowIdxTopDragTarget(widget.rowIdx);

    final bool isBottomDragTarget =
        isDraggingRow && stateManager.isRowIdxBottomDragTarget(widget.rowIdx);

    final bool hasCurrentSelectingPosition =
        stateManager.hasCurrentSelectingPosition;

    final bool isFocusedCurrentRow = isCurrentRow && stateManager.hasFocus;

    final Color rowColor = _getRowColor(
      isDragTarget: isDragTarget,
      isFocusedCurrentRow: isFocusedCurrentRow,
      isSelecting: isSelecting,
      hasCurrentSelectingPosition: hasCurrentSelectingPosition,
      isCheckedRow: isCheckedRow,
      isHovered: _isHovered,
    );

    return BoxDecoration(
      color: rowColor,
      border: Border(
        top: isTopDragTarget
            ? BorderSide(
                width: stateManager.configuration.style.rowBorderWidth,
                color: stateManager.configuration.style.activatedBorderColor,
              )
            : BorderSide.none,
        bottom: isBottomDragTarget
            ? BorderSide(
                width: stateManager.configuration.style.rowBorderWidth,
                color: stateManager.configuration.style.activatedBorderColor,
              )
            : stateManager.configuration.style.enableCellBorderHorizontal
            ? BorderSide(
                width: stateManager.configuration.style.rowBorderWidth,
                color: stateManager.configuration.style.borderColor,
              )
            : BorderSide.none,
      ),
    );
  }

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }

    setState(() {
      _isHovered = value;
      _decoration = _getBoxDecoration();
    });

    stateManager.eventManager!.addEvent(
      PlutoGridRowHoverEvent(
        rowIdx: widget.rowIdx,
        isHovered: value,
        notifyStateManager: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MouseRegion(
      key: ValueKey<String>('row_hover_${widget.row.key}'),
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: _AnimatedOrNormalContainer(
        enable: widget.enableRowColorAnimation,
        decoration: _decoration,
        child: widget.child,
      ),
    );
  }
}

class _AnimatedOrNormalContainer extends StatelessWidget {
  final bool enable;

  final Widget child;

  final BoxDecoration decoration;

  const _AnimatedOrNormalContainer({
    required this.enable,
    required this.child,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return enable
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: decoration,
            child: child,
          )
        : DecoratedBox(decoration: decoration, child: child);
  }
}
