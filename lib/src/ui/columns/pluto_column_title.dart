import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import '../ui.dart';
import 'pluto_column_resize_handle.dart';

class PlutoColumnTitle extends PlutoStatefulWidget {
  final PlutoGridStateManager stateManager;

  final PlutoColumn column;

  final PlutoColumn? leadingResizeColumn;

  late final double height;

  PlutoColumnTitle({
    required this.stateManager,
    required this.column,
    this.leadingResizeColumn,
    double? height,
  }) : height = height ?? stateManager.columnHeight,
       super(key: ValueKey('column_title_${column.key}'));

  @override
  PlutoColumnTitleState createState() => PlutoColumnTitleState();
}

class PlutoColumnTitleState extends PlutoStateWithChange<PlutoColumnTitle> {
  late Offset _columnRightPosition;

  bool _isPointMoving = false;

  PlutoColumnSort? _sort;

  bool get showActionIcon =>
      widget.column.resolveShowColumnHeaderIcon(stateManager.style) &&
      (widget.column.enableContextMenu || widget.column.enableDropToResize);

  bool get showRightIcon {
    _sort ??= widget.column.sort;
    return showActionIcon || !_sort!.isNone;
  }

  bool get showResizeHandle =>
      widget.column.enableDropToResize &&
      !stateManager.columnsResizeMode.isNone;

  PlutoColumn? get leadingResizeColumn =>
      !stateManager.columnsResizeMode.isNone &&
          widget.leadingResizeColumn?.enableDropToResize == true
      ? widget.leadingResizeColumn
      : null;

  bool get enableGesture {
    return widget.column.enableContextMenu || widget.column.enableDropToResize;
  }

  MouseCursor get contextMenuCursor {
    if (enableGesture) {
      return widget.column.enableDropToResize
          ? SystemMouseCursors.resizeLeftRight
          : SystemMouseCursors.click;
    }

    return SystemMouseCursors.basic;
  }

  @override
  PlutoGridStateManager get stateManager => widget.stateManager;

