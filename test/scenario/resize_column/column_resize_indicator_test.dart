import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:pluto_grid_plus/src/ui/ui.dart';

import '../../helper/column_helper.dart';
import '../../helper/row_helper.dart';
import '../../helper/test_helper_util.dart';

void desktopTestWidgets(
  String description,
  WidgetTesterCallback callback,
) {
  testWidgets(description, (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await callback(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  const ValueKey<String> indicatorKey = ValueKey<String>(
    'FullHeightColumnResizeIndicator',
  );
  const ValueKey<String> overlayKey = ValueKey<String>(
    'ColumnResizeIndicatorOverlay',
  );
  const ValueKey<String> footerIndicatorKey = ValueKey<String>(
    'ColumnFooterResizeIndicator',
  );
  const ValueKey<String> footerContentKey = ValueKey<String>(
    'ResizeIndicatorTestFooter',
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
    Color indicatorColor = Colors.grey,
    double handleWidth = PlutoGridSettings.columnResizeHandleWidth,
    double indicatorWidth = PlutoGridSettings.columnResizeHandleActiveWidth,
    Duration indicatorAnimationDuration =
        PlutoGridSettings.columnResizeIndicatorAnimationDuration,
    Duration cursorDelay = Duration.zero,
    Duration indicatorHoverDelay = Duration.zero,
    bool showColumnFooter = false,
  }) async {
    if (showColumnFooter) {
      columns.first.footerRenderer = (_) =>
          const SizedBox.expand(key: footerContentKey);
    }

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
                  columnResizeIndicatorColor: indicatorColor,
                  columnResizeHandleWidth: handleWidth,
                  columnResizeIndicatorWidth: indicatorWidth,
                  columnResizeIndicatorAnimationDuration:
                      indicatorAnimationDuration,
                  columnResizeCursorDelay: cursorDelay,
                  columnResizeIndicatorHoverDelay: indicatorHoverDelay,
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
    String field,
  ) async {
    final Finder handle = find.byKey(
      ValueKey<String>('body_resize_handle_$field'),
    );
    final TestGesture mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );

    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(handle));
    await tester.pumpAndSettle();

    return mouse;
  }

  desktopTestWidgets(
    'fullHeight mode highlights one centered boundary through the grid',
    (WidgetTester tester) async {
      await buildGrid(tester);

      final Finder handle = find.byKey(
        const ValueKey<String>('body_resize_handle_column0'),
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
        closeTo(tester.getCenter(handle).dx, 0.01),
      );
      expect(
        tester.getBottomRight(indicator).dy,
        closeTo(tester.getBottomRight(find.byType(PlutoBaseRow).last).dy, 0.51),
      );

      await mouse.removePointer();
    },
  );

  desktopTestWidgets(
    'hover delay prevents transient indicators and uses configured styling',
    (WidgetTester tester) async {
      const Duration cursorDelay = Duration(milliseconds: 100);
      const Duration hoverDelay = Duration(milliseconds: 180);
      const Duration animationDuration = Duration(milliseconds: 200);
      const Color indicatorColor = Colors.deepOrange;

      await buildGrid(
        tester,
        indicatorColor: indicatorColor,
        indicatorAnimationDuration: animationDuration,
        cursorDelay: cursorDelay,
        indicatorHoverDelay: hoverDelay,
      );

      final Finder handle = find.byKey(
        const ValueKey<String>('body_resize_handle_column0'),
      );
      final Finder indicator = find.byKey(indicatorKey);
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(handle));
      await tester.pump();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        isNot(SystemMouseCursors.resizeLeftRight),
      );
      expect(indicator, findsNothing);

      await tester.pump(cursorDelay - const Duration(milliseconds: 1));
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        isNot(SystemMouseCursors.resizeLeftRight),
      );
      expect(indicator, findsNothing);

      await tester.pump(const Duration(milliseconds: 1));
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.resizeLeftRight,
      );
      expect(indicator, findsNothing);

      await tester.pump(
        hoverDelay - cursorDelay - const Duration(milliseconds: 1),
      );
      expect(indicator, findsNothing);

      await tester.pump(const Duration(milliseconds: 1));
      expect(indicator, findsOneWidget);

      final AnimatedContainer indicatorWidget = tester.widget(indicator);
      final BoxDecoration decoration =
          indicatorWidget.decoration! as BoxDecoration;

      expect(indicatorWidget.duration, animationDuration);
      expect(decoration.color, indicatorColor);

      await mouse.removePointer();
    },
  );

  desktopTestWidgets(
    'leaving a resize boundary before the hover delay shows no indicator',
    (WidgetTester tester) async {
      const Duration hoverDelay = Duration(milliseconds: 120);

      await buildGrid(
        tester,
        cursorDelay: hoverDelay,
        indicatorHoverDelay: hoverDelay,
      );

      final Finder handle = find.byKey(
        const ValueKey<String>('body_resize_handle_column0'),
      );
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 40));
      await mouse.moveTo(const Offset(350, 450));
      await tester.pump(hoverDelay);

      expect(find.byKey(indicatorKey), findsNothing);
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        isNot(SystemMouseCursors.resizeLeftRight),
      );

      await mouse.removePointer();
    },
  );

  desktopTestWidgets(
    'dragging shows the indicator without waiting for the hover delay',
    (WidgetTester tester) async {
      const Duration hoverDelay = Duration(seconds: 1);

      await buildGrid(
        tester,
        indicatorAnimationDuration: Duration.zero,
        cursorDelay: hoverDelay,
        indicatorHoverDelay: hoverDelay,
      );

      final Finder handle = find.byKey(
        const ValueKey<String>('body_resize_handle_column0'),
      );
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(handle));
      await tester.pump();
      expect(find.byKey(indicatorKey), findsNothing);

      await mouse.down(tester.getCenter(handle));
      await mouse.moveBy(const Offset(20, 0));
      await tester.pump();

      expect(find.byKey(indicatorKey), findsOneWidget);
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.resizeLeftRight,
      );

      await mouse.up();
      await mouse.removePointer();
    },
  );

  desktopTestWidgets(
    'fullHeight indicator also highlights the column footer',
    (WidgetTester tester) async {
      await buildGrid(
        tester,
        indicatorAnimationDuration: Duration.zero,
        showColumnFooter: true,
      );

      final TestGesture mouse = await hoverHandle(tester, 'column0');
      final Finder rowIndicator = find.byKey(indicatorKey);
      final Finder footerIndicator = find.byKey(footerIndicatorKey);
      final Rect footerRect = tester.getRect(find.byKey(footerContentKey));
      final Rect footerIndicatorRect = tester.getRect(footerIndicator);

      expect(rowIndicator, findsOneWidget);
      expect(footerIndicator, findsOneWidget);
      expect(footerIndicatorRect.top, closeTo(footerRect.top, 0.01));
      expect(footerIndicatorRect.bottom, closeTo(footerRect.bottom, 0.01));
      expect(
        tester.getRect(rowIndicator).bottom,
        lessThan(footerIndicatorRect.top),
      );

      await mouse.removePointer();
    },
  );

  desktopTestWidgets(
    'column boundary has an equal hit area on both sides',
    (WidgetTester tester) async {
      const double handleWidth = 20;
      const double indicatorWidth = 5;

      await buildGrid(
        tester,
        handleWidth: handleWidth,
        indicatorWidth: indicatorWidth,
      );

      final Finder bodyHandle = find.byKey(
        const ValueKey<String>('body_resize_handle_column0'),
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
      final Rect bodyRect = tester.getRect(bodyHandle);
      final Rect headerEndRect = tester.getRect(headerEndHalf);
      final Rect headerStartRect = tester.getRect(headerStartHalf);
      final double boundaryX = bodyRect.center.dx;

      expect(bodyRect.width, handleWidth);
      expect(headerEndRect.width, handleWidth / 2);
      expect(headerStartRect.width, handleWidth / 2);
      expect(headerEndRect.right, closeTo(headerStartRect.left, 0.01));
      expect(headerEndRect.right, closeTo(boundaryX, 0.01));

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);

      await mouse.moveTo(bodyRect.center);
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.resizeLeftRight,
      );
      expect(tester.getSize(indicator).width, indicatorWidth);
      expect(tester.getCenter(indicator).dx, closeTo(boundaryX, 0.01));

      final double previousWidth = columns.first.width;
      await mouse.down(bodyRect.center);
      await mouse.moveBy(const Offset(20, 0));
      await mouse.up();
      await tester.pumpAndSettle();

      expect(columns.first.width, previousWidth + 20);

      await mouse.removePointer();
    },
  );

  desktopTestWidgets(
    'column boundary hit area is centered in RTL',
    (WidgetTester tester) async {
      await buildGrid(tester, textDirection: TextDirection.rtl);

      final Finder bodyHandle = find.byKey(
        const ValueKey<String>('body_resize_handle_column0'),
      );
      final Finder indicator = find.byKey(indicatorKey);
      final Finder lastBodyHandle = find.byKey(
        const ValueKey<String>('body_resize_handle_column2'),
      );
      final Finder lastHeaderEndHalf = find.byKey(
        const ValueKey<String>('column_resize_handle_column2'),
      );
      final Rect bodyRect = tester.getRect(bodyHandle);
      final Rect lastBodyRect = tester.getRect(lastBodyHandle);
      final Rect lastHeaderEndRect = tester.getRect(lastHeaderEndHalf);
      final double boundaryX = bodyRect.center.dx;

      expect(bodyRect.width, stateManager.style.columnResizeHandleWidth);
      expect(
        lastBodyRect.center.dx,
        closeTo(lastHeaderEndRect.left, 0.01),
      );

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(bodyRect.center);
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.resizeLeftRight,
      );
      expect(tester.getCenter(indicator).dx, closeTo(boundaryX, 0.01));

      await mouse.removePointer();
    },
  );

  desktopTestWidgets(
    'last column boundary remains centered over the trailing blank area',
    (WidgetTester tester) async {
      const double handleWidth = 20;

      await buildGrid(tester, handleWidth: handleWidth);

      final Finder bodyHandle = find.byKey(
        const ValueKey<String>('body_resize_handle_column2'),
      );
      final Finder headerEndHalf = find.byKey(
        const ValueKey<String>('column_resize_handle_column2'),
      );
      final Finder headerGutterHalf = find.byKey(
        const ValueKey<String>('column_resize_handle_end_gutter_column2'),
      );
      final Finder indicator = find.byKey(indicatorKey);
      final Rect bodyRect = tester.getRect(bodyHandle);
      final Rect headerEndRect = tester.getRect(headerEndHalf);
      final Rect headerGutterRect = tester.getRect(headerGutterHalf);
      final double boundaryX = bodyRect.center.dx;

      expect(bodyRect.width, handleWidth);
      expect(headerGutterRect.left, closeTo(headerEndRect.right, 0.01));
      expect(headerGutterRect.width, handleWidth / 2);
      expect(headerEndRect.right, closeTo(boundaryX, 0.01));

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(bodyRect.center);
      await tester.pumpAndSettle();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.resizeLeftRight,
      );
      expect(tester.getCenter(indicator).dx, closeTo(boundaryX, 0.01));

      final double previousWidth = columns.last.width;
      await mouse.down(bodyRect.center);
      await mouse.moveBy(const Offset(20, 0));
      await mouse.up();
      await tester.pumpAndSettle();

      expect(columns.last.width, previousWidth + 20);

      await mouse.removePointer();
    },
  );

  desktopTestWidgets(
    'cell indicator stays centered when hovering the start half',
    (WidgetTester tester) async {
      const double indicatorWidth = 5;

      await buildGrid(
        tester,
        indicatorMode: PlutoColumnResizeIndicatorMode.cell,
        indicatorWidth: indicatorWidth,
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
        indicatorWidth,
      );
      expect(
        tester.getCenter(localIndicator).dx,
        closeTo(startRect.left, 0.01),
      );

      await mouse.removePointer();
    },
  );

  desktopTestWidgets(
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

  desktopTestWidgets(
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
        const ValueKey<String>('body_resize_handle_updated'),
      );
      final double boundaryBefore = tester.getCenter(handle).dx;

      stateManager.autoFitColumn(
        tester.element(find.byType(PlutoGrid)),
        column,
      );

      expect(column.width, column.minWidth);

      await tester.pump();

      final double boundaryAfter = tester.getCenter(handle).dx;
      expect(
        boundaryBefore - boundaryAfter,
        closeTo(180 - column.minWidth, 0.01),
      );
    },
  );

  desktopTestWidgets(
    'fullHeight mode uses the actual boundary of a frozen column',
    (WidgetTester tester) async {
      columns.first.frozen = PlutoColumnFrozen.start;
      columns.last.frozen = PlutoColumnFrozen.end;
      await buildGrid(tester);

      final Finder handle = find.byKey(
        const ValueKey<String>('body_resize_handle_column0'),
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

  desktopTestWidgets(
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

  desktopTestWidgets(
    'body resize handles stay constant and forward vertical wheel scrolling',
    (WidgetTester tester) async {
      rows = RowHelper.count(30, columns);
      await buildGrid(tester);

      final Finder bodyHandles = find.byWidgetPredicate((Widget widget) {
        final Key? key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('body_resize_handle_');
      });
      final Finder firstHandle = find.byKey(
        const ValueKey<String>('body_resize_handle_column0'),
      );
      final ScrollController verticalScroll =
          stateManager.scroll.bodyRowsVertical!;

      expect(bodyHandles, findsNWidgets(columns.length));
      expect(verticalScroll.offset, 0);

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(firstHandle),
          scrollDelta: const Offset(0, 120),
          kind: PointerDeviceKind.mouse,
        ),
      );
      await tester.pump();

      expect(verticalScroll.offset, greaterThan(0));
      expect(bodyHandles, findsNWidgets(columns.length));
    },
  );

  desktopTestWidgets(
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
            const ValueKey<String>('body_resize_handle_column1'),
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
