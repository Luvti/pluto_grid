import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import '../../../helper/column_helper.dart';
import '../../../helper/row_helper.dart';
import '../../../mock/shared_mocks.mocks.dart';

void main() {
  PlutoGridStateManager createStateManager({
    required List<PlutoColumn> columns,
    required List<PlutoRow> rows,
    FocusNode? gridFocusNode,
    PlutoGridScrollController? scroll,
    BoxConstraints? layout,
    PlutoGridConfiguration configuration = const PlutoGridConfiguration(),
  }) {
    final stateManager = PlutoGridStateManager(
      columns: columns,
      rows: rows,
      gridFocusNode: gridFocusNode ?? MockFocusNode(),
      scroll: scroll ?? MockPlutoGridScrollController(),
      configuration: configuration,
    );

    stateManager.setEventManager(MockPlutoGridEventManager());

    if (layout != null) {
      stateManager.setLayout(layout);
    }

    return stateManager;
  }

  testWidgets('레이아웃 전 RTL 상태면 directional offset 이 안전한 기본값이어야 한다.', (
    WidgetTester tester,
  ) async {
    final columns = ColumnHelper.textColumn('body', count: 1, width: 150);
    final rows = RowHelper.count(1, columns);

    final stateManager = createStateManager(
      columns: columns,
      rows: rows,
      gridFocusNode: null,
      scroll: null,
    );

    stateManager.setTextDirection(TextDirection.rtl);

    expect(stateManager.maxWidth, isNull);
    expect(stateManager.gridGlobalOffset, isNull);
    expect(stateManager.directionalScrollEdgeOffset, Offset.zero);
    expect(
      stateManager.toDirectionalOffset(const Offset(10, 20)),
      const Offset(10, 20),
    );
  });

  testWidgets('레이아웃 전 moveScrollByRow 는 no-op 이어야 한다.', (
    WidgetTester tester,
  ) async {
    final columns = ColumnHelper.textColumn('body', count: 1, width: 150);
    final rows = RowHelper.count(3, columns);
    final scroll = MockPlutoGridScrollController();
    final vertical = MockLinkedScrollControllerGroup();

    when(scroll.vertical).thenReturn(vertical);
    when(scroll.verticalOffset).thenReturn(0);

    final stateManager = createStateManager(
      columns: columns,
      rows: rows,
      gridFocusNode: null,
      scroll: scroll,
    );

    stateManager.moveScrollByRow(PlutoMoveDirection.down, 0);

    verifyNever(vertical.jumpTo(any));
  });

  group('고정 컬럼이 있는 상태에서 needMovingScroll', () {
    late PlutoGridStateManager stateManager;

    List<PlutoColumn> columns;

    List<PlutoRow> rows;

    setUp(() {
      columns = [
        ...ColumnHelper.textColumn(
          'left',
          count: 3,
          frozen: PlutoColumnFrozen.start,
        ),
        ...ColumnHelper.textColumn('body', count: 3, width: 150),
        ...ColumnHelper.textColumn(
          'right',
          count: 3,
          frozen: PlutoColumnFrozen.end,
        ),
      ];

      rows = RowHelper.count(10, columns);

      stateManager = createStateManager(
        columns: columns,
        rows: rows,
        gridFocusNode: null,
        scroll: null,
        layout: const BoxConstraints(maxWidth: 300, maxHeight: 500),
      );

      stateManager.setGridGlobalOffset(Offset.zero);
    });

    testWidgets(
      '스크롤 할 offset.dx 값이 bodyLeftScrollOffset 보다 작으면 true'
      '하지만, selectingMode 가 None 이면 false 를 리턴해야 한다.',
      (WidgetTester tester) async {
        stateManager.setSelectingMode(PlutoGridSelectingMode.none);

        expect(stateManager.selectingMode.isNone, true);

        expect(
          stateManager.needMovingScroll(
            Offset(stateManager.bodyLeftScrollOffset - 1, 0),
            PlutoMoveDirection.left,
          ),
          false,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dx 값이 bodyLeftScrollOffset 보다 작으면 true',
      (WidgetTester tester) async {
        expect(
          stateManager.needMovingScroll(
            Offset(stateManager.bodyLeftScrollOffset - 1, 0),
            PlutoMoveDirection.left,
          ),
          true,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dx 값이 bodyLeftScrollOffset 와 같으면 false',
      (WidgetTester tester) async {
        expect(
          stateManager.needMovingScroll(
            Offset(stateManager.bodyLeftScrollOffset, 0),
            PlutoMoveDirection.left,
          ),
          false,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dx 값이 bodyLeftScrollOffset 보다 크면 false',
      (WidgetTester tester) async {
        expect(
          stateManager.needMovingScroll(
            Offset(stateManager.bodyLeftScrollOffset + 1, 0),
            PlutoMoveDirection.left,
          ),
          false,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dx 값이 bodyRightScrollOffset 보다 크면 true'
      '하지만, selectingMode 가 None 이면 false 를 리턴해야 한다.',
      (WidgetTester tester) async {
        stateManager.setSelectingMode(PlutoGridSelectingMode.none);

        expect(stateManager.selectingMode.isNone, true);

        expect(
          stateManager.needMovingScroll(
            Offset(stateManager.bodyRightScrollOffset + 1, 0),
            PlutoMoveDirection.right,
          ),
          false,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dx 값이 bodyRightScrollOffset 보다 크면 true',
      (WidgetTester tester) async {
        expect(
          stateManager.needMovingScroll(
            Offset(stateManager.bodyRightScrollOffset + 1, 0),
            PlutoMoveDirection.right,
          ),
          true,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dx 값이 bodyRightScrollOffset 같으면 false',
      (WidgetTester tester) async {
        expect(
          stateManager.needMovingScroll(
            Offset(stateManager.bodyRightScrollOffset, 0),
            PlutoMoveDirection.right,
          ),
          false,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dx 값이 bodyRightScrollOffset 보다 작으면 false',
      (WidgetTester tester) async {
        expect(
          stateManager.needMovingScroll(
            Offset(stateManager.bodyRightScrollOffset - 1, 0),
            PlutoMoveDirection.right,
          ),
          false,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dy 값이 bodyUpScrollOffset 보다 작으면 true',
      (WidgetTester tester) async {
        expect(
          stateManager.needMovingScroll(
            Offset(0, stateManager.bodyUpScrollOffset - 1),
            PlutoMoveDirection.up,
          ),
          true,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dy 값이 bodyUpScrollOffset 같으면 false',
      (WidgetTester tester) async {
        expect(
          stateManager.needMovingScroll(
            Offset(0, stateManager.bodyUpScrollOffset),
            PlutoMoveDirection.up,
          ),
          false,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dy 값이 bodyUpScrollOffset 보다 크면 false',
      (WidgetTester tester) async {
        expect(
          stateManager.needMovingScroll(
            Offset(0, stateManager.bodyUpScrollOffset + 1),
            PlutoMoveDirection.up,
          ),
          false,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dy 값이 bodyDownScrollOffset 보다 크면 true',
      (WidgetTester tester) async {
        expect(
          stateManager.needMovingScroll(
            Offset(0, stateManager.bodyDownScrollOffset + 1),
            PlutoMoveDirection.down,
          ),
          true,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dy 값이 bodyDownScrollOffset 같으면 false',
      (WidgetTester tester) async {
        expect(
          stateManager.needMovingScroll(
            Offset(0, stateManager.bodyDownScrollOffset),
            PlutoMoveDirection.down,
          ),
          false,
        );
      },
    );

    testWidgets(
      '스크롤 할 offset.dy 값이 bodyDownScrollOffset 보다 작으면 false',
      (WidgetTester tester) async {
        expect(
          stateManager.needMovingScroll(
            Offset(0, stateManager.bodyDownScrollOffset - 1),
            PlutoMoveDirection.down,
          ),
          false,
        );
      },
    );
  });
}