  @override
  void initState() {
    super.initState();
    _sort ??= widget.column.sort;

    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  @override
  void updateState(PlutoNotifierEvent event) {
    _sort ??= widget.column.sort;
    _sort = update<PlutoColumnSort>(_sort!, widget.column.sort);
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    ShapeBorder? shape,
  ) async {
    final selected = await showColumnMenu(
      context: context,
      position: position,
      backgroundColor: stateManager.style.menuBackgroundColor,
      shape: shape,
      items: stateManager.columnMenuDelegate.buildMenuItems(
        stateManager: stateManager,
        column: widget.column,
      ),
    );

    if (context.mounted) {
      stateManager.columnMenuDelegate.onSelected(
        context: context,
        stateManager: stateManager,
        column: widget.column,
        mounted: mounted,
        selected: selected,
      );
    }
  }

  void _handleOnPointDown(PointerDownEvent event) {
    _isPointMoving = false;

    _columnRightPosition = event.position;
  }

  void _handleOnPointMove(PointerMoveEvent event) {
    // if at least one movement event has distanceSquared > 0.5 _isPointMoving will be true
    _isPointMoving |=
        (_columnRightPosition - event.position).distanceSquared > 0.5;

    if (!_isPointMoving) return;

    final double moveOffset = event.position.dx - _columnRightPosition.dx;

    final bool isLTR = stateManager.isLTR;

    stateManager.resizeColumn(widget.column, isLTR ? moveOffset : -moveOffset);

    _columnRightPosition = event.position;
  }

  void _handleOnPointUp(
    BuildContext context,
    PointerUpEvent event,
    ShapeBorder? shape,
  ) {
    if (_isPointMoving) {
      stateManager.updateCorrectScrollOffset();
    } else if (mounted && widget.column.enableContextMenu) {
      _showContextMenu(context, event.position, shape);
    }

    _isPointMoving = false;
  }

  void _handleOnPointCancel(PointerCancelEvent event) {
    _isPointMoving = false;
  }

  @override
  Widget build(BuildContext context) {
    final PlutoGridStyleConfig style = stateManager.configuration.style;
    final bool shouldShowRightIcon = showRightIcon;
    final double resizeHandleInset = showResizeHandle
        ? style.columnResizeHandleWidth / 2
        : 0;
    final double actionIconSpacing = shouldShowRightIcon
        ? style.iconSize + resizeHandleInset
        : 0;
    final _SortableWidget columnWidget = _SortableWidget(
      stateManager: stateManager,
      column: widget.column,
      child: _ColumnWidget(
        stateManager: stateManager,
        column: widget.column,
        height: widget.height,
        actionIconSpacing: actionIconSpacing,
      ),
    );

    return Theme(
      data: Theme.of(context).copyWith(splashFactory: InkRipple.splashFactory),
      child: Builder(
        builder: (BuildContext themedContext) {
          final ThemeData theme = Theme.of(themedContext);

          // Keep the painted action and its hit test at iconSize. A default
          // IconButton is 48 px wide and would overlap the adjacent filter
          // action even though the header reserves only the compact icon slot.
          final Widget contextMenuIcon = MouseRegion(
            cursor: showActionIcon
                ? contextMenuCursor
                : SystemMouseCursors.basic,
            child: SizedBox(
              key: ValueKey<String>(
                'column_header_action_${widget.column.field}',
              ),
              width: style.iconSize,
              height: widget.height,
              child: Center(
                child: IconTheme(
                  data: IconThemeData(size: style.iconSize),
                  child: PlutoGridColumnIcon(
                    sort: _sort,
                    color: style.iconColor,
                    icon: widget.column.enableContextMenu
                        ? style.columnContextIcon
                        : style.columnResizeIcon,
                    ascendingIcon: style.columnAscendingIcon,
                    descendingIcon: style.columnDescendingIcon,
                    successColor: style.activatedColor,
                    errorColor:
                        style.removeIconColor ?? theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          );

          Offset position = Offset.zero;
          final PlutoColumn? leadingColumn = leadingResizeColumn;

          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                child: widget.column.enableColumnDrag
                    ? Listener(
                        onPointerUp: (PointerUpEvent event) {
                          position = event.position;
                        },
                        child: GestureDetector(
                          onSecondaryTap: () {
                            if (mounted && widget.column.enableContextMenu) {
                              _showContextMenu(themedContext, position, null);
                            }
                          },
                          child: _DraggableWidget(
                            stateManager: stateManager,
                            column: widget.column,
                            child: columnWidget,
                          ),
                        ),
                      )
                    : columnWidget,
              ),
              if (shouldShowRightIcon)
                Positioned.directional(
                  textDirection: stateManager.textDirection,
                  end: resizeHandleInset,
                  child: showActionIcon && enableGesture
                      ? Listener(
                          onPointerDown: _handleOnPointDown,
                          onPointerMove: _handleOnPointMove,
                          onPointerUp: (PointerUpEvent event) =>
                              _handleOnPointUp(
                                themedContext,
                                event,
                                RoundedRectangleBorder(
                                  borderRadius:
                                      widget
                                          .stateManager
                                          .gridPopupBorderRadius ??
                                      BorderRadius.zero,
                                ),
                              ),
                          onPointerCancel: _handleOnPointCancel,
                          child: contextMenuIcon,
                        )
                      : contextMenuIcon,
                ),
              if (showResizeHandle)
                Positioned.directional(
                  textDirection: stateManager.textDirection,
                  top: 0,
                  bottom: 0,
                  end: 0,
                  width: style.columnResizeHandleWidth / 2,
                  child: PlutoColumnResizeHandle(
                    key: ValueKey<String>(
                      'column_resize_handle_${widget.column.field}',
                    ),
                    stateManager: stateManager,
                    column: widget.column,
                  ),
                ),
              if (leadingColumn != null)
                Positioned.directional(
                  textDirection: stateManager.textDirection,
                  top: 0,
                  bottom: 0,
                  start: 0,
                  width: style.columnResizeHandleWidth / 2,
                  child: PlutoColumnResizeHandle(
                    key: ValueKey<String>(
                      'column_resize_handle_start_${widget.column.field}_for_'
                      '${leadingColumn.field}',
                    ),
                    stateManager: stateManager,
                    column: leadingColumn,
                    side: PlutoColumnResizeHandleSide.start,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class PlutoGridColumnIcon extends StatelessWidget {
  final PlutoColumnSort? sort;

  final Color color;

  final IconData icon;

  final Icon? ascendingIcon;

  final Icon? descendingIcon;
  final Color successColor;
  final Color errorColor;

  const PlutoGridColumnIcon({
    this.sort,
    this.color = Colors.black26,
    this.icon = Icons.dehaze,
    this.ascendingIcon,
    this.descendingIcon,
    this.successColor = Colors.green,
    this.errorColor = Colors.red,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    switch (sort) {
      case PlutoColumnSort.ascending:
        return ascendingIcon == null
            ? Transform.rotate(
                angle: 90 * pi / 90,
                child: Icon(Icons.sort, color: successColor),
              )
            : ascendingIcon!;
      case PlutoColumnSort.descending:
        return descendingIcon == null
            ? Icon(Icons.sort, color: errorColor)
            : descendingIcon!;
      default:
        return Icon(icon, color: color);
    }
  }
}

class _DraggableWidget extends StatelessWidget {
  final PlutoGridStateManager stateManager;

  final PlutoColumn column;

  final Widget child;

  const _DraggableWidget({
    required this.stateManager,
    required this.column,
    required this.child,
  });

  void _handleOnPointerMove(PointerMoveEvent event) {
    stateManager.eventManager!.addEvent(
      PlutoGridScrollUpdateEvent(
        offset: event.position,
        scrollDirection: PlutoGridScrollUpdateDirection.horizontal,
      ),
    );
  }

  void _handleOnPointerUp(PointerUpEvent event) {
    PlutoGridScrollUpdateEvent.stopScroll(
      stateManager,
      PlutoGridScrollUpdateDirection.horizontal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: _handleOnPointerMove,
      onPointerUp: _handleOnPointerUp,
      child: Draggable<PlutoColumn>(
        data: column,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: PlutoShadowContainer(
            alignment: column.titleTextAlign.alignmentValue,
            width: PlutoGridSettings.minColumnWidth,
            height: stateManager.columnHeight,
            backgroundColor:
                stateManager.configuration.style.gridBackgroundColor,
            borderColor: stateManager.configuration.style.gridBorderColor,
            child: Text(
              column.title,
              style: stateManager.configuration.style.columnHeaderTextStyle
                  ?.copyWith(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _SortableWidget extends StatelessWidget {
  final PlutoGridStateManager stateManager;

  final PlutoColumn column;

  final Widget child;

  const _SortableWidget({
    required this.stateManager,
    required this.column,
    required this.child,
  });

  void _onTap() {
    stateManager.toggleSortColumn(column);
  }

  @override
  Widget build(BuildContext context) {
    return column.enableSorting
        ? MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              key: const ValueKey('ColumnTitleSortableGesture'),
              onTap: _onTap,
              onDoubleTap: _onTap,
              child: child,
            ),
          )
        : child;
  }
}

class _ColumnWidget extends StatelessWidget {
  final PlutoGridStateManager stateManager;

  final PlutoColumn column;

  final double height;

  final double actionIconSpacing;

  const _ColumnWidget({
    required this.stateManager,
    required this.column,
    required this.height,
    required this.actionIconSpacing,
  });

  EdgeInsets get padding =>
      column.titlePadding ??
      stateManager.configuration.style.defaultColumnTitlePadding;

  @override
  Widget build(BuildContext context) {
    return DragTarget<PlutoColumn>(
      onWillAcceptWithDetails: (DragTargetDetails<PlutoColumn> columnToDrag) {
        return columnToDrag.data.key != column.key &&
            !stateManager.limitMoveColumn(
              column: columnToDrag.data,
              targetColumn: column,
            );
      },
      onAcceptWithDetails: (DragTargetDetails<PlutoColumn> columnToMove) {
        if (columnToMove.data.key != column.key) {
          stateManager.moveColumn(
            column: columnToMove.data,
            targetColumn: column,
          );
        }
      },
      builder:
          (
            BuildContext dragContext,
            List<PlutoColumn?> candidate,
            List rejected,
          ) {
            final bool noDragTarget = candidate.isEmpty;

            final PlutoGridStyleConfig style = stateManager.style;
            final bool haveCheckbox =
                column.enableRowChecked &&
                column.rowCheckBoxGroupDepth == 0 &&
                column.enableTitleChecked;
            return SizedBox(
              width: column.width,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: column.backgroundGradient, //
                  color: column.backgroundGradient == null
                      ? (noDragTarget
                            ? column.backgroundColor
                            : style.dragTargetColumnColor)
                      : null,
                  border: BorderDirectional(
                    end: style.enableColumnBorderVertical
                        ? BorderSide(
                            color: style.borderColor,
                            width: style.columnBorderWidth,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: Padding(
                  padding: haveCheckbox ? padding.copyWith(left: 0) : padding,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: <Widget>[
                        if (haveCheckbox)
                          CheckboxAllSelectionWidget(
                            stateManager: stateManager,
                          ),
                        Expanded(
                          child: _ColumnTextWidget(
                            column: column,
                            stateManager: stateManager,
                            actionIconSpacing: actionIconSpacing,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
    );
  }
}

class CheckboxAllSelectionWidget extends PlutoStatefulWidget {
  final PlutoGridStateManager stateManager;

  const CheckboxAllSelectionWidget({required this.stateManager, super.key});

  @override
  CheckboxAllSelectionWidgetState createState() =>
      CheckboxAllSelectionWidgetState();
}

class CheckboxAllSelectionWidgetState
    extends PlutoStateWithChange<CheckboxAllSelectionWidget> {
  bool? _checked;

  @override
  PlutoGridStateManager get stateManager => widget.stateManager;

  @override
  void initState() {
    super.initState();

    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  @override
  void updateState(PlutoNotifierEvent event) {
    _checked = update<bool?>(_checked, stateManager.tristateCheckedRow);
  }

  void _handleOnChanged(bool? changed) {
    if (changed == _checked) {
      return;
    }

    changed ??= false;

    if (_checked == null) changed = true;

    if (_checked == null) changed = true;

    stateManager.toggleAllRowChecked(changed);

    if (stateManager.onRowChecked != null) {
      stateManager.onRowChecked!(
        PlutoGridOnRowCheckedAllEvent(isChecked: changed),
      );
    }

    setState(() {
      _checked = changed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlutoScaledCheckbox(
      value: _checked,
      handleOnChanged: _handleOnChanged,
      tristate: true,
      scale: 0.86,
      unselectedColor: stateManager.configuration.style.columnUnselectedColor,
      activeColor: stateManager.configuration.style.columnActiveColor,
      checkColor: stateManager.configuration.style.columnCheckedColor,
    );
  }
}

class _ColumnTextWidget extends PlutoStatefulWidget {
  final PlutoGridStateManager stateManager;

  final PlutoColumn column;

  final double actionIconSpacing;

  const _ColumnTextWidget({
    required this.stateManager,
    required this.column,
    required this.actionIconSpacing,
  });

  @override
  _ColumnTextWidgetState createState() => _ColumnTextWidgetState();
}

class _ColumnTextWidgetState extends PlutoStateWithChange<_ColumnTextWidget> {
  static const double _filterTapMovementTolerance = 4;

  bool _isFilteredList = false;

  int? _filterPointer;

  Offset? _filterPointerDownPosition;

  bool _filterPointerMoved = false;

  @override
  PlutoGridStateManager get stateManager => widget.stateManager;

  @override
  void initState() {
    super.initState();

    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  @override
  void updateState(PlutoNotifierEvent event) {
    _isFilteredList = update<bool>(
      _isFilteredList,
      stateManager.isFilteredColumn(widget.column),
    );
  }

  String? get _title =>
      widget.column.titleSpan == null ? widget.column.title : null;

  List<InlineSpan> get _children => <InlineSpan>[
    if (widget.column.titleSpan != null) widget.column.titleSpan!,
  ];

  bool get _showFilterIcon =>
      widget.column.resolveShowColumnFilterIcon(stateManager.style) &&
      (_isFilteredList ||
          widget.column.filterIconRenderer != null ||
          widget.column.onFilterIconTap != null ||
          stateManager.showFilterPopupCustom != null);

  PlutoColumnFilterIconContext _filterIconContext(BuildContext context) =>
      PlutoColumnFilterIconContext(
        buildContext: context,
        column: widget.column,
        stateManager: stateManager,
      );

  void _handleFilterIconTap(BuildContext context) {
    final PlutoColumnFilterIconContext filterIconContext = _filterIconContext(
      context,
    );
    final PlutoColumnFilterIconTapCallback? onTap =
        widget.column.onFilterIconTap;

    if (onTap != null) {
      onTap(filterIconContext);
      return;
    }

    filterIconContext.showFilterPopup();
  }

  void _handleFilterPointerDown(PointerDownEvent event) {
    if ((event.buttons & kPrimaryButton) == 0) {
      return;
    }

    _filterPointer = event.pointer;
    _filterPointerDownPosition = event.position;
    _filterPointerMoved = false;
  }

  void _handleFilterPointerMove(PointerMoveEvent event) {
    if (_filterPointer != event.pointer || _filterPointerDownPosition == null) {
      return;
    }

    _filterPointerMoved |=
        (event.position - _filterPointerDownPosition!).distanceSquared >
        _filterTapMovementTolerance * _filterTapMovementTolerance;
  }

  void _handleFilterPointerUp(
    BuildContext context,
    PointerUpEvent event,
  ) {
    if (_filterPointer == event.pointer && !_filterPointerMoved) {
      _handleFilterIconTap(context);
    }

    _resetFilterPointer();
  }

  void _handleFilterPointerCancel(PointerCancelEvent event) {
    if (_filterPointer == event.pointer) {
      _resetFilterPointer();
    }
  }

  void _resetFilterPointer() {
    _filterPointer = null;
    _filterPointerDownPosition = null;
    _filterPointerMoved = false;
  }

  Widget _buildFilterIcon(
    BuildContext context,
    PlutoGridStyleConfig style,
  ) {
    final PlutoColumnFilterIconContext filterIconContext = _filterIconContext(
      context,
    );
    final Widget icon =
        widget.column.filterIconRenderer?.call(filterIconContext) ??
        Icon(
          style.columnFilterIcon,
          color: style.iconColor,
          size: style.iconSize,
        );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: RawGestureDetector(
        key: ValueKey<String>('column_filter_icon_${widget.column.field}'),
        behavior: HitTestBehavior.opaque,
        // Claim the icon's compact hit area before the surrounding sortable or
        // draggable header can consume the tap. Raw pointer tracking below
        // still rejects a drag that started on the icon.
        gestures: <Type, GestureRecognizerFactory>{
          EagerGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                EagerGestureRecognizer.new,
                (EagerGestureRecognizer recognizer) {},
              ),
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handleFilterPointerDown,
          onPointerMove: _handleFilterPointerMove,
          onPointerUp: (PointerUpEvent event) =>
              _handleFilterPointerUp(context, event),
          onPointerCancel: _handleFilterPointerCancel,
          child: Semantics(
            button: true,
            label: stateManager.localeText.setFilter,
            onTap: () => _handleFilterIconTap(context),
            child: SizedBox.square(dimension: style.iconSize, child: icon),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PlutoGridStyleConfig style = stateManager.style;

    return Row(
      children: <Widget>[
        // A tight text region keeps alignment deterministic and places all
        // visible header controls at the directional end of the column.
        Expanded(
          child: Text.rich(
            key: ValueKey<String>('column_header_text_${widget.column.field}'),
            TextSpan(
              text: _title,
              children: _children,
              style: stateManager.configuration.style.columnHeaderTextStyle,
            ),
            style: stateManager.configuration.style.columnHeaderTextStyle,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            maxLines: 2,
            textAlign: widget.column.titleTextAlign.value,
          ),
        ),
        if (_showFilterIcon)
          // Builder supplies the icon's exact context, which lets custom
          // callbacks anchor an OverlayEntry to this action.
          Builder(
            builder: (BuildContext filterIconContext) =>
                _buildFilterIcon(filterIconContext, style),
          ),
        if (widget.actionIconSpacing > 0)
          SizedBox(
            key: ValueKey<String>(
              'column_header_action_spacer_${widget.column.field}',
            ),
            width: widget.actionIconSpacing,
          ),
      ],
    );
  }
}
