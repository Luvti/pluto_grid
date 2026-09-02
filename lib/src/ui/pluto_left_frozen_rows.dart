import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import 'columns/pluto_column_resize_handle.dart';
import 'ui.dart';

class PlutoLeftFrozenRows extends PlutoStatefulWidget {
  final PlutoGridStateManager stateManager;

  const PlutoLeftFrozenRows(
    this.stateManager, {
    super.key,
  });

  @override
  PlutoLeftFrozenRowsState createState() => PlutoLeftFrozenRowsState();
}

class PlutoLeftFrozenRowsState
    extends PlutoStateWithChange<PlutoLeftFrozenRows> {
  List<PlutoColumn> _columns = [];

  List<PlutoRow> _rows = [];

  late final ScrollController _scroll;

  @override
  PlutoGridStateManager get stateManager => widget.stateManager;

  @override
  void initState() {
    super.initState();

    _scroll = stateManager.scroll.vertical!.addAndGet();

    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  @override
  void dispose() {
    _scroll.dispose();

    super.dispose();
  }

  @override
  void updateState(PlutoNotifierEvent event) {
    forceUpdate();

    _columns = stateManager.leftFrozenColumns;

    _rows = stateManager.refRows;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ListView.builder(
          controller: _scroll,
          scrollDirection: Axis.vertical,
          physics: const ClampingScrollPhysics(),
          itemCount: _rows.length,
          itemExtent: stateManager.rowTotalHeight,
          itemBuilder: (ctx, i) {
            return PlutoBaseRow(
              key: ValueKey('left_frozen_row_${_rows[i].key}'),
              rowIdx: i,
              row: _rows[i],
              columns: _columns,
              stateManager: stateManager,
            );
          },
        ),
        PlutoBodyColumnResizeHandles(
          key: const ValueKey<String>('left_frozen_column_resize_handles'),
          stateManager: stateManager,
          columns: _columns,
        ),
      ],
    );
  }
}
