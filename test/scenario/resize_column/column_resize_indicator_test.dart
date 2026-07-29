import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import '../../helper/column_helper.dart';
import '../../helper/row_helper.dart';
import '../../helper/test_helper_util.dart';

void main() {
  const ValueKey<String> indicatorKey = ValueKey<String>(
    'FullHeightColumnResizeIndicator',
  );
  const ValueKey<String> overlayKey = ValueKey<String>(
    'ColumnResizeIndicatorOverlay',
  );

  late List<PlutoColumn> columns;
  late List<PlutoRow<dynamic>> rows;
  late PlutoGridStateManager stateManager;

  setUp(() {
    columns = ColumnHelper.textColumn('column', count: 3, width: 160);
    rows = RowHelper.count(5, columns);
  });

  Future<void> buildGrid(
    WidgetTester tester, {
    List<PlutoColumnGroup>? columnGroups,
    TextDirection textDirection = TextDirection.ltr,
    PlutoColumnResizeIndicatorMode indicatorMode =
        PlutoColumnResizeIndicatorMode.fullHeight,
  }) async {
    await TestHelperUtil.changeWidth(
      tester: tester,
      width: 700,
      height: 500,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Directionality(
            textDirection: textDirection,
            child: PlutoGrid(
              columns: columns,
              columnGroups: columnGroups,
              rows: rows,
              configuration: PlutoGridConfiguration(
                style: PlutoGridStyleConfig(
                  columnResizeIndicatorMode: indicatorMode,
                  rowBorderWidth: 0.5,
                ),
              ),
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<TestGesture> hoverHandle(
    WidgetTester tester,
    String field, {
    int rowIdx = 0,
  }) async {
    final Finder handle = find.byKey(
      ValueKey<String>('cell_resize_handle_${field}_$rowIdx'),
    );
    final TestGesture mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );

    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(handle));
    await tester.pumpAndSettle();

    return mouse;
  }

  testWidgets(
    'fullHeight mode highlights one centered boundary through the grid',
    (WidgetTester tester) async {
      await buildGrid(tester);

      final Finder handle = find.byKey(
        const ValueKey<String>('cell_resize_handle_column0_0'),
      );
      final Finder lastRowHandle = find.byKey(
        const ValueKey<String>('cell_resize_handle_column0_4'),
      );
      final TestGesture mouse = await hoverHandle(tester, 'column0');
      final Finder indicator = find.byKey(indicatorKey);

      expect(indicator, findsOneWidget);
      expect(
        tester.getSize(indicator).width,
        PlutoGridSettings.columnResizeHandleActiveWidth,
      );
      expect(
        tester.getSize(indicator).height,
        greaterThan(stateManager.rowHeight * rows.length),
      );
      expect(
        tester.getCenter(indicator).dx,
        closeTo(tester.getTopRight(handle).dx, 0.01),
      );
      expect(
        tester.getBottomRight(indicator).dy,
        closeTo(tester.getBottomRight(lastRowHandle).dy, 0.01),
      );

      await mouse.removePointer();
    },
  );

  testWidgets(
    'column boundary has an equal hit area on both sides',
    (WidgetTester tester) async {
      await buildGrid(tester);

      final Finder endHalf = find.byKey(
        const ValueKey<String>('cell_resize_handle_column0_0'),
      );
      final Finder startHalf = find.byKey(
        const ValueKey<String>(
          'cell_resize_handle_start_column1_for_column0_0',
        ),
      );
      final Finder indicator = find.byKey(indicatorKey);
      final Finder headerEndHalf = find.byKey(
        const ValueKey<String>('column_resize_handle_column0'),
      );
      final Finder headerStartHalf = find.byKey(
        const ValueKey<String>(
          'column_resize_handle_start_column1_for_column0',
        ),
      );
      final Rect endRect = tester.getRect(endHalf);
      final Rect startRect = tester.getRect(startHalf);
      final Rect headerEndRect = tester.getRect(headerEndHalf);
      final Rect headerStartRect = tester.getRect(headerStartHalf);
      final double boundaryX = endRect.right;

      expect(
        endRect.width,
        PlutoGridSettings.columnResizeHandleWidth / 2,
      );
      expect(
        startRect.width,
        PlutoGridSettings.columnResizeHandleWidth / 2,
      );
      expect(startRect.left, closeTo(boundaryX, 0.01));
      expect(headerEndRect.width, endRect.width);
      expect(headerStartRect.width, startRect.width);
      expect(headerEndRect.right, closeTo(headerStartRect.left, 0.01));

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);

      await mouse.moveTo(endRect.center);
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.resizeLeftRight,
      );
      expect(tester.getCenter(indicator).dx, closeTo(boundaryX, 0.01));

      await mouse.moveTo(startRect.center);
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.resizeLeftRight,
      );
      expect(tester.getCenter(indicator).dx, closeTo(boundaryX, 0.01));

      final double previousWidth = columns.first.width;
      await mouse.down(startRect.center);
      await mouse.moveBy(const Offset(20, 0));
      await mouse.up();
      await tester.pumpAndSettle();

      expect(columns.first.width, previousWidth + 20);

      await mouse.removePointer();
    },
  );

  testWidgets(
    'column boundary hit area is centered in RTL',
    (WidgetTester tester) async {
      await buildGrid(tester, textDirection: TextDirection.rtl);

      final Finder endHalf = find.byKey(
        const ValueKey<String>('cell_resize_handle_column0_0'),
      );
      final Finder startHalf = find.byKey(
        const ValueKey<String>(
          'cell_resize_handle_start_column1_for_column0_0',
        ),
      );
      final Finder indicator = find.byKey(indicatorKey);
      final Finder lastEndHalf = find.byKey(
        const ValueKey<String>('cell_resize_handle_column2_0'),
      );
      final Finder lastGutterHalf = find.byKey(
        const ValueKey<String>('cell_resize_handle_end_gutter_column2_0'),
      );
      final Rect endRect = tester.getRect(endHalf);
      final Rect startRect = tester.getRect(startHalf);
      final Rect lastEndRect = tester.getRect(lastEndHalf);
      final Rect lastGutterRect = tester.getRect(lastGutterHalf);
      final double boundaryX = endRect.left;

      expect(startRect.right, closeTo(boundaryX, 0.01));
      expect(lastGutterRect.right, closeTo(lastEndRect.left, 0.01));

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(startRect.center);
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.resizeLeftRight,
      );
      expect(tester.getCenter(indicator).dx, closeTo(boundaryX, 0.01));

      await mouse.removePointer();
    },
  );

  testWidgets(
    'last column boundary remains centered over the trailing blank area',
    (WidgetTester tester) async {
      await buildGrid(tester);

      final Finder endHalf = find.byKey(
        const ValueKey<String>('cell_resize_handle_column2_0'),
      );
      final Finder gutterHalf = find.byKey(
        const ValueKey<String>('cell_resize_handle_end_gutter_column2_0'),
      );
      final Finder headerEndHalf = find.byKey(
        const ValueKey<String>('column_resize_handle_column2'),
      );
      final Finder headerGutterHalf = find.byKey(
        const ValueKey<String>('column_resize_handle_end_gutter_column2'),
      );
      final Finder indicator = find.byKey(indicatorKey);
      final Rect endRect = tester.getRect(endHalf);
      final Rect gutterRect = tester.getRect(gutterHalf);
      final Rect headerEndRect = tester.getRect(headerEndHalf);
      final Rect headerGutterRect = tester.getRect(headerGutterHalf);
      final double boundaryX = endRect.right;

      expect(gutterRect.left, closeTo(boundaryX, 0.01));
      expect(headerGutterRect.left, closeTo(headerEndRect.right, 0.01));

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(gutterRect.center);
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.resizeLeftRight,
      );
      expect(tester.getCenter(indicator).dx, closeTo(boundaryX, 0.01));

      final double previousWidth = columns.last.width;
      await mouse.down(gutterRect.center);
      await mouse.moveBy(const Offset(20, 0));
      await mouse.up();
      await tester.pumpAndSettle();

      expect(columns.last.width, previousWidth + 20);

      await mouse.removePointer();
    },
  );

  testWidgets(
    'cell indicator stays centered when hovering the start half',
    (WidgetTester tester) async {
      await buildGrid(
        tester,
        indicatorMode: PlutoColumnResizeIndicatorMode.cell,
      );

      final Finder startHalf = find.byKey(
        const ValueKey<String>(
          'cell_resize_handle_start_column1_for_column0_0',
        ),
      );
      final Finder localIndicator = find.descendant(
        of: startHalf,
        matching: find.byKey(
          const ValueKey<String>('ColumnResizeHandleIndicator'),
        ),
      );
      final Rect startRect = tester.getRect(startHalf);
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(startRect.center);
      await tester.pumpAndSettle();

      expect(
        tester.getSize(localIndicator).width,
        PlutoGridSettings.columnResizeHandleActiveWidth,
      );
      expect(
        tester.getCenter(localIndicator).dx,
        closeTo(startRect.left, 0.01),
      );

      await mouse.removePointer();
    },
  );

  testWidgets(
    'column can fall back to a header-only resize indicator',
    (WidgetTester tester) async {
      columns.first.columnResizeIndicatorMode =
          PlutoColumnResizeIndicatorMode.header;
      await buildGrid(
        tester,
        columnGroups: <PlutoColumnGroup>[
          PlutoColumnGroup(
            title: 'Group A',
            fields: <String>['column0', 'column1'],
          ),
          PlutoColumnGroup(
            title: 'Group B',
            fields: <String>['column2'],
          ),
        ],
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'column_resize_handle_start_column1_for_column0',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'column_resize_handle_start_column2_for_column1',
          ),
        ),
        findsOneWidget,
      );

      final TestGesture mouse = await hoverHandle(tester, 'column0');
      final Finder indicator = find.byKey(indicatorKey);
      final Finder overlay = find.byKey(overlayKey);

      expect(tester.getSize(indicator).height, stateManager.columnHeight);
      expect(
        tester.getTopLeft(indicator).dy - tester.getTopLeft(overlay).dy,
        closeTo(stateManager.columnGroupHeight, 0.01),
      );

      await mouse.removePointer();
    },
  );

  testWidgets(
    'auto fit relayouts immediately when the width clamps to minWidth',
    (WidgetTester tester) async {
      final PlutoColumn column = PlutoColumn(
        title: 'U',
        field: 'updated',
        type: PlutoColumnType.text(),
        width: 180,
      );
      columns = <PlutoColumn>[column];
      rows = <PlutoRow<dynamic>>[
        PlutoRow<dynamic>(
          cells: <String, PlutoCell>{
            column.field: PlutoCell(value: 'x'),
          },
        ),
      ];
      await buildGrid(tester);

      final Finder handle = find.byKey(
        const ValueKey<String>('cell_resize_handle_updated_0'),
      );
      final double boundaryBefore = tester.getTopRight(handle).dx;

      stateManager.autoFitColumn(
        tester.element(find.byType(PlutoGrid)),
        column,
      );

      expect(column.width, column.minWidth);

      await tester.pump();

      final double boundaryAfter = tester.getTopRight(handle).dx;
      expect(
        boundaryBefore - boundaryAfter,
        closeTo(180 - column.minWidth, 0.01),
      );
    },
  );

  testWidgets(
    'fullHeight mode uses the actual boundary of a frozen column',
    (WidgetTester tester) async {
      columns.first.frozen = PlutoColumnFrozen.start;
      columns.last.frozen = PlutoColumnFrozen.end;
      await buildGrid(tester);

      final Finder handle = find.byKey(
        const ValueKey<String>('cell_resize_handle_column0_0'),
      );
      final TestGesture mouse = await hoverHandle(tester, 'column0');
      final Finder indicator = find.byKey(indicatorKey);

      expect(
        tester.getCenter(indicator).dx,
        closeTo(tester.getTopRight(handle).dx, 0.01),
      );

      await mouse.removePointer();
    },
  );

  testWidgets(
    'fullHeight mode is limited by the viewport when rows overflow it',
    (WidgetTester tester) async {
      rows = RowHelper.count(30, columns);
      await buildGrid(tester);

      final TestGesture mouse = await hoverHandle(tester, 'column0');
      final Finder indicator = find.byKey(indicatorKey);
      final Finder overlay = find.byKey(overlayKey);

      expect(
        tester.getBottomRight(indicator).dy,
        closeTo(tester.getBottomRight(overlay).dy, 0.01),
      );

      await mouse.removePointer();
    },
  );

  testWidgets(
    'fullHeight mode does not cut a shared grouped header',
    (WidgetTester tester) async {
      await buildGrid(
        tester,
        columnGroups: <PlutoColumnGroup>[
          PlutoColumnGroup(
            title: 'Group A',
            fields: <String>['column0', 'column1'],
          ),
          PlutoColumnGroup(
            title: 'Group B',
            fields: <String>['column2'],
          ),
        ],
      );

      final Finder overlay = find.byKey(overlayKey);
      final TestGesture mouse = await hoverHandle(tester, 'column0');
      final Finder indicator = find.byKey(indicatorKey);

      expect(
        tester.getTopLeft(indicator).dy - tester.getTopLeft(overlay).dy,
        closeTo(stateManager.columnGroupHeight, 0.01),
      );

      await mouse.moveTo(
        tester.getCenter(
          find.byKey(
            const ValueKey<String>('cell_resize_handle_column1_0'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(indicator).dy,
        closeTo(tester.getTopLeft(overlay).dy, 0.01),
      );

      await mouse.removePointer();
    },
  );
}
