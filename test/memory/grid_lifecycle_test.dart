import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart' show forceGC;
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart'
    show LeakTesting, LeakTracking;
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  testWidgets('repeated dual grids dispose their resize notifiers', (
    WidgetTester tester,
  ) async {
    for (int cycle = 0; cycle < 3; cycle++) {
      final GlobalKey<PlutoDualGridState> key = GlobalKey<PlutoDualGridState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoDualGrid(
              key: key,
              gridPropsA: PlutoDualGridProps(
                columns: <PlutoColumn>[_textColumn('value')],
                rows: <PlutoRow<dynamic>>[_row('left')],
              ),
              gridPropsB: PlutoDualGridProps(
                columns: <PlutoColumn>[_textColumn('value')],
                rows: <PlutoRow<dynamic>>[_row('right')],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final PlutoDualGridResizeNotifier notifier =
          key.currentState!.resizeNotifier..resize();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(() => notifier.addListener(() {}), throwsFlutterError);
    }
  });

  testWidgets('disposing the manager disposes its resize notifier', (
    WidgetTester tester,
  ) async {
    expect(LeakTesting.enabled, isTrue);
    expect(LeakTracking.isStarted, isTrue);
    final FocusNode focus = FocusNode();
    final PlutoGridStateManager manager = PlutoGridStateManager(
      columns: <PlutoColumn>[],
      rows: <PlutoRow<dynamic>>[],
      gridFocusNode: focus,
      scroll: PlutoGridScrollController(),
    );
    manager.resizingChangeNotifier.addListener(() {});
    manager.dispose();
    focus.dispose();
    expect(
      () => manager.resizingChangeNotifier.addListener(() {}),
      throwsFlutterError,
    );
    expect(manager.streamNotifier.isClosed, isTrue);
  });

  testWidgets(
    'repeated grid editing, filtering and scrolling releases resources',
    (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (int cycle = 0; cycle < 3; cycle++) {
        final List<PlutoColumn> columns = List<PlutoColumn>.generate(
          8,
          (int index) => PlutoColumn(
            title: 'Column $index',
            field: 'field$index',
            type: PlutoColumnType.text(),
            width: 180,
            frozen: index == 0
                ? PlutoColumnFrozen.start
                : index == 7
                ? PlutoColumnFrozen.end
                : PlutoColumnFrozen.none,
          ),
        );
        final List<PlutoRow<dynamic>> rows = List<PlutoRow<dynamic>>.generate(
          300,
          (int index) => PlutoRow<dynamic>(
            cells: <String, PlutoCell>{
              for (final PlutoColumn column in columns)
                column.field: PlutoCell(value: 'Row $index'),
            },
          ),
        );
        late PlutoGridStateManager manager;
        int disposed = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: PlutoGrid(
                key: ValueKey<int>(cycle),
                columns: columns,
                rows: rows,
                createFooter: PlutoPagination.new,
                onLoaded: (PlutoGridOnLoadedEvent event) {
                  manager = event.stateManager..setShowColumnFilter(true);
                },
                onDispose: (PlutoGridOnDisposeEvent event) {
                  expect(event.stateManager, same(manager));
                  disposed++;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        manager.scroll.bodyRowsHorizontal!.jumpTo(200);
        manager.scroll.bodyRowsVertical!.jumpTo(100);
        manager
          ..setCurrentCell(rows.first.cells['field0'], 0)
          ..setEditing(true);
        await tester.pumpAndSettle();
        expect(manager.textEditingController, isNotNull);
        final PlutoGridEventManager events = manager.eventManager!;
        final PlutoGridKeyManager keys = manager.keyManager!;

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(disposed, 1);
        expect(events.subject.isClosed, isTrue);
        expect(keys.subject.isClosed, isTrue);
        expect(manager.streamNotifier.isClosed, isTrue);
        expect(manager.textEditingController, isNull);
        expect(manager.scroll.bodyRowsHorizontal, isNull);
        expect(manager.scroll.bodyRowsVertical, isNull);
        expect(
          columns.every((PlutoColumn column) => column.filterFocusNode == null),
          isTrue,
        );
      }
    },
  );

  testWidgets(
    'a linked group and its widget can both release their controller',
    (
      WidgetTester tester,
    ) async {
      final LinkedScrollControllerGroup group = LinkedScrollControllerGroup();
      final ScrollController controller = group.addAndGet();
      await tester.pumpWidget(
        MaterialApp(
          home: ListView.builder(
            controller: controller,
            itemExtent: 40,
            itemCount: 40,
            itemBuilder: (BuildContext context, int index) =>
                Text('Row $index'),
          ),
        ),
      );
      group.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'a retained disposed manager releases columns, groups and filter data',
    () async {
      final _DisposedManager fixture = _createDisposedManager();
      await forceGC(fullGcCycles: 3, timeout: const Duration(seconds: 15));
      // Keep the disposed manager reachable while checking its old data.
      expect(fixture.manager.refRows.originalList, isEmpty);
      expect(fixture.manager.columnsMap, isEmpty);
      expect(fixture.manager.refColumnGroups.originalList, isEmpty);
      expect(fixture.manager.filterRows, isEmpty);
      expect(fixture.manager.filterColumns, isEmpty);
      expect(fixture.manager.savedFilter, isNull);
      expect(fixture.manager.dragRows, isEmpty);
      for (final WeakReference<Object> reference in fixture.references) {
        expect(reference.target, isNull);
      }
    },
  );

  test('disposing collapsed groups clears every descendant cell link', () {
    final PlutoColumn column = _textColumn('value');
    final PlutoRow<dynamic> leaf = _row('leaf');
    final PlutoRow<dynamic> child = _group('child', <PlutoRow<dynamic>>[leaf]);
    final PlutoRow<dynamic> root = _group('root', <PlutoRow<dynamic>>[child]);
    final FocusNode focus = FocusNode();
    final PlutoGridStateManager manager =
        PlutoGridStateManager(
          columns: <PlutoColumn>[column],
          rows: <PlutoRow<dynamic>>[root],
          gridFocusNode: focus,
          scroll: PlutoGridScrollController(),
        )..setRowGroup(
          PlutoRowGroupTreeDelegate(
            resolveColumnDepth: (PlutoColumn column) => 0,
            showText: (PlutoCell cell) => true,
          ),
          notify: false,
        );
    expect(leaf.cells['value']!.initialized, isTrue);
    expect(leaf.parent, same(child));
    manager.dispose();
    focus.dispose();
    for (final PlutoRow<dynamic> row in <PlutoRow<dynamic>>[
      root,
      child,
      leaf,
    ]) {
      expect(row.cells['value']!.initialized, isFalse);
      expect(row.parent, isNull);
    }
    // Callers may reuse their row data in a replacement grid.
    expect(root.type.group.children.originalList, <PlutoRow<dynamic>>[child]);
    expect(child.type.group.children.originalList, <PlutoRow<dynamic>>[leaf]);
    expect(leaf.cells['value']!.currentValue, 'leaf');
  });

  testWidgets('disposing cancels delayed grid events', (
    WidgetTester tester,
  ) async {
    final FocusNode focus = FocusNode();
    final PlutoGridStateManager manager = PlutoGridStateManager(
      columns: <PlutoColumn>[],
      rows: <PlutoRow<dynamic>>[],
      gridFocusNode: focus,
      scroll: PlutoGridScrollController(),
    );
    final PlutoGridEventManager events = PlutoGridEventManager(
      stateManager: manager,
    )..init();
    int handled = 0;
    events.addEvent(_DelayedEvent(() => handled++));
    await tester.pump();
    events.dispose();
    manager.dispose();
    focus.dispose();
    await tester.pump(const Duration(seconds: 2));
    expect(handled, 0);
    expect(events.subject.isClosed, isTrue);
  });
}

PlutoColumn _textColumn(String field) => PlutoColumn(
  title: field,
  field: field,
  type: PlutoColumnType.text(),
);

PlutoRow<dynamic> _row(String value) => PlutoRow<dynamic>(
  cells: <String, PlutoCell>{'value': PlutoCell(value: value)},
);

PlutoRow<dynamic> _group(String value, List<PlutoRow<dynamic>> children) =>
    PlutoRow<dynamic>(
      cells: <String, PlutoCell>{'value': PlutoCell(value: value)},
      type: PlutoRowType.group(
        children: FilteredList<PlutoRow<dynamic>>(initialList: children),
      ),
    );

_DisposedManager _createDisposedManager() {
  final PlutoColumn column = _textColumn('value');
  final PlutoColumn hidden = _textColumn('hidden')..hide = true;
  final PlutoColumnGroup group = PlutoColumnGroup(
    title: 'Group',
    fields: <String>['value'],
  );
  final PlutoRow<dynamic> row = PlutoRow<dynamic>(
    cells: <String, PlutoCell>{
      'value': PlutoCell(value: 'value'),
      'hidden': PlutoCell(value: 'hidden'),
    },
  );
  final List<int> payload = List<int>.filled(10000, 1);
  final PlutoRow<dynamic> filter = FilterHelper.createFilterRow(
    columnField: 'value',
    filterValue: 'value',
    filterValueObject: payload,
  );
  final FocusNode focus = FocusNode();
  final PlutoGridStateManager manager = PlutoGridStateManager(
    columns: <PlutoColumn>[column, hidden],
    rows: <PlutoRow<dynamic>>[row],
    columnGroups: <PlutoColumnGroup>[group],
    gridFocusNode: focus,
    scroll: PlutoGridScrollController(),
  );
  final PlutoRowGroupDelegate delegate = PlutoRowGroupByColumnDelegate(
    columns: <PlutoColumn>[column],
  );
  manager
    ..setRowGroup(delegate, notify: false)
    ..setFilterWithFilterRows(<PlutoRow<dynamic>>[filter], notify: false)
    ..savedFilter = ((PlutoRow<dynamic> candidate) => payload.isNotEmpty)
    ..setDragRows(<PlutoRow<dynamic>>[row], notify: false);
  final _DisposedManager fixture = _DisposedManager(
    manager,
    <WeakReference<Object>>[
      WeakReference<Object>(column),
      WeakReference<Object>(hidden),
      WeakReference<Object>(group),
      WeakReference<Object>(row),
      WeakReference<Object>(filter),
      WeakReference<Object>(payload),
      WeakReference<Object>(delegate),
    ],
  );
  manager.dispose();
  focus.dispose();
  return fixture;
}

class _DisposedManager {
  const _DisposedManager(this.manager, this.references);
  final PlutoGridStateManager manager;
  final List<WeakReference<Object>> references;
}

class _DelayedEvent extends PlutoGridEvent {
  _DelayedEvent(this.callback)
    : super(
        type: PlutoGridEventType.debounce,
        duration: const Duration(seconds: 1),
      );
  final VoidCallback callback;

  @override
  void handler(PlutoGridStateManager stateManager) => callback();
}
