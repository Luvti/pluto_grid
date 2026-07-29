import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart'
    show
        computePanSlop,
        kDoubleTapMinTime,
        kDoubleTapSlop,
        kDoubleTapTimeout,
        kPrimaryButton;
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import 'package:pluto_grid_plus/src/ui/miscellaneous/pluto_visibility_layout.dart';

/// Geometry published by a resize handle for the grid-level guide overlay.
class PlutoColumnResizeIndicatorData {
  final Object source;

  final PlutoColumn column;

  final PlutoColumnResizeIndicatorMode mode;

  final double x;

  const PlutoColumnResizeIndicatorData({
    required this.source,
    required this.column,
    required this.mode,
    required this.x,
  });
}

/// Shows or hides the grid-level resize guide owned by [source].
///
/// Associating every notification with its source prevents a stale handle
/// from hiding the guide that a newer hovered handle has already shown.
class PlutoColumnResizeIndicatorNotification extends Notification {
  final PlutoColumnResizeIndicatorData? data;

  final Object source;

  PlutoColumnResizeIndicatorNotification.show({
    required PlutoColumnResizeIndicatorData this.data,
  }) : source = data.source;

  PlutoColumnResizeIndicatorNotification.hide({
    required this.source,
  }) : data = null;
}

enum PlutoColumnResizeHandleSide {
  start,
  end,
}

/// One half of an invisible interaction target centered on a column boundary.
///
/// It supports hover feedback, drag-to-resize, and double-tap auto-fit without
/// requiring the painted divider itself to be wide.
class PlutoColumnResizeHandle extends StatefulWidget {
  final PlutoGridStateManager stateManager;

  final PlutoColumn column;

  /// The directional edge of this half-handle that touches the boundary.
  ///
  /// A column paints the [PlutoColumnResizeHandleSide.end] half while its next
  /// visible sibling paints the [PlutoColumnResizeHandleSide.start] half for
  /// the same boundary. Together they form one centered hit target without
  /// relying on hit testing outside either column's bounds.
  final PlutoColumnResizeHandleSide side;

  const PlutoColumnResizeHandle({
    required this.stateManager,
    required this.column,
    this.side = PlutoColumnResizeHandleSide.end,
    super.key,
  });

  @override
  State<PlutoColumnResizeHandle> createState() =>
      _PlutoColumnResizeHandleState();
}

/// Supplies the outer half of the final column boundary's hit target.
///
/// Internal boundaries receive their second half from the next column. The
/// final boundary has no sibling, so a small gutter keeps the hit area centered
/// without widening the column content itself.
class PlutoColumnResizeGutter extends StatelessWidget
    implements PlutoVisibilityLayoutChild {
  static const ValueKey<String> layoutId = ValueKey<String>(
    'TrailingColumnResizeGutter',
  );

  final PlutoGridStateManager stateManager;

  final PlutoColumn column;

  final double boundaryPosition;

  final Key handleKey;

  const PlutoColumnResizeGutter({
    required this.stateManager,
    required this.column,
    required this.boundaryPosition,
    required this.handleKey,
    super.key,
  });

  @override
  double get width => stateManager.style.columnResizeHandleWidth / 2;

  @override
  double get startPosition => boundaryPosition;

  @override
  bool get keepAlive => true;

  @override
  Widget build(BuildContext context) {
    return PlutoColumnResizeHandle(
      key: handleKey,
      stateManager: stateManager,
      column: column,
      side: PlutoColumnResizeHandleSide.start,
    );
  }
}

class _PlutoColumnResizeHandleState extends State<PlutoColumnResizeHandle> {
  static final Expando<_ResizeTapState> _tapStates = Expando<_ResizeTapState>(
    'columnResizeTapState',
  );

  late Offset _columnRightPosition;

  bool _isHovered = false;

  bool _isPointerInside = false;

  bool _showResizeCursor = false;

  bool _isDragging = false;

  bool _isPointMoving = false;

  bool _indicatorUpdateScheduled = false;

  bool _isPrimaryPointer = false;

  double _dragSlopSquared = 0;

  Timer? _hoverDelayTimer;

