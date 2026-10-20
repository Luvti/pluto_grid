import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import 'columns/pluto_column_resize_handle.dart';
import 'ui.dart';

class PlutoBodyColumns extends PlutoStatefulWidget {
  final PlutoGridStateManager stateManager;

  const PlutoBodyColumns(
    this.stateManager, {
    super.key,
  });

  @override
  PlutoBodyColumnsState createState() => PlutoBodyColumnsState();
}

class PlutoBodyColumnsState extends PlutoStateWithChange<PlutoBodyColumns> {
  List<PlutoColumn> _columns = [];

  List<PlutoColumnGroupPair> _columnGroups = [];

  bool _showColumnGroups = false;

  int _itemCount = 0;

  late final ScrollController _scroll;

  @override
  PlutoGridStateManager get stateManager => widget.stateManager;

  @override
  void initState() {
    super.initState();

    _scroll = stateManager.scroll.horizontal!.addAndGet();

    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  @override
  void dispose() {
    _scroll.dispose();

    super.dispose();
  }

  @override
  void updateState(PlutoNotifierEvent event) {
    _showColumnGroups = update<bool>(
      _showColumnGroups,
      stateManager.showColumnGroups,
    );

    _columns = update<List<PlutoColumn>>(
      _columns,
      _getColumns(),
      compare: listEquals,
    );

    _columnGroups = update<List<PlutoColumnGroupPair>>(
      _columnGroups,
      stateManager.separateLinkedGroup(
        columnGroupList: stateManager.refColumnGroups,
        columns: _columns,
      ),
    );

    _itemCount = update<int>(_itemCount, _getItemCount());
  }

  List<PlutoColumn> _getColumns() {
    return stateManager.showFrozenColumn
        ? stateManager.bodyColumns
        : stateManager.columns;
  }

  int _getItemCount() {
    return _showColumnGroups == true ? _columnGroups.length : _columns.length;
  }

  PlutoColumn? _previousColumn(PlutoColumn column) {
    final int index = _columns.indexWhere(
      (PlutoColumn candidate) => candidate.key == column.key,
    );

    return index > 0 ? _columns[index - 1] : null;
  }

  PlutoColumn? _previousColumnGroup(PlutoColumnGroupPair columnGroup) {
    final int index = _columnGroups.indexWhere(
      (PlutoColumnGroupPair candidate) => candidate.key == columnGroup.key,
    );

    return index > 0 ? _columnGroups[index - 1].columns.last : null;
  }

  PlutoColumn? get _trailingResizeColumn {
    if (stateManager.showFrozenColumn ||
        stateManager.columnsResizeMode.isNone ||
        _columns.isEmpty ||
        !_columns.last.enableDropToResize) {
      return null;
    }

    return _columns.last;
  }

  double get _columnsWidth => _columns.fold<double>(
    0,
    (double width, PlutoColumn column) => width + column.width,
  );

  PlutoVisibilityLayoutId _makeColumnGroup(PlutoColumnGroupPair e) {
    return PlutoVisibilityLayoutId(
      id: e.key,
      child: PlutoBaseColumnGroup(
        stateManager: stateManager,
        columnGroup: e,
        leadingResizeColumn: _previousColumnGroup(e),
        depth: stateManager.columnGroupDepth(
          stateManager.refColumnGroups,
        ),
      ),
    );
  }

  PlutoVisibilityLayoutId _makeColumn(PlutoColumn e) {
    return PlutoVisibilityLayoutId(
      id: e.field,
      child: PlutoBaseColumn(
        stateManager: stateManager,
        column: e,
        leadingResizeColumn: _previousColumn(e),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PlutoColumn? trailingResizeColumn = _trailingResizeColumn;
    final List<PlutoVisibilityLayoutId> children = _showColumnGroups == true
        ? _columnGroups.map(_makeColumnGroup).toList(growable: true)
        : _columns.map(_makeColumn).toList(growable: true);

    if (trailingResizeColumn != null) {
      children.add(
        PlutoVisibilityLayoutId(
          id: PlutoColumnResizeGutter.layoutId,
          child: PlutoColumnResizeGutter(
            key: const ValueKey<String>('column_resize_trailing_gutter'),
            handleKey: ValueKey<String>(
              'column_resize_handle_end_gutter_'
              '${trailingResizeColumn.field}',
            ),
            stateManager: stateManager,
            column: trailingResizeColumn,
            boundaryPosition: _columnsWidth,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: PlutoVisibilityLayout(
        delegate: MainColumnLayoutDelegate(
          stateManager: stateManager,
          columns: _columns,
          columnGroups: _columnGroups,
          frozen: PlutoColumnFrozen.none,
          textDirection: stateManager.textDirection,
          trailingResizeColumn: trailingResizeColumn,
        ),
        scrollController: _scroll,
        initialViewportDimension: MediaQuery.sizeOf(context).width,
        children: children,
      ),
    );
  }
}

class MainColumnLayoutDelegate extends MultiChildLayoutDelegate {
  final PlutoGridStateManager stateManager;

  final List<PlutoColumn> columns;

  final List<PlutoColumnGroupPair> columnGroups;

  final PlutoColumnFrozen frozen;

  final TextDirection textDirection;

  final PlutoColumn? trailingResizeColumn;

  MainColumnLayoutDelegate({
    required this.stateManager,
    required this.columns,
    required this.columnGroups,
    required this.frozen,
    required this.textDirection,
    this.trailingResizeColumn,
  }) : super(relayout: stateManager.resizingChangeNotifier);

  double totalColumnsHeight = 0;

  double get _trailingGutterWidth => trailingResizeColumn == null
      ? 0
      : stateManager.style.columnResizeHandleWidth / 2;

  @override
  Size getSize(BoxConstraints constraints) {
    totalColumnsHeight = 0;

    if (stateManager.showColumnGroups) {
      totalColumnsHeight =
          stateManager.columnGroupHeight + stateManager.columnHeight;
    } else {
      totalColumnsHeight = stateManager.columnHeight;
    }

    totalColumnsHeight += stateManager.columnFilterHeight;

    return Size(
      columns.fold<double>(
            0,
            (double width, PlutoColumn column) => width + column.width,
          ) +
          _trailingGutterWidth,
      totalColumnsHeight,
    );
  }

  @override
  void performLayout(Size size) {
    final isLTR = textDirection == TextDirection.ltr;

    if (stateManager.showColumnGroups) {
      final items = isLTR ? columnGroups : columnGroups.reversed;
      double dx = isLTR ? 0 : _trailingGutterWidth;

      for (PlutoColumnGroupPair pair in items) {
        final double width = pair.columns.fold<double>(
          0,
          (previousValue, element) => previousValue + element.width,
        );

        if (hasChild(pair.key)) {
          var boxConstraints = BoxConstraints.tight(
            Size(width, totalColumnsHeight),
          );

          layoutChild(pair.key, boxConstraints);

          positionChild(pair.key, Offset(dx, 0));
        }

        dx += width;
      }
    } else {
      final items = isLTR ? columns : columns.reversed;
      double dx = isLTR ? 0 : _trailingGutterWidth;

      for (PlutoColumn col in items) {
        var width = col.width;

        if (hasChild(col.field)) {
          var boxConstraints = BoxConstraints.tight(
            Size(width, totalColumnsHeight),
          );

          layoutChild(col.field, boxConstraints);

          positionChild(col.field, Offset(dx, 0));
        }

        dx += width;
      }
    }

    if (trailingResizeColumn != null &&
        hasChild(PlutoColumnResizeGutter.layoutId)) {
      layoutChild(
        PlutoColumnResizeGutter.layoutId,
        BoxConstraints.tight(
          Size(_trailingGutterWidth, totalColumnsHeight),
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
