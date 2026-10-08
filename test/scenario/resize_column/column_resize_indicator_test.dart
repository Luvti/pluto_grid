import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
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
    bool enableRowHoverColor = false,
    PlutoOnRowEnterEventCallback? onRowEnter,
    PlutoOnRowExitEventCallback? onRowExit,
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
                  enableRowHoverColor: enableRowHoverColor,
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
              onRowEnter: onRowEnter,
              onRowExit: onRowExit,
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

  Color? rowColor(WidgetTester tester, Finder row) {
    final DecoratedBox decoration = tester.widget<DecoratedBox>(
      find.descendant(of: row, matching: find.byType(DecoratedBox)).first,
    );
    return (decoration.decoration as BoxDecoration).color;
  }

  for (final TextDirection direction in TextDirection.values) {
    desktopTestWidgets(
      'row hover covers the first pinned column and all row sections in ${direction.name}',
      (WidgetTester tester) async {
        columns.first.frozen = PlutoColumnFrozen.start;
        columns.last.frozen = PlutoColumnFrozen.end;
        int cellBuilds = 0;
        for (final PlutoColumn column in columns) {
          column.renderer = (_) {
            cellBuilds += 1;
            return const SizedBox.expand();
          };
        }
        await buildGrid(
          tester,
          textDirection: direction,
          enableRowHoverColor: true,
        );

        List<Finder> rowSections(int rowIdx) => <Finder>[
          find.byKey(ValueKey<String>('left_frozen_row_${rows[rowIdx].key}')),
          find.byKey(ValueKey<String>('body_row_${rows[rowIdx].key}')),
          find.byKey(ValueKey<String>('right_frozen_row_${rows[rowIdx].key}')),
        ];
        final List<Finder> firstSections = rowSections(0);
        final List<Finder> secondSections = rowSections(1);
        final List<PlutoNotifierEvent> notifications = <PlutoNotifierEvent>[];
        final StreamSubscription<PlutoNotifierEvent> subscription = stateManager
            .streamNotifier
            .listen(notifications.add);
        final int initialCellBuilds = cellBuilds;
        final TestGesture mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: Offset.zero);

        for (final int section in <int>[1, 0, 1, 2]) {
          await mouse.moveTo(tester.getCenter(firstSections[section]));
          await tester.pumpAndSettle();

          for (final Finder row in firstSections) {
            expect(rowColor(tester, row), stateManager.style.rowHoveredColor);
          }
          expect(stateManager.hoveredRowIdx, 0);
        }

        final Rect bodyHandle = tester.getRect(
          find.byKey(const ValueKey<String>('body_resize_handle_column1')),
        );
        await mouse.moveTo(
          Offset(bodyHandle.center.dx, tester.getCenter(firstSections[1]).dy),
        );
        await tester.pumpAndSettle();

        for (final Finder row in firstSections) {
          expect(rowColor(tester, row), stateManager.style.rowHoveredColor);
        }

        await mouse.moveTo(tester.getCenter(secondSections.first));
        await tester.pumpAndSettle();

        for (final Finder row in firstSections) {
          expect(
            rowColor(tester, row),
            isNot(stateManager.style.rowHoveredColor),
          );
        }
        for (final Finder row in secondSections) {
          expect(rowColor(tester, row), stateManager.style.rowHoveredColor);
        }
        expect(stateManager.hoveredRowIdx, 1);

        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();

        for (final Finder row in secondSections) {
          expect(
            rowColor(tester, row),
            isNot(stateManager.style.rowHoveredColor),
          );
        }
        expect(stateManager.hoveredRowIdx, isNull);
        expect(notifications, isEmpty);
        expect(cellBuilds, initialCellBuilds);

        await tester.runAsync(subscription.cancel);
        await mouse.removePointer();
      },
    );
  }

  for (final TextDirection direction in TextDirection.values) {
    for (final PlutoColumnResizeIndicatorMode mode
        in <PlutoColumnResizeIndicatorMode>[
          PlutoColumnResizeIndicatorMode.fullHeight,
          PlutoColumnResizeIndicatorMode.header,
        ]) {
      desktopTestWidgets(
        'row hover survives crossing a ${mode.name} resize handle in ${direction.name}',
        (WidgetTester tester) async {
          final List<int?> enteredRows = <int?>[];
          final List<int?> exitedRows = <int?>[];
          await buildGrid(
            tester,
            textDirection: direction,
            indicatorMode: mode,
            enableRowHoverColor: true,
            onRowEnter: (PlutoGridOnRowEnterEvent event) =>
                enteredRows.add(event.rowIdx),
            onRowExit: (PlutoGridOnRowExitEvent event) =>
                exitedRows.add(event.rowIdx),
          );

          final Finder firstRow = find.byKey(
            ValueKey<String>('body_row_${rows.first.key}'),
          );
          final Finder secondRow = find.byKey(
            ValueKey<String>('body_row_${rows[1].key}'),
          );
          final Rect handleRect = tester.getRect(
            find.byKey(const ValueKey<String>('body_resize_handle_column0')),
          );
          final double rowY = tester.getCenter(firstRow).dy;
          final TestGesture mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          await mouse.moveTo(Offset(handleRect.left - handleRect.width, rowY));
          await tester.pumpAndSettle();

          expect(
            rowColor(tester, firstRow),
            stateManager.style.rowHoveredColor,
          );
          expect(stateManager.hoveredRowIdx, 0);
          expect(enteredRows, <int>[0]);

          final List<PlutoNotifierEvent> notifications = <PlutoNotifierEvent>[];
          final StreamSubscription<PlutoNotifierEvent> subscription =
              stateManager.streamNotifier.listen(
                notifications.add,
              );

          for (final double x in <double>[
            handleRect.left + handleRect.width / 4,
            handleRect.center.dx,
            handleRect.right - handleRect.width / 4,
            handleRect.right + handleRect.width,
          ]) {
            await mouse.moveTo(Offset(x, rowY));
            await tester.pumpAndSettle();

            expect(
              rowColor(tester, firstRow),
              stateManager.style.rowHoveredColor,
            );
            expect(stateManager.hoveredRowIdx, 0);
            expect(enteredRows, <int>[0]);
            expect(exitedRows, isEmpty);
          }

          await mouse.moveTo(
            Offset(handleRect.center.dx, tester.getCenter(secondRow).dy),
          );
          await tester.pumpAndSettle();

          expect(
            rowColor(tester, firstRow),
            isNot(stateManager.style.rowHoveredColor),
          );
          expect(
            rowColor(tester, secondRow),
            stateManager.style.rowHoveredColor,
          );
          expect(stateManager.hoveredRowIdx, 1);
          expect(enteredRows, <int>[0, 1]);
          expect(exitedRows, <int>[0]);

          await mouse.moveTo(Offset.zero);
          await tester.pumpAndSettle();

          expect(
            rowColor(tester, secondRow),
            isNot(stateManager.style.rowHoveredColor),
          );
          expect(stateManager.hoveredRowIdx, isNull);
          expect(exitedRows, <int>[0, 1]);
          expect(notifications, isEmpty);

          await tester.runAsync(subscription.cancel);
          await mouse.removePointer();
        },
      );
    }
  }

  for (final PlutoColumnFrozen frozen in <PlutoColumnFrozen>[
    PlutoColumnFrozen.start,
    PlutoColumnFrozen.end,
  ]) {
    desktopTestWidgets(
      'row hover survives crossing a resize handle in ${frozen.name} frozen columns',
      (WidgetTester tester) async {
        final bool isStart = frozen == PlutoColumnFrozen.start;
        final List<PlutoColumn> frozenColumns = isStart
            ? columns.take(2).toList()
            : columns.skip(1).toList();
        for (final PlutoColumn column in frozenColumns) {
          column.frozen = frozen;
        }
        await buildGrid(tester, enableRowHoverColor: true);

        final String rowPrefix = isStart ? 'left' : 'right';
        final Finder firstRow = find.byKey(
          ValueKey<String>('${rowPrefix}_frozen_row_${rows.first.key}'),
        );
        final Finder secondRow = find.byKey(
          ValueKey<String>('${rowPrefix}_frozen_row_${rows[1].key}'),
        );
        final Rect handleRect = tester.getRect(
          find.byKey(
            ValueKey<String>('body_resize_handle_${frozenColumns.first.field}'),
          ),
        );
        final double rowY = tester.getCenter(firstRow).dy;
        final TestGesture mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: Offset.zero);

        for (final double x in <double>[
          handleRect.left - handleRect.width,
          handleRect.center.dx,
          handleRect.right + handleRect.width,
        ]) {
          await mouse.moveTo(Offset(x, rowY));
          await tester.pumpAndSettle();

          expect(
            rowColor(tester, firstRow),
            stateManager.style.rowHoveredColor,
          );
          expect(stateManager.hoveredRowIdx, 0);
        }

        await mouse.moveTo(
          Offset(handleRect.center.dx, tester.getCenter(secondRow).dy),
        );
        await tester.pumpAndSettle();

        expect(
          rowColor(tester, firstRow),
          isNot(stateManager.style.rowHoveredColor),
        );
        expect(rowColor(tester, secondRow), stateManager.style.rowHoveredColor);
        expect(stateManager.hoveredRowIdx, 1);

        await mouse.removePointer();
      },
    );
  }

  desktopTestWidgets(
    'hover-transparent resize handles own taps, auto fit, drags and long presses',
    (WidgetTester tester) async {
      int rendererActions = 0;
      for (final PlutoColumn column in columns) {
        column
          ..cellPadding = EdgeInsets.zero
          ..renderer = (_) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => rendererActions += 1,
            onLongPress: () => rendererActions += 1,
            onSecondaryTap: () => rendererActions += 1,
            child: const SizedBox.expand(),
          );
      }
      columns.first.width = 260;
      await buildGrid(tester, enableRowHoverColor: true);
      final PlutoCell originalCell = rows.last.cells[columns.last.field]!;
      stateManager
        ..setCurrentCell(originalCell, rows.length - 1)
        ..setKeepFocus(true);
      await tester.pumpAndSettle();

      final List<PlutoGridCellGestureEvent> cellGestures =
          <PlutoGridCellGestureEvent>[];
      final StreamSubscription<PlutoGridEvent> subscription = stateManager
          .eventManager!
          .listener((PlutoGridEvent event) {
            if (event is PlutoGridCellGestureEvent) {
              cellGestures.add(event);
            }
          });
      final Finder handle = find.byKey(
        const ValueKey<String>('body_resize_handle_column0'),
      );
      final Finder firstRow = find.byKey(
        ValueKey<String>('body_row_${rows.first.key}'),
      );
      Offset boundary() => Offset(
        tester.getCenter(handle).dx,
        tester.getCenter(firstRow).dy,
      );
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(boundary());
      await tester.pumpAndSettle();

      final double widthBeforeAutoFit = columns.first.width;
      await mouse.down(boundary());
      await mouse.up(timeStamp: const Duration(milliseconds: 1));
      await tester.pumpAndSettle();

      expect(stateManager.currentCell, same(originalCell));
      expect(rendererActions, 0);
      expect(cellGestures, isEmpty);

      await mouse.down(
        boundary(),
        timeStamp: const Duration(milliseconds: 100),
      );
      await mouse.up(timeStamp: const Duration(milliseconds: 101));
      await tester.pumpAndSettle();

      expect(columns.first.width, lessThan(widthBeforeAutoFit));
      expect(stateManager.currentCell, same(originalCell));
      expect(stateManager.isEditing, isFalse);
      expect(rendererActions, 0);
      expect(cellGestures, isEmpty);

      final double widthBeforeDrag = columns.first.width;
      await mouse.down(boundary());
      await mouse.moveBy(const Offset(30, 0));
      await mouse.up();
      await tester.pumpAndSettle();

      expect(columns.first.width, closeTo(widthBeforeDrag + 30, 0.01));

      await mouse.down(boundary());
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
      await mouse.up();
      await tester.pumpAndSettle();

      final TestGesture secondaryMouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await secondaryMouse.down(boundary());
      await secondaryMouse.up();
      await tester.pumpAndSettle();

      expect(stateManager.currentCell, same(originalCell));
      expect(stateManager.isEditing, isFalse);
      expect(rendererActions, 0);
      expect(cellGestures, isEmpty);

      final Finder adjacentCell = find.byWidgetPredicate(
        (Widget widget) =>
            widget is PlutoBaseCell &&
            widget.rowIdx == 0 &&
            widget.column == columns[1],
      );
      await mouse.down(tester.getCenter(adjacentCell));
      await mouse.up();
      await tester.pumpAndSettle();

      expect(rendererActions, 1);

      await mouse.removePointer();
      await secondaryMouse.removePointer();
      await tester.runAsync(subscription.cancel);
    },
  );

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

      expect(verticalScroll.offset, 120);
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