  Timer? _cursorDelayTimer;

  _ResizeTapState get _tapState =>
      _tapStates[widget.column] ??= _ResizeTapState();

  bool get _isActive => _isHovered || _isDragging;

  PlutoColumnResizeIndicatorMode get _indicatorMode =>
      widget.column.resolveColumnResizeIndicatorMode(
        widget.stateManager.style,
      );

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }

    setState(() {
      _isHovered = value;
    });

    _syncOverlayIndicator();
  }

  void _handleEnter() {
    _isPointerInside = true;
    _hoverDelayTimer?.cancel();
    _cursorDelayTimer?.cancel();

    final PlutoGridStyleConfig style = widget.stateManager.style;
    final Duration indicatorDelay =
        widget.stateManager.style.columnResizeIndicatorHoverDelay;
    final Duration cursorDelay = style.columnResizeCursorDelay;

    if (indicatorDelay <= Duration.zero) {
      _setHovered(true);
    } else {
      _hoverDelayTimer = Timer(indicatorDelay, () {
        if (mounted && _isPointerInside) {
          _setHovered(true);
        }
      });
    }

    if (cursorDelay <= Duration.zero) {
      _setResizeCursorVisible(true);
    } else {
      _cursorDelayTimer = Timer(cursorDelay, () {
        if (mounted && _isPointerInside) {
          _setResizeCursorVisible(true);
        }
      });
    }
  }

  void _handleExit() {
    _isPointerInside = false;
    _hoverDelayTimer?.cancel();
    _cursorDelayTimer?.cancel();
    _setHovered(false);
    _setResizeCursorVisible(false);
  }

  void _setResizeCursorVisible(bool value) {
    if (_showResizeCursor == value) {
      return;
    }

    setState(() {
      _showResizeCursor = value;
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    _columnRightPosition = event.position;
    _isPointMoving = false;
    _isPrimaryPointer = event.buttons & kPrimaryButton != 0;
    final double dragSlop = computePanSlop(
      event.kind,
      MediaQuery.gestureSettingsOf(context),
    );
    _dragSlopSquared = dragSlop * dragSlop;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _isPointMoving |=
        (_columnRightPosition - event.position).distanceSquared >
        _dragSlopSquared;

    if (!_isPointMoving) {
      return;
    }

    if (!_isDragging) {
      _hoverDelayTimer?.cancel();
      _cursorDelayTimer?.cancel();

      setState(() {
        _isDragging = true;
        _isHovered = _isPointerInside;
        _showResizeCursor = true;
      });
      _syncOverlayIndicator();
    }

    final double moveOffset = event.position.dx - _columnRightPosition.dx;

    widget.stateManager.resizeColumn(
      widget.column,
      widget.stateManager.isLTR ? moveOffset : -moveOffset,
    );

    _columnRightPosition = event.position;
    _scheduleOverlayIndicatorUpdate();
  }

  void _handlePointerUp(PointerUpEvent event) {
    final bool wasPointMoving = _isPointMoving;

    if (_isPointMoving) {
      widget.stateManager.updateCorrectScrollOffset();
    }

    if (!wasPointMoving && _isPrimaryPointer) {
      _handleTap(event);
    }

    _isPrimaryPointer = false;
    _finishDragging();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _isPrimaryPointer = false;
    _finishDragging();
  }

  void _handleTap(PointerUpEvent event) {
    // Detect the double tap from raw pointer events so the same hit target can
    // start a drag immediately without competing gesture-arena recognizers.
    final _ResizeTapState tapState = _tapState;
    final Duration? lastTapTime = tapState.lastTapTime;
    final Offset? lastTapPosition = tapState.lastTapPosition;
    final Duration? elapsed = lastTapTime == null
        ? null
        : event.timeStamp - lastTapTime;
    final bool isDoubleTap =
        elapsed != null &&
        elapsed >= kDoubleTapMinTime &&
        elapsed <= kDoubleTapTimeout &&
        lastTapPosition != null &&
        (event.position - lastTapPosition).distance <= kDoubleTapSlop;

    if (isDoubleTap) {
      tapState
        ..lastTapTime = null
        ..lastTapPosition = null;
      _handleDoubleTap();
      return;
    }

    tapState
      ..lastTapTime = event.timeStamp
      ..lastTapPosition = event.position;
  }

  void _handleDoubleTap() {
    widget.stateManager.autoFitColumn(context, widget.column);
    widget.stateManager.updateCorrectScrollOffset();
    _scheduleOverlayIndicatorUpdate();
  }

  void _finishDragging() {
    _isPointMoving = false;

    if (!mounted || !_isDragging) {
      return;
    }

    setState(() {
      _isDragging = false;
      _isHovered = _isPointerInside;
      _showResizeCursor = _isPointerInside;
    });

    _syncOverlayIndicator();
  }

  double? _resolveGlobalBoundaryX() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;

    if (renderBox == null || !renderBox.hasSize) {
      return null;
    }

    final bool boundaryAtStart =
        widget.side == PlutoColumnResizeHandleSide.start;
    final bool useLeftEdge = boundaryAtStart
        ? widget.stateManager.isLTR
        : widget.stateManager.isRTL;
    final Offset boundary = useLeftEdge
        ? Offset.zero
        : Offset(renderBox.size.width, 0);

    return renderBox.localToGlobal(boundary).dx;
  }

  void _syncOverlayIndicator() {
    final PlutoColumnResizeIndicatorMode mode = _indicatorMode;

    if (mode == PlutoColumnResizeIndicatorMode.cell) {
      PlutoColumnResizeIndicatorNotification.hide(source: this).dispatch(
        context,
      );
      return;
    }

    if (!_isActive) {
      PlutoColumnResizeIndicatorNotification.hide(source: this).dispatch(
        context,
      );
      return;
    }

    final double? globalX = _resolveGlobalBoundaryX();

    if (globalX == null) {
      return;
    }

    PlutoColumnResizeIndicatorNotification.show(
      data: PlutoColumnResizeIndicatorData(
        source: this,
        column: widget.column,
        mode: mode,
        x: globalX,
      ),
    ).dispatch(context);
  }

  void _scheduleOverlayIndicatorUpdate() {
    if (_indicatorMode == PlutoColumnResizeIndicatorMode.cell ||
        _indicatorUpdateScheduled) {
      return;
    }

    _indicatorUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _indicatorUpdateScheduled = false;

      if (mounted) {
        _syncOverlayIndicator();
      }
    });
  }

  @override
  void deactivate() {
    _hoverDelayTimer?.cancel();
    _cursorDelayTimer?.cancel();

    if (_indicatorMode != PlutoColumnResizeIndicatorMode.cell && _isActive) {
      PlutoColumnResizeIndicatorNotification.hide(source: this).dispatch(
        context,
      );
    }

    super.deactivate();
  }

  @override
  void dispose() {
    _hoverDelayTimer?.cancel();
    _cursorDelayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLTR = widget.stateManager.isLTR;
    final bool boundaryAtStart =
        widget.side == PlutoColumnResizeHandleSide.start;
    final bool showLocalIndicator =
        _indicatorMode == PlutoColumnResizeIndicatorMode.cell && _isActive;
    final AlignmentGeometry indicatorAlignment = boundaryAtStart
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.centerEnd;
    final double directionalTranslation = boundaryAtStart ? -0.5 : 0.5;

    return MouseRegion(
      cursor: _showResizeCursor
          ? SystemMouseCursors.resizeLeftRight
          : MouseCursor.defer,
      onEnter: (_) => _handleEnter(),
      onExit: (_) => _handleExit(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: Align(
          alignment: indicatorAlignment,
          child: FractionalTranslation(
            translation: Offset(
              isLTR ? directionalTranslation : -directionalTranslation,
              0,
            ),
            child: AnimatedContainer(
              key: const ValueKey<String>('ColumnResizeHandleIndicator'),
              duration: widget
                  .stateManager
                  .style
                  .columnResizeIndicatorAnimationDuration,
              curve: Curves.easeOut,
              width: showLocalIndicator
                  ? widget.stateManager.style.columnResizeIndicatorWidth
                  : 0,
              color: widget.stateManager.style.columnResizeIndicatorColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizeTapState {
  Duration? lastTapTime;

  Offset? lastTapPosition;
}

/// Paints a single resize guide above virtualized grid rows.
///
/// Keeping the guide at grid level avoids rebuilding or painting one active
/// segment in every visible cell.
class PlutoColumnResizeIndicatorOverlay extends StatefulWidget {
  final PlutoGridStateManager stateManager;

  final ValueListenable<PlutoColumnResizeIndicatorData?> notifier;

  const PlutoColumnResizeIndicatorOverlay({
    required this.stateManager,
    required this.notifier,
    super.key,
  });

  @override
  State<PlutoColumnResizeIndicatorOverlay> createState() =>
      _PlutoColumnResizeIndicatorOverlayState();
}

class _PlutoColumnResizeIndicatorOverlayState
    extends State<PlutoColumnResizeIndicatorOverlay> {
  PlutoColumnResizeIndicatorData? _data;

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _data = widget.notifier.value;
    _visible = _data != null;
    widget.notifier.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(PlutoColumnResizeIndicatorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_handleChanged);
      widget.notifier.addListener(_handleChanged);
      _handleChanged();
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() {
    final PlutoColumnResizeIndicatorData? next = widget.notifier.value;

    if (next != null) {
      _data = next;
    }

    if (mounted) {
      setState(() {
        _visible = next != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final PlutoColumnResizeIndicatorData? data = _data;

    if (data == null) {
      return const SizedBox.expand();
    }

    final _ResizeIndicatorGeometry geometry = _resolveGeometry(data);
    final _ResizeIndicatorGeometry? footerGeometry =
        _resolveColumnFooterGeometry(data);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildIndicator(
            key: const ValueKey<String>('FullHeightColumnResizeIndicator'),
            x: data.x,
            geometry: geometry,
          ),
          if (footerGeometry != null)
            _buildIndicator(
              key: const ValueKey<String>('ColumnFooterResizeIndicator'),
              x: data.x,
              geometry: footerGeometry,
            ),
        ],
      ),
    );
  }

  Widget _buildIndicator({
    required Key key,
    required double x,
    required _ResizeIndicatorGeometry geometry,
  }) {
    final PlutoGridStyleConfig style = widget.stateManager.style;

    return Positioned(
      left: x,
      top: geometry.top,
      height: geometry.height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: AnimatedContainer(
          key: key,
          duration: style.columnResizeIndicatorAnimationDuration,
          curve: Curves.easeOut,
          width: _visible ? style.columnResizeIndicatorWidth : 0,
          color: style.columnResizeIndicatorColor,
        ),
      ),
    );
  }

  _ResizeIndicatorGeometry _resolveGeometry(
    PlutoColumnResizeIndicatorData data,
  ) {
    final PlutoGridStateManager stateManager = widget.stateManager;
    final double gridHeight = stateManager.maxHeight ?? 0;

    if (data.mode == PlutoColumnResizeIndicatorMode.header) {
      final bool expandedColumn =
          stateManager.showColumnGroups &&
          (data.column.group?.expandedColumn ?? false);
      final double top =
          stateManager.headerHeight +
          (expandedColumn ? 0 : stateManager.columnGroupHeight);
      final double height = expandedColumn
          ? stateManager.columnGroupHeight + stateManager.columnHeight
          : stateManager.columnHeight;

      return _ResizeIndicatorGeometry(top: top, height: height);
    }

    final double top =
        stateManager.headerHeight + _commonGroupHeaderHeight(data.column);
    final double viewportBottom =
        gridHeight -
        stateManager.footerHeight -
        stateManager.columnFooterHeight;
    final double bottom = _resolveLastRowBottom(viewportBottom);

    return _ResizeIndicatorGeometry(
      top: top,
      height: (bottom - top).clamp(0.0, double.infinity),
    );
  }

  _ResizeIndicatorGeometry? _resolveColumnFooterGeometry(
    PlutoColumnResizeIndicatorData data,
  ) {
    final PlutoGridStateManager stateManager = widget.stateManager;
    final double footerHeight = stateManager.columnFooterHeight;

    if (data.mode != PlutoColumnResizeIndicatorMode.fullHeight ||
        footerHeight <= 0) {
      return null;
    }

    final double gridHeight = stateManager.maxHeight ?? 0;

    return _ResizeIndicatorGeometry(
      top: gridHeight - stateManager.footerHeight - footerHeight,
      height: footerHeight,
    );
  }

  double _resolveLastRowBottom(double viewportBottom) {
    final PlutoGridStateManager stateManager = widget.stateManager;

    // A custom row wrapper can alter row geometry, so the viewport edge is the
    // only reliable lower bound in that case.
    if (stateManager.rowWrapper != null) {
      return viewportBottom;
    }

    final ScrollController? verticalScroll =
        stateManager.scroll.bodyRowsVertical;
    final double verticalOffset;

    if (verticalScroll != null && verticalScroll.hasClients) {
      verticalOffset = verticalScroll.offset;
    } else {
      verticalOffset = 0;
    }
    // PlutoGrid virtualizes rows. Derive the last row position from the total
    // row extent and current scroll offset instead of walking rendered cells.
    final int rowCount = stateManager.refRows.length;
    final double rowsHeight = rowCount == 0
        ? 0
        : rowCount * stateManager.rowTotalHeight -
              stateManager.style.rowBorderWidth;
    final double remainingRowsHeight = (rowsHeight - verticalOffset).clamp(
      0.0,
      double.infinity,
    );
    final double lastRowBottom =
        stateManager.rowsTopOffset +
        stateManager.gridBorderWidth +
        remainingRowsHeight;

    return lastRowBottom < viewportBottom ? lastRowBottom : viewportBottom;
  }

  double _commonGroupHeaderHeight(PlutoColumn column) {
    final PlutoGridStateManager stateManager = widget.stateManager;

    if (!stateManager.showColumnGroups) {
      return 0;
    }

    final PlutoColumn? nextColumn = _nextVisibleColumn(column);

    if (nextColumn == null) {
      return 0;
    }

    final List<PlutoColumnGroup> currentPath = _groupPath(column);
    final List<PlutoColumnGroup> nextPath = _groupPath(nextColumn);
    final List<PlutoColumnGroup> commonPath = <PlutoColumnGroup>[];
    final int commonLength = currentPath.length < nextPath.length
        ? currentPath.length
        : nextPath.length;

    for (int i = 0; i < commonLength; i += 1) {
      if (currentPath[i].key != nextPath[i].key) {
        break;
      }

      commonPath.add(currentPath[i]);
    }

    int depth = stateManager.columnGroupDepth(stateManager.columnGroups);
    double height = 0;

    for (final PlutoColumnGroup group in commonPath) {
      final int childrenDepth = group.hasChildren
          ? stateManager.columnGroupDepth(group.children!)
          : 0;
      final int titleDepth = group.hasChildren ? depth - childrenDepth : depth;

      height += titleDepth * stateManager.columnHeight;
      depth = childrenDepth;
    }

    return height;
  }

  PlutoColumn? _nextVisibleColumn(PlutoColumn column) {
    final PlutoGridStateManager stateManager = widget.stateManager;
    final List<PlutoColumn> columns = stateManager.showFrozenColumn
        ? <PlutoColumn>[
            ...stateManager.leftFrozenColumns,
            ...stateManager.bodyColumns,
            ...stateManager.rightFrozenColumns,
          ]
        : stateManager.columns;
    final int index = columns.indexWhere(
      (PlutoColumn e) => e.key == column.key,
    );
    final int nextIndex = index + 1;

    return index >= 0 && nextIndex < columns.length ? columns[nextIndex] : null;
  }

  List<PlutoColumnGroup> _groupPath(PlutoColumn column) {
    final PlutoColumnGroup? group = column.group;

    if (group == null) {
      return <PlutoColumnGroup>[];
    }

    return <PlutoColumnGroup>[
      ...group.parents.toList(growable: false).reversed,
      group,
    ];
  }
}

class _ResizeIndicatorGeometry {
  final double top;

  final double height;

  const _ResizeIndicatorGeometry({
    required this.top,
    required this.height,
  });
}
