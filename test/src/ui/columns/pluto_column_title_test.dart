import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:pluto_grid_plus/src/ui/ui.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helper/pluto_widget_test_helper.dart';
import '../../../helper/test_helper_util.dart';
import '../../../mock/shared_mocks.mocks.dart';

void main() {
  late MockPlutoGridStateManager stateManager;
  late MockPlutoGridScrollController scroll;
  late MockLinkedScrollControllerGroup horizontalScroll;
  late MockScrollController horizontalScrollController;
  late PublishSubject<PlutoNotifierEvent> subject;
  late PlutoGridEventManager eventManager;
  late PlutoGridConfiguration configuration;

  const ValueKey<String> sortableGestureKey = ValueKey(
    'ColumnTitleSortableGesture',
  );

  setUp(() {
    stateManager = MockPlutoGridStateManager();
    scroll = MockPlutoGridScrollController();
    horizontalScroll = MockLinkedScrollControllerGroup();
    horizontalScrollController = MockScrollController();
    subject = PublishSubject<PlutoNotifierEvent>();
    eventManager = PlutoGridEventManager(stateManager: stateManager);
    configuration = const PlutoGridConfiguration();

    when(stateManager.configuration).thenReturn(configuration);
    when(stateManager.columnMenuDelegate).thenReturn(
      const PlutoColumnMenuDelegateDefault(),
    );
    when(stateManager.style).thenReturn(configuration.style);
    when(stateManager.eventManager).thenReturn(eventManager);
    when(stateManager.streamNotifier).thenAnswer((_) => subject);
    when(stateManager.localeText).thenReturn(const PlutoGridLocaleText());
    when(stateManager.hasCheckedRow).thenReturn(false);
    when(stateManager.hasUnCheckedRow).thenReturn(false);
    when(stateManager.hasFilter).thenReturn(false);
    when(stateManager.columnHeight).thenReturn(45);
    when(stateManager.columnsResizeMode).thenReturn(PlutoResizeMode.normal);
    when(stateManager.isHorizontalOverScrolled).thenReturn(false);
    when(stateManager.correctHorizontalOffset).thenReturn(0);
    when(stateManager.scroll).thenReturn(scroll);
    when(stateManager.maxWidth).thenReturn(1000);
    when(stateManager.textDirection).thenReturn(TextDirection.ltr);
    when(stateManager.isRTL).thenReturn(false);
    when(stateManager.isLTR).thenReturn(true);
    when(stateManager.enoughFrozenColumnsWidth(any)).thenReturn(true);
    when(scroll.maxScrollHorizontal).thenReturn(0);
    when(scroll.horizontal).thenReturn(horizontalScroll);
    when(scroll.bodyRowsHorizontal).thenReturn(horizontalScrollController);
    when(horizontalScrollController.offset).thenReturn(0);
    when(horizontalScroll.offset).thenReturn(0);
    when(stateManager.isFilteredColumn(any)).thenReturn(false);
  });

  tearDown(() {
    unawaited(subject.close());
  });

  MaterialApp buildApp({
    required PlutoColumn column,
    TextDirection textDirection = TextDirection.ltr,
    bool constrainToColumnWidth = false,
  }) {
    final Widget columnTitle = PlutoColumnTitle(
      stateManager: stateManager,
      column: column,
    );

    return MaterialApp(
      home: Directionality(
        textDirection: textDirection,
        child: Material(
          child: constrainToColumnWidth
              ? Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(width: column.width, child: columnTitle),
                )
              : columnTitle,
        ),
      ),
    );
  }

  testWidgets('컬럼 타이틀이 출력 되어야 한다.', (WidgetTester tester) async {
    // given
    final PlutoColumn column = PlutoColumn(
      title: 'column title',
      field: 'column_field_name',
      type: PlutoColumnType.text(),
    );

    // when
    await tester.pumpWidget(
      buildApp(column: column),
    );

    // then
    expect(find.text('column title'), findsOneWidget);
  });

  testWidgets('ColumnIcon 이 출력 되어야 한다.', (WidgetTester tester) async {
    // given
    final PlutoColumn column = PlutoColumn(
      title: 'column title',
      field: 'column_field_name',
      type: PlutoColumnType.text(),
    );

    // when
    await tester.pumpWidget(
      buildApp(column: column),
    );

    // then
    expect(find.byType(PlutoGridColumnIcon), findsOneWidget);
  });

  testWidgets('When enableSorting is true by default, '
      'tapping the title should call toggleSortColumn.', (
    WidgetTester tester,
  ) async {
    // given
    final PlutoColumn column = PlutoColumn(
      title: 'header',
      field: 'header',
      type: PlutoColumnType.text(),
      enableColumnDrag: false,
    );

    // when
    await tester.pumpWidget(
      buildApp(column: column),
    );

    final gestureDetector = tester.widget<GestureDetector>(
      find.byKey(sortableGestureKey),
    );

    gestureDetector.onTap!();

    // then
    verify(stateManager.toggleSortColumn(captureAny)).called(1);
  });

  testWidgets('When enableSorting is false, '
      'GestureDetector widget should not be displayed.', (
    WidgetTester tester,
  ) async {
    // given
    final PlutoColumn column = PlutoColumn(
      title: 'header',
      field: 'header',
      type: PlutoColumnType.text(),
      enableSorting: false,
    );

    // when
    await tester.pumpWidget(
      buildApp(column: column),
    );

    Finder gestureDetector = find.byKey(sortableGestureKey);

    // then
    expect(gestureDetector, findsNothing);

    verifyNever(stateManager.toggleSortColumn(captureAny));
  });

  testWidgets('WHEN Column 이 enableDraggable false'
      'THEN Draggable 이 노출 되지 않아야 한다.', (WidgetTester tester) async {
    // given
    final PlutoColumn column = PlutoColumn(
      title: 'header',
      field: 'header',
      type: PlutoColumnType.text(),
      enableColumnDrag: false,
    );

    // when
    await tester.pumpWidget(
      buildApp(column: column),
    );

    // then
    final draggable = find.byType(Draggable);

    expect(draggable, findsNothing);
  });

  testWidgets('WHEN Column 이 enableDraggable true'
      'THEN Draggable 이 노출 되어야 한다.', (WidgetTester tester) async {
    // given
    final PlutoColumn column = PlutoColumn(
      title: 'header',
      field: 'header',
      type: PlutoColumnType.text(),
      enableColumnDrag: true,
    );

    // when
    await tester.pumpWidget(
      buildApp(column: column),
    );

    // then
    final draggable = find.byType(
      TestHelperUtil.typeOf<Draggable<PlutoColumn>>(),
    );

    expect(draggable, findsOneWidget);
  });

  testWidgets(
    'enableContextMenu 이 false, enableDropToResize 가 false 면 '
    'ColumnIcon 이 출력 되지 않아야 한다.',
    (WidgetTester tester) async {
      // given
      final PlutoColumn column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
        enableContextMenu: false,
        enableDropToResize: false,
      );

      // when
      await tester.pumpWidget(
        buildApp(column: column),
      );

      // then
      expect(find.byType(PlutoGridColumnIcon), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>(
            'column_resize_handle_column_field_name',
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'showColumnHeaderIcon 이 false 면 action icon 없이 resize handle만 '
    '출력되어야 한다.',
    (WidgetTester tester) async {
      configuration = const PlutoGridConfiguration(
        style: PlutoGridStyleConfig(showColumnHeaderIcon: false),
      );
      when(stateManager.configuration).thenReturn(configuration);
      when(stateManager.style).thenReturn(configuration.style);

      final PlutoColumn column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
      );

      await tester.pumpWidget(buildApp(column: column));

      expect(find.byType(PlutoGridColumnIcon), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>(
            'column_resize_handle_column_field_name',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'column_header_action_spacer_column_field_name',
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'hidden header controls reserve no layout width in LTR and RTL.',
    (WidgetTester tester) async {
      const double columnWidth = 200;
      const String title =
          'AHeaderTitleThatIsLongEnoughToFillTheAvailableTextRegion';

      Future<double> pumpHeader({
        required TextDirection textDirection,
        required bool showHeaderAction,
        required bool showFilterAction,
        required int caseIndex,
      }) async {
        configuration = PlutoGridConfiguration(
          style: PlutoGridStyleConfig(
            defaultColumnTitlePadding: EdgeInsets.zero,
            showColumnHeaderIcon: showHeaderAction,
            showColumnFilterIcon: showFilterAction,
          ),
        );
        when(stateManager.configuration).thenReturn(configuration);
        when(stateManager.style).thenReturn(configuration.style);
        when(stateManager.textDirection).thenReturn(textDirection);
        when(stateManager.isRTL).thenReturn(
          textDirection == TextDirection.rtl,
        );
        when(stateManager.isLTR).thenReturn(
          textDirection == TextDirection.ltr,
        );

        final String field = 'header_layout_${textDirection.name}_$caseIndex';
        final PlutoColumn column = PlutoColumn(
          title: title,
          field: field,
          type: PlutoColumnType.text(),
          width: columnWidth,
          onFilterIconTap: (_) {},
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          buildApp(
            column: column,
            textDirection: textDirection,
            constrainToColumnWidth: true,
          ),
        );

        final Finder headerText = find.byKey(
          ValueKey<String>('column_header_text_$field'),
        );

        expect(headerText, findsOneWidget);
        expect(
          find.byKey(ValueKey<String>('column_filter_icon_$field')),
          showFilterAction ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(ValueKey<String>('column_header_action_spacer_$field')),
          showHeaderAction ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(ValueKey<String>('column_header_action_$field')),
          showHeaderAction ? findsOneWidget : findsNothing,
        );

        final Rect columnRect = tester.getRect(find.byType(PlutoColumnTitle));
        final Rect textRect = tester.getRect(headerText);
        final Finder filterAction = find.byKey(
          ValueKey<String>('column_filter_icon_$field'),
        );
        final Finder actionSpacer = find.byKey(
          ValueKey<String>('column_header_action_spacer_$field'),
        );
        final Finder headerAction = find.byKey(
          ValueKey<String>('column_header_action_$field'),
        );

        if (showHeaderAction) {
          expect(
            tester.getSize(headerAction).width,
            configuration.style.iconSize,
          );
        }

        if (textDirection == TextDirection.ltr) {
          double nextX = textRect.right;

          if (showFilterAction) {
            final Rect filterRect = tester.getRect(filterAction);
            expect(filterRect.left, closeTo(nextX, 0.01));
            nextX = filterRect.right;
          }

          if (showHeaderAction) {
            final Rect spacerRect = tester.getRect(actionSpacer);
            final Rect actionRect = tester.getRect(headerAction);
            expect(spacerRect.left, closeTo(nextX, 0.01));
            expect(actionRect.left, closeTo(spacerRect.left, 0.01));
            expect(
              actionRect.right,
              closeTo(
                spacerRect.right -
                    PlutoGridSettings.columnResizeHandleWidth / 2,
                0.01,
              ),
            );
            nextX = spacerRect.right;
          }

          expect(nextX, closeTo(columnRect.right, 0.01));
        } else {
          double nextX = textRect.left;

          if (showFilterAction) {
            final Rect filterRect = tester.getRect(filterAction);
            expect(filterRect.right, closeTo(nextX, 0.01));
            nextX = filterRect.left;
          }

          if (showHeaderAction) {
            final Rect spacerRect = tester.getRect(actionSpacer);
            final Rect actionRect = tester.getRect(headerAction);
            expect(spacerRect.right, closeTo(nextX, 0.01));
            expect(
              actionRect.left,
              closeTo(
                spacerRect.left + PlutoGridSettings.columnResizeHandleWidth / 2,
                0.01,
              ),
            );
            expect(actionRect.right, closeTo(spacerRect.right, 0.01));
            nextX = spacerRect.left;
          }

          expect(nextX, closeTo(columnRect.left, 0.01));
        }

        return tester.getSize(headerText).width;
      }

      final double actionSpacing =
          configuration.style.iconSize +
          PlutoGridSettings.columnResizeHandleWidth / 2;

      for (final TextDirection textDirection in TextDirection.values) {
        final double hiddenWidth = await pumpHeader(
          textDirection: textDirection,
          showHeaderAction: false,
          showFilterAction: false,
          caseIndex: 0,
        );
        final double headerActionWidth = await pumpHeader(
          textDirection: textDirection,
          showHeaderAction: true,
          showFilterAction: false,
          caseIndex: 1,
        );
        final double filterActionWidth = await pumpHeader(
          textDirection: textDirection,
          showHeaderAction: false,
          showFilterAction: true,
          caseIndex: 2,
        );
        final double bothActionsWidth = await pumpHeader(
          textDirection: textDirection,
          showHeaderAction: true,
          showFilterAction: true,
          caseIndex: 3,
        );

        expect(hiddenWidth, columnWidth);
        expect(
          headerActionWidth,
          columnWidth - actionSpacing,
        );
        expect(
          filterActionWidth,
          columnWidth - configuration.style.iconSize,
        );
        expect(
          bothActionsWidth,
          columnWidth - actionSpacing - configuration.style.iconSize,
        );
      }
    },
  );

  testWidgets(
    'column.showColumnHeaderIcon 이 global style 값을 재정의해야 한다.',
    (WidgetTester tester) async {
      configuration = const PlutoGridConfiguration(
        style: PlutoGridStyleConfig(showColumnHeaderIcon: false),
      );
      when(stateManager.configuration).thenReturn(configuration);
      when(stateManager.style).thenReturn(configuration.style);

      final PlutoColumn column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
        showColumnHeaderIcon: true,
      );

      await tester.pumpWidget(buildApp(column: column));

      expect(find.byType(PlutoGridColumnIcon), findsOneWidget);
    },
  );

  testWidgets(
    'active filter icon visibility can be configured globally and per column.',
    (WidgetTester tester) async {
      configuration = const PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          showColumnHeaderIcon: false,
          showColumnFilterIcon: false,
          columnFilterIcon: Icons.tune,
        ),
      );
      when(stateManager.configuration).thenReturn(configuration);
      when(stateManager.style).thenReturn(configuration.style);

      final PlutoColumn column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
      );
      when(stateManager.isFilteredColumn(column)).thenReturn(true);

      await tester.pumpWidget(buildApp(column: column));

      final Finder filterIcon = find.byKey(
        const ValueKey<String>(
          'column_filter_icon_column_field_name',
        ),
      );
      expect(filterIcon, findsNothing);

      column.showColumnFilterIcon = true;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(buildApp(column: column));

      expect(filterIcon, findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
    },
  );

  testWidgets(
    'filter icon remains tappable beside the header action and supports a '
    'custom overlay.',
    (WidgetTester tester) async {
      configuration = const PlutoGridConfiguration();
      when(stateManager.configuration).thenReturn(configuration);
      when(stateManager.style).thenReturn(configuration.style);

      OverlayEntry? overlayEntry;
      bool actionCalled = false;
      Size? actionContextSize;
      final PlutoColumn column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
        filterIconRenderer: (PlutoColumnFilterIconContext context) =>
            const Icon(Icons.star, key: ValueKey<String>('custom_filter_icon')),
        onFilterIconTap: (PlutoColumnFilterIconContext context) {
          actionCalled = true;
          actionContextSize =
              (context.buildContext.findRenderObject()! as RenderBox).size;
          overlayEntry = OverlayEntry(
            builder: (BuildContext context) => const Positioned(
              top: 10,
              left: 10,
              child: Material(child: Text('custom filter overlay')),
            ),
          );
          Overlay.of(context.buildContext).insert(overlayEntry!);
        },
      );

      await tester.pumpWidget(buildApp(column: column));

      expect(
        find.byKey(const ValueKey<String>('custom_filter_icon')),
        findsOneWidget,
      );
      expect(find.byType(PlutoGridColumnIcon), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt_outlined), findsNothing);

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'column_filter_icon_column_field_name',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      verifyNever(stateManager.toggleSortColumn(any));
      expect(actionCalled, isTrue);
      expect(actionContextSize, const Size(18, 18));
      expect(find.text('custom filter overlay'), findsOneWidget);

      overlayEntry?.remove();
      await tester.pump();
    },
  );

  testWidgets(
    'filter icon uses PlutoGrid custom filter popup by default.',
    (WidgetTester tester) async {
      configuration = const PlutoGridConfiguration(
        style: PlutoGridStyleConfig(showColumnHeaderIcon: false),
      );
      when(stateManager.configuration).thenReturn(configuration);
      when(stateManager.style).thenReturn(configuration.style);

      PlutoColumn? popupColumn;
      when(stateManager.showFilterPopupCustom).thenReturn(
        (
          BuildContext context, {
          PlutoColumn? calledColumn,
          VoidCallback? onClosed,
        }) {
          popupColumn = calledColumn;
        },
      );
      final PlutoColumn column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
      );

      await tester.pumpWidget(buildApp(column: column));

      final Finder filterIcon = find.byKey(
        const ValueKey<String>(
          'column_filter_icon_column_field_name',
        ),
      );
      expect(filterIcon, findsOneWidget);

      await tester.tap(filterIcon);
      await tester.pump(const Duration(milliseconds: 50));

      expect(popupColumn, same(column));
      verifyNever(stateManager.toggleSortColumn(any));
    },
  );

  testWidgets(
    'enableContextMenu 이 true, enableDropToResize 가 true 면 '
    'ColumnIcon 이 출력 되어야 한다.',
    (WidgetTester tester) async {
      // given
      final PlutoColumn column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
        enableContextMenu: true,
        enableDropToResize: true,
      );

      // when
      await tester.pumpWidget(
        buildApp(column: column),
      );

      final found = find.byType(PlutoGridColumnIcon);

      final foundWidget = found.evaluate().first.widget as PlutoGridColumnIcon;

      // then
      expect(found, findsOneWidget);
      expect(foundWidget.icon, configuration.style.columnContextIcon);
    },
  );

  testWidgets(
    'enableContextMenu 이 true, enableDropToResize 가 false 면 '
    'ColumnIcon 이 출력 되어야 한다.',
    (WidgetTester tester) async {
      // given
      final PlutoColumn column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
        enableContextMenu: true,
        enableDropToResize: false,
      );

      // when
      await tester.pumpWidget(
        buildApp(column: column),
      );

      // then
      final found = find.byType(PlutoGridColumnIcon);

      final foundWidget = found.evaluate().first.widget as PlutoGridColumnIcon;

      // then
      expect(found, findsOneWidget);
      expect(foundWidget.icon, configuration.style.columnContextIcon);
    },
  );

  testWidgets(
    'enableContextMenu 이 false, enableDropToResize 가 true 면 '
    'ColumnIcon 이 출력 되어야 한다.',
    (WidgetTester tester) async {
      // given
      final PlutoColumn column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
        enableContextMenu: false,
        enableDropToResize: true,
      );

      // when
      await tester.pumpWidget(
        buildApp(column: column),
      );

      // then
      final found = find.byType(PlutoGridColumnIcon);

      final foundWidget = found.evaluate().first.widget as PlutoGridColumnIcon;

      // then
      expect(found, findsOneWidget);
      expect(foundWidget.icon, configuration.style.columnResizeIcon);
    },
  );

  group('enableRowChecked', () {
    buildColumn(bool enable) {
      final column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
        enableRowChecked: enable,
      );

      return PlutoWidgetTestHelper('build column.', (tester) async {
        await tester.pumpWidget(
          buildApp(column: column),
        );
      });
    }

    final columnHasNotCheckbox = buildColumn(false);

    columnHasNotCheckbox.test(
      'checkbox 위젯이 이 출력 되지 않아야 한다.',
      (tester) async {
        expect(find.byType(Checkbox), findsNothing);
      },
    );

    final columnHasCheckbox = buildColumn(true);

    columnHasCheckbox.test(
      'checkbox 위젯이 이 출력 되어야 한다.',
      (tester) async {
        expect(find.byType(Checkbox), findsOneWidget);
      },
    );

    columnHasCheckbox.test(
      'After tapping the checkbox, the toggleAllRowChecked function should be called.',
      (tester) async {
        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        checkbox.onChanged!(true);

        verify(stateManager.toggleAllRowChecked(true)).called(1);
      },
    );
  });

  group('고정 컬럼이 아닌 경우', () {
    final PlutoColumn column = PlutoColumn(
      title: 'column title',
      field: 'column_field_name',
      type: PlutoColumnType.text(),
    );

    final tapColumn = PlutoWidgetTestHelper('Tap column.', (tester) async {
      when(
        stateManager.refColumns,
      ).thenReturn(FilteredList(initialList: [column]));

      await tester.pumpWidget(
        buildApp(column: column),
      );

      final columnIcon = find.byType(PlutoGridColumnIcon);

      final gesture = await tester.startGesture(tester.getCenter(columnIcon));

      await gesture.up();
    });

    tapColumn.test('기본 메뉴가 출력 되어야 한다.', (tester) async {
      expect(find.text('Freeze to start'), findsOneWidget);
      expect(find.text('Freeze to end'), findsOneWidget);
      expect(find.text('Auto fit'), findsOneWidget);
    });

    tapColumn.test('Freeze to start 를 탭하면 toggleFrozenColumn 이 호출 되어야 한다.', (
      tester,
    ) async {
      await tester.tap(find.text('Freeze to start'));

      verify(
        stateManager.toggleFrozenColumn(
          column,
          PlutoColumnFrozen.start,
        ),
      ).called(1);
    });

    tapColumn.test('Freeze to end 를 탭하면 toggleFrozenColumn 이 호출 되어야 한다.', (
      tester,
    ) async {
      await tester.tap(find.text('Freeze to end'));

      verify(
        stateManager.toggleFrozenColumn(
          column,
          PlutoColumnFrozen.end,
        ),
      ).called(1);
    });

    tapColumn.test('Auto fit 를 탭하면 autoFitColumn 이 호출 되어야 한다.', (tester) async {
      when(stateManager.rows).thenReturn([
        PlutoRow(
          cells: {
            'column_field_name': PlutoCell(value: 'cell value'),
          },
        ),
      ]);

      await tester.tap(find.text('Auto fit'));

      verify(
        stateManager.autoFitColumn(
          argThat(isA<BuildContext>()),
          column,
        ),
      ).called(1);
    });
  });

  group('왼쪽 고정 컬럼인 경우', () {
    final PlutoColumn column = PlutoColumn(
      title: 'column title',
      field: 'column_field_name',
      type: PlutoColumnType.text(),
      frozen: PlutoColumnFrozen.start,
    );

    final tapColumn = PlutoWidgetTestHelper('Tap column.', (tester) async {
      when(
        stateManager.refColumns,
      ).thenReturn(FilteredList(initialList: [column]));

      await tester.pumpWidget(
        buildApp(column: column),
      );

      final columnIcon = find.byType(PlutoGridColumnIcon);

      final gesture = await tester.startGesture(tester.getCenter(columnIcon));

      await gesture.up();
    });

    tapColumn.test('고정 컬럼의 기본 메뉴가 출력 되어야 한다.', (tester) async {
      expect(find.text('Unfreeze'), findsOneWidget);
      expect(find.text('Freeze to start'), findsNothing);
      expect(find.text('Freeze to end'), findsNothing);
      expect(find.text('Auto fit'), findsOneWidget);
    });

    tapColumn.test('Unfreeze 를 탭하면 toggleFrozenColumn 이 호출 되어야 한다.', (
      tester,
    ) async {
      await tester.tap(find.text('Unfreeze'));

      verify(
        stateManager.toggleFrozenColumn(
          column,
          PlutoColumnFrozen.none,
        ),
      ).called(1);
    });

    tapColumn.test('Auto fit 를 탭하면 autoFitColumn 이 호출 되어야 한다.', (tester) async {
      when(stateManager.rows).thenReturn([]);

      await tester.tap(find.text('Auto fit'));

      verify(
        stateManager.autoFitColumn(
          argThat(isA<BuildContext>()),
          column,
        ),
      ).called(1);
    });
  });

  group('우측 고정 컬럼인 경우', () {
    final PlutoColumn column = PlutoColumn(
      title: 'column title',
      field: 'column_field_name',
      type: PlutoColumnType.text(),
      frozen: PlutoColumnFrozen.end,
    );

    final tapColumn = PlutoWidgetTestHelper('Tap column.', (tester) async {
      when(
        stateManager.refColumns,
      ).thenReturn(FilteredList(initialList: [column]));

      await tester.pumpWidget(
        buildApp(column: column),
      );

      final columnIcon = find.byType(PlutoGridColumnIcon);

      final gesture = await tester.startGesture(tester.getCenter(columnIcon));

      await gesture.up();
    });

    tapColumn.test('고정 컬럼의 기본 메뉴가 출력 되어야 한다.', (tester) async {
      expect(find.text('Unfreeze'), findsOneWidget);
      expect(find.text('Freeze to start'), findsNothing);
      expect(find.text('Freeze to end'), findsNothing);
      expect(find.text('Auto fit'), findsOneWidget);
    });

    tapColumn.test('Unfreeze 를 탭하면 toggleFrozenColumn 이 호출 되어야 한다.', (
      tester,
    ) async {
      await tester.tap(find.text('Unfreeze'));

      verify(
        stateManager.toggleFrozenColumn(
          column,
          PlutoColumnFrozen.none,
        ),
      ).called(1);
    });

    tapColumn.test('Auto fit 를 탭하면 autoFitColumn 이 호출 되어야 한다.', (tester) async {
      when(stateManager.rows).thenReturn([]);

      await tester.tap(find.text('Auto fit'));

      verify(
        stateManager.autoFitColumn(
          argThat(isA<BuildContext>()),
          column,
        ),
      ).called(1);
    });
  });

  group('Drag a column', () {
    final PlutoColumn column = PlutoColumn(
      title: 'column title',
      field: 'column_field_name',
      type: PlutoColumnType.text(),
      frozen: PlutoColumnFrozen.end,
    );

    final aColumn = PlutoWidgetTestHelper('a column.', (tester) async {
      await tester.pumpWidget(
        buildApp(column: column),
      );
    });

    aColumn.test(
      'When dragging and dropping to the same column, moveColumn should not be called.',
      (tester) async {
        await tester.drag(
          find.byType(TestHelperUtil.typeOf<Draggable<PlutoColumn>>()),
          const Offset(50.0, 0.0),
        );

        verifyNever(
          stateManager.moveColumn(
            column: column,
            targetColumn: column,
          ),
        );
      },
    );
  });

  group('Drag a button', () {
    final PlutoColumn column = PlutoColumn(
      title: 'column title',
      field: 'column_field_name',
      type: PlutoColumnType.text(),
    );

    dragAColumn(Offset offset) {
      return PlutoWidgetTestHelper('a column.', (tester) async {
        await tester.pumpWidget(
          buildApp(column: column),
        );

        final columnIcon = find.byType(PlutoGridColumnIcon);

        await tester.drag(columnIcon, offset);
      });
    }

    /**
     * (기본 값이 4, Positioned 위젯 right -3)
     */
    dragAColumn(
      const Offset(50.0, 0.0),
    ).test(
      'resizeColumn 이 30 이상으로 호출 되어야 한다.',
      (tester) async {
        verify(
          stateManager.resizeColumn(
            column,
            argThat(greaterThanOrEqualTo(30)),
          ),
        );
      },
    );

    dragAColumn(
      const Offset(-50.0, 0.0),
    ).test(
      'resizeColumn 이 -30 이하로 호출 되어야 한다.',
      (tester) async {
        verify(
          stateManager.resizeColumn(
            column,
            argThat(lessThanOrEqualTo(-30)),
          ),
        );
      },
    );
  });

  testWidgets(
    'column boundary resize handle 로 resizeColumn 이 호출되어야 한다.',
    (WidgetTester tester) async {
      configuration = const PlutoGridConfiguration(
        style: PlutoGridStyleConfig(showColumnHeaderIcon: false),
      );
      when(stateManager.configuration).thenReturn(configuration);
      when(stateManager.style).thenReturn(configuration.style);

      final PlutoColumn column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
      );

      await tester.pumpWidget(buildApp(column: column));

      final Finder resizeHandle = find.byKey(
        const ValueKey<String>(
          'column_resize_handle_column_field_name',
        ),
      );

      await tester.drag(resizeHandle, const Offset(50, 0));

      verify(
        stateManager.resizeColumn(
          column,
          argThat(greaterThanOrEqualTo(30)),
        ),
      );
    },
  );

  testWidgets(
    'double tapping the column boundary should auto fit the column',
    (WidgetTester tester) async {
      configuration = const PlutoGridConfiguration(
        style: PlutoGridStyleConfig(showColumnHeaderIcon: false),
      );
      when(stateManager.configuration).thenReturn(configuration);
      when(stateManager.style).thenReturn(configuration.style);

      final PlutoColumn column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
      );

      await tester.pumpWidget(buildApp(column: column));

      final Finder resizeHandle = find.byKey(
        const ValueKey<String>(
          'column_resize_handle_column_field_name',
        ),
      );
      final Offset handleCenter = tester.getCenter(resizeHandle);
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );

      await mouse.addPointer(location: handleCenter);
      await mouse.down(handleCenter);
      await mouse.moveBy(
        const Offset(1, 0),
        timeStamp: const Duration(milliseconds: 1),
      );
      await mouse.up(timeStamp: const Duration(milliseconds: 2));
      await mouse.down(
        handleCenter + const Offset(1, 0),
        timeStamp: const Duration(milliseconds: 100),
      );
      await mouse.moveBy(
        const Offset(-1, 0),
        timeStamp: const Duration(milliseconds: 101),
      );
      await mouse.up(timeStamp: const Duration(milliseconds: 102));
      await tester.pumpAndSettle();

      verify(stateManager.autoFitColumn(any, column)).called(1);
      verify(stateManager.updateCorrectScrollOffset()).called(1);
      verifyNever(stateManager.resizeColumn(any, any));

      await mouse.removePointer();
    },
  );

  testWidgets(
    'column boundary hover 시 resize indicator 가 표시되어야 한다.',
    (WidgetTester tester) async {
      configuration = const PlutoGridConfiguration(
        style: PlutoGridStyleConfig(showColumnHeaderIcon: false),
      );
      when(stateManager.configuration).thenReturn(configuration);
      when(stateManager.style).thenReturn(configuration.style);

      final PlutoColumn column = PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
      );

      await tester.pumpWidget(buildApp(column: column));

      final Finder resizeHandle = find.byKey(
        const ValueKey<String>(
          'column_resize_handle_column_field_name',
        ),
      );
      final Finder indicator = find.byKey(
        const ValueKey<String>('ColumnResizeHandleIndicator'),
      );

      expect(tester.getSize(indicator).width, 0);

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(resizeHandle));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(indicator).width,
        PlutoGridSettings.columnResizeHandleActiveWidth,
      );

      await mouse.removePointer();
    },
  );

  group('configuration', () {
    aColumnWithConfiguration(
      PlutoGridConfiguration configuration, {
      PlutoColumn? column,
    }) {
      return PlutoWidgetTestHelper('a column.', (tester) async {
        when(stateManager.configuration).thenReturn(configuration);
        when(stateManager.style).thenReturn(configuration.style);

        await tester.pumpWidget(
          buildApp(
            column:
                column ??
                PlutoColumn(
                  title: 'column title',
                  field: 'column_field_name',
                  type: PlutoColumnType.text(),
                  frozen: PlutoColumnFrozen.end,
                ),
          ),
        );
      });
    }

    aColumnWithConfiguration(
      const PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          enableColumnBorderVertical: true,
          borderColor: Colors.deepOrange,
          columnBorderWidth: 0.5,
        ),
      ),
    ).test(
      'if enableColumnBorder is true, should be set the border.',
      (tester) async {
        expect(
          stateManager.configuration.style.enableColumnBorderVertical,
          true,
        );

        final target = find.descendant(
          of: find.byKey(sortableGestureKey),
          matching: find.byType(DecoratedBox),
        );

        final container = target.evaluate().single.widget as DecoratedBox;

        final BoxDecoration decoration = container.decoration as BoxDecoration;

        final BorderDirectional border = decoration.border as BorderDirectional;

        expect(border.end.width, 0.5);
        expect(border.end.color, Colors.deepOrange);
      },
    );

    aColumnWithConfiguration(
      const PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          enableColumnBorderVertical: false,
          borderColor: Colors.deepOrange,
        ),
      ),
    ).test(
      'if enableColumnBorder is false, should not be set the border.',
      (tester) async {
        expect(
          stateManager.configuration.style.enableColumnBorderVertical,
          false,
        );

        final target = find.descendant(
          of: find.byKey(sortableGestureKey),
          matching: find.byType(DecoratedBox),
        );

        final container = target.evaluate().single.widget as DecoratedBox;

        final BoxDecoration decoration = container.decoration as BoxDecoration;

        final BorderDirectional border = decoration.border as BorderDirectional;

        expect(border.end, BorderSide.none);
      },
    );

    aColumnWithConfiguration(
      const PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          columnAscendingIcon: Icon(
            Icons.arrow_upward,
            color: Colors.cyan,
          ),
        ),
      ),
      column: PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
        sort: PlutoColumnSort.ascending,
      ),
    ).test(
      'If columnAscendingIcon is set, the set icon should appear.',
      (tester) async {
        final target = find.descendant(
          of: find.byType(PlutoColumnTitle),
          matching: find.byType(Icon),
        );

        final icon = target.evaluate().first.widget as Icon;

        expect(icon.icon, Icons.arrow_upward);
        expect(icon.color, Colors.cyan);
      },
    );

    aColumnWithConfiguration(
      const PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          columnDescendingIcon: Icon(
            Icons.arrow_downward,
            color: Colors.pink,
          ),
        ),
      ),
      column: PlutoColumn(
        title: 'column title',
        field: 'column_field_name',
        type: PlutoColumnType.text(),
        sort: PlutoColumnSort.descending,
      ),
    ).test(
      'If columnDescendingIcon is set, the set icon should appear.',
      (tester) async {
        final target = find.descendant(
          of: find.byType(PlutoColumnTitle),
          matching: find.byType(Icon),
        );

        final icon = target.evaluate().first.widget as Icon;

        expect(icon.icon, Icons.arrow_downward);
        expect(icon.color, Colors.pink);
      },
    );
  });
}
