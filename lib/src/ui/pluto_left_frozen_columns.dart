import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import 'ui.dart';

class PlutoLeftFrozenColumns extends PlutoStatefulWidget {
  final PlutoGridStateManager stateManager;

  const PlutoLeftFrozenColumns(
    this.stateManager, {
    super.key,
  });

  @override
  PlutoLeftFrozenColumnsState createState() => PlutoLeftFrozenColumnsState();
}

class PlutoLeftFrozenColumnsState
    extends PlutoStateWithChange<PlutoLeftFrozenColumns> {
  List<PlutoColumn> _columns = [];

  List<PlutoColumnGroupPair> _columnGroups = [];

  bool _showColumnGroups = false;

  int _itemCount = 0;

  @override
  PlutoGridStateManager get stateManager => widget.stateManager;

  @override
  void initState() {
    super.initState();

    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  @override
  void updateState(PlutoNotifierEvent event) {
    _showColumnGroups = update<bool>(
      _showColumnGroups,
      stateManager.showColumnGroups,
    );

    _columns = update<List<PlutoColumn>>(
      _columns,
      stateManager.leftFrozenColumns,
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

  Widget _makeColumnGroup(PlutoColumnGroupPair e) {
    return LayoutId(
      id: e.key,
      child: PlutoBaseColumnGroup(
        stateManager: stateManager,
        columnGroup: e,
        leadingResizeColumn: _previousColumnGroup(e),
        depth: stateManager.columnGroupDepth(stateManager.refColumnGroups),
      ),
    );
  }

  Widget _makeColumn(PlutoColumn e) {
    return LayoutId(
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
    return CustomMultiChildLayout(
      delegate: MainColumnLayoutDelegate(
        stateManager: stateManager,
        columns: _columns,
        columnGroups: _columnGroups,
        frozen: PlutoColumnFrozen.start,
        textDirection: stateManager.textDirection,
      ),
      children: _showColumnGroups == true
          ? _columnGroups.map(_makeColumnGroup).toList(growable: false)
          : _columns.map(_makeColumn).toList(growable: false),
    );
  }
}
