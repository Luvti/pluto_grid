import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart' show forceGC;
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  test('the column map follows insertions, hiding and removals', () {
    final FocusNode focus = FocusNode();
    final PlutoColumn initial = _column('initial');
    final PlutoGridStateManager manager = PlutoGridStateManager(
      columns: <PlutoColumn>[initial],
      rows: <PlutoRow<dynamic>>[
        PlutoRow<dynamic>(
          cells: <String, PlutoCell>{'initial': PlutoCell(value: 'value')},
        ),
      ],
      gridFocusNode: focus,
      scroll: PlutoGridScrollController(),
    );
    addTearDown(() {
      manager.dispose();
      focus.dispose();
    });
    final Map<String, PlutoColumn> map = manager.columnsMap;
    final PlutoColumn inserted = _column('inserted');
    final PlutoColumn hidden = _column('hidden')..hide = true;
    manager.insertColumns(0, <PlutoColumn>[inserted, hidden]);
    expect(manager.columnsMap, same(map));
    expect(map, <String, PlutoColumn>{
      'initial': initial,
      'inserted': inserted,
      'hidden': hidden,
    });
    expect(manager.refRows.first.cells.keys, containsAll(map.keys));

    manager.hideColumn(initial, true, notify: false);
    expect(map['initial'], same(initial));
    manager.removeColumns(<PlutoColumn>[initial, hidden]);
    expect(map, <String, PlutoColumn>{'inserted': inserted});
    expect(manager.refRows.first.cells.keys, <String>['inserted']);

    final PlutoColumn replacement = _column('initial');
    manager.insertColumns(0, <PlutoColumn>[replacement]);
    expect(map['initial'], same(replacement));
    expect(manager.refRows.first.cells['initial']!.column, same(replacement));
  });

  test(
    'removed columns and renderer data are collected with a live manager',
    () async {
      final _LiveManager fixture = _createManagerWithRemovedColumns();
      addTearDown(() {
        fixture.manager.dispose();
        fixture.focus.dispose();
      });
      await forceGC(fullGcCycles: 3, timeout: const Duration(seconds: 15));
      expect(fixture.manager.streamNotifier.isClosed, isFalse);
      expect(fixture.manager.columnsMap.keys, <String>['kept']);
      expect(fixture.manager.refRows.first.cells.keys, <String>['kept']);
      for (final WeakReference<Object> reference in fixture.references) {
        expect(reference.target, isNull);
      }
    },
  );
}

PlutoColumn _column(String field) => PlutoColumn(
  title: field,
  field: field,
  type: PlutoColumnType.text(),
);

_LiveManager _createManagerWithRemovedColumns() {
  final List<int> rendererData = List<int>.filled(10000, 1);
  final PlutoColumn removed = PlutoColumn(
    title: 'removed',
    field: 'removed',
    type: PlutoColumnType.text(),
    renderer: (PlutoColumnRendererContext context) =>
        Text('${rendererData.length}'),
  );
  final PlutoColumn hidden = _column('hidden')..hide = true;
  final FocusNode focus = FocusNode();
  final PlutoGridStateManager manager = PlutoGridStateManager(
    columns: <PlutoColumn>[_column('kept'), removed, hidden],
    rows: <PlutoRow<dynamic>>[
      PlutoRow<dynamic>(
        cells: <String, PlutoCell>{
          for (final String field in <String>['kept', 'removed', 'hidden'])
            field: PlutoCell(value: field),
        },
      ),
    ],
    gridFocusNode: focus,
    scroll: PlutoGridScrollController(),
  )..removeColumns(<PlutoColumn>[removed, hidden]);
  return _LiveManager(manager, focus, <WeakReference<Object>>[
    WeakReference<Object>(removed),
    WeakReference<Object>(hidden),
    WeakReference<Object>(rendererData),
  ]);
}

class _LiveManager {
  const _LiveManager(this.manager, this.focus, this.references);
  final PlutoGridStateManager manager;
  final FocusNode focus;
  final List<WeakReference<Object>> references;
}
