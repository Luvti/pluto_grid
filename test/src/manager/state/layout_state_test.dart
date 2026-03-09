import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import '../../../helper/column_helper.dart';
import '../../../helper/pluto_widget_test_helper.dart';
import '../../../helper/row_helper.dart';
import '../../../mock/shared_mocks.mocks.dart';

void main() {
  group('속성 값 테스트.', () {
    late PlutoGridStateManager stateManager;

    PlutoGridEventManager eventManager;

    List<PlutoColumn> columns;

    List<PlutoRow> rows;

    makeFrozenColumnByMaxWidth(String description, double maxWidth) {
      return PlutoWidgetTestHelper(
        '고정 컬럼이 있고 $description',
        (tester) async {
          columns = [
            ...ColumnHelper.textColumn(
              'left',
              count: 1,
              frozen: PlutoColumnFrozen.start,
              width: 150,
            ),
            ...ColumnHelper.textColumn(
              'body',
              count: 3,
              width: 150,
            ),
            ...ColumnHelper.textColumn(
              'right',
              count: 1,
              frozen: PlutoColumnFrozen.end,
              width: 150,
            ),
          ];

          rows = RowHelper.count(10, columns);

          eventManager = MockPlutoGridEventManager();

          stateManager = PlutoGridStateManager(
            columns: columns,
            rows: rows,
            gridFocusNode: MockFocusNode(),
            scroll: MockPlutoGridScrollController(),
          );

          stateManager.setEventManager(eventManager);
          stateManager.setLayout(
            BoxConstraints(maxWidth: maxWidth, maxHeight: 500),
          );
          stateManager.setGridGlobalOffset(Offset.zero);
        },
      );
    }

    final hasFrozenColumnAndWidthEnough = makeFrozenColumnByMaxWidth(
      '넓이가 충분한 경우',
      600,
    );

    hasFrozenColumnAndWidthEnough.test(
      'bodyLeftOffset 값은 왼쪽 고정 컬럼 넓이 + 1 이어야 한다.',
      (tester) async {
        expect(
          stateManager.bodyLeftOffset,
          stateManager.leftFrozenColumnsWidth + 1,
        );
      },
    );

    hasFrozenColumnAndWidthEnough.test(
      'bodyRightOffset 값은 우측 고정 컬럼 넓이 + 1 이어야 한다.',
      (tester) async {
        expect(
          stateManager.bodyRightOffset,
          stateManager.rightFrozenColumnsWidth + 1,
        );
      },
    );

    hasFrozenColumnAndWidthEnough.test(
      'bodyLeftScrollOffset 값이 일치해야 한다.',
      (tester) async {
        expect(
          stateManager.bodyLeftScrollOffset,
          stateManager.gridGlobalOffset!.dx +
              stateManager.configuration.style.gridPadding +
              stateManager.configuration.style.gridBorderWidth +
              PlutoGridSettings.offsetScrollingFromEdge,
        );
      },
    );

    hasFrozenColumnAndWidthEnough.test(
      'bodyRightScrollOffset 값이 일치해야 한다.',
      (tester) async {
        expect(
          stateManager.bodyRightScrollOffset,
          (stateManager.gridGlobalOffset!.dx + stateManager.maxWidth!) -
              PlutoGridSettings.offsetScrollingFromEdge,
        );
      },
    );

    final hasFrozenColumnAndWidthNotEnough = makeFrozenColumnByMaxWidth(
      '넓이가 부족한 경우',
      450,
    );

    hasFrozenColumnAndWidthNotEnough.test(
      'bodyLeftOffset 값은 0 이어야 한다.',
      (tester) async {
        expect(
          stateManager.bodyLeftOffset,
          0,
        );
      },
    );

    hasFrozenColumnAndWidthNotEnough.test(
      'bodyRightOffset 값은 0 이어야 한다.',
      (tester) async {
        expect(
          stateManager.bodyRightOffset,
          0,
        );
      },
    );

    hasFrozenColumnAndWidthNotEnough.test(
      'bodyLeftScrollOffset 값이 일치해야 한다.',
      (tester) async {
        expect(
          stateManager.bodyLeftScrollOffset,
          stateManager.gridGlobalOffset!.dx +
              stateManager.configuration.style.gridPadding +
              stateManager.configuration.style.gridBorderWidth +
              PlutoGridSettings.offsetScrollingFromEdge,
        );
      },
    );

    hasFrozenColumnAndWidthNotEnough.test(
      'bodyRightScrollOffset 값이 일치해야 한다.',
      (tester) async {
        expect(
          stateManager.bodyRightScrollOffset,
          (stateManager.gridGlobalOffset!.dx + stateManager.maxWidth!) -
              PlutoGridSettings.offsetScrollingFromEdge,
        );
      },
    );
  });

  group('레이아웃 전 maxWidth 가 null 인 상태', () {
    late PlutoGridStateManager stateManager;
    late MockPlutoGridScrollController scroll;
    late MockLinkedScrollControllerGroup horizontal;

    setUp(() {
      final columns = [
        ...ColumnHelper.textColumn(
          'left',
          count: 1,
          frozen: PlutoColumnFrozen.start,
          width: 150,
        ),
        ...ColumnHelper.textColumn(
          'body',
          count: 2,
          width: 150,
        ),
        ...ColumnHelper.textColumn(
          'right',
          count: 1,
          frozen: PlutoColumnFrozen.end,
          width: 150,
        ),
      ];

      scroll = MockPlutoGridScrollController();
      horizontal = MockLinkedScrollControllerGroup();

      when(scroll.horizontal).thenReturn(horizontal);
      when(horizontal.offset).thenReturn(0);

      stateManager = PlutoGridStateManager(
        columns: columns,
        rows: RowHelper.count(1, columns),
        gridFocusNode: MockFocusNode(),
        scroll: scroll,
      );

      stateManager.setEventManager(MockPlutoGridEventManager());
    });

    testWidgets('고정 컬럼 offset 계산이 안전한 기본값을 리턴해야 한다.', (
      WidgetTester tester,
    ) async {
      expect(stateManager.maxWidth, isNull);
      expect(stateManager.maxHeight, isNull);
      expect(stateManager.columnRowContainerHeight, 0);
      expect(stateManager.rowContainerHeight, 0);
      expect(stateManager.headerBottomOffset, 0);
      expect(stateManager.footerTopOffset, 0);
      expect(stateManager.columnBottomOffset, 0);
      expect(
        stateManager.bodyTopOffset,
        stateManager.gridPadding +
            stateManager.headerHeight +
            stateManager.gridBorderWidth +
            stateManager.columnGroupHeight +
            stateManager.columnHeight +
            stateManager.columnFilterHeight,
      );
      expect(
        stateManager.bodyLeftScrollOffset,
        stateManager.gridPadding +
            stateManager.gridBorderWidth +
            PlutoGridSettings.offsetScrollingFromEdge,
      );
      expect(stateManager.bodyRightScrollOffset, double.infinity);
      expect(stateManager.bodyDownScrollOffset, double.infinity);
      expect(
        stateManager.leftFrozenRightOffset,
        stateManager.leftFrozenColumnsWidth,
      );
      expect(
        stateManager.rightFrozenLeftOffset,
        stateManager.leftFrozenColumnsWidth + stateManager.bodyColumnsWidth,
      );
      expect(stateManager.rightBlankOffset, 0);

      stateManager.resetShowFrozenColumn();

      expect(stateManager.showFrozenColumn, false);
    });
  });
}
