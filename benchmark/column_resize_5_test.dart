import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  testWidgets(
    'measures double-click auto-fit latency with five rows',
    (WidgetTester tester) async {
      final PlutoColumn column = PlutoColumn(
        title: 'Updated',
        field: 'updated',
        type: PlutoColumnType.text(),
        width: 180,
      );
      final List<PlutoRow<dynamic>> rows = <PlutoRow<dynamic>>[
        for (final String value in <String>[
          'Today',
          'Today',
          'Yesterday',
          'Yesterday',
          '2 days ago',
        ])
          PlutoRow<dynamic>(
            cells: <String, PlutoCell>{
              column.field: PlutoCell(value: value),
            },
          ),
      ];
      late final PlutoGridStateManager stateManager;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoGrid(
              columns: <PlutoColumn>[column],
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
              },
              configuration: const PlutoGridConfiguration(
                style: PlutoGridStyleConfig(
                  showColumnHeaderIcon: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final Stopwatch directWatch = Stopwatch()..start();
      final BuildContext gridContext = tester.element(find.byType(PlutoGrid));
      if (!gridContext.mounted) {
        fail('The grid context must remain mounted during the benchmark.');
      }
      stateManager.autoFitColumn(gridContext, column);
      directWatch.stop();
      final double directWidth = column.width;
      column.width = 180;
      stateManager.notifyResizingListeners();
      await tester.pump();
      final double initialWidth = column.width;

      final Finder resizeHandle = find.byKey(
        const ValueKey<String>('column_resize_handle_updated'),
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

      final Stopwatch calculationWatch = Stopwatch()..start();
      await mouse.up(timeStamp: const Duration(milliseconds: 102));
      calculationWatch.stop();
      final double widthAfterPointerUp = column.width;

      final Stopwatch rebuildWatch = Stopwatch()..start();
      await tester.pump();
      rebuildWatch.stop();

      expect(widthAfterPointerUp, lessThan(initialWidth));

      // Kept outside test/ so timing diagnostics do not run in the regular
      // suite and cannot introduce a flaky performance threshold.
      // ignore: avoid_print
      print(
        'COLUMN_RESIZE_5 '
        'direct=${directWatch.elapsedMicroseconds}us '
        'directWidth=$directWidth '
        'initialWidth=$initialWidth '
        'afterPointerUp=$widthAfterPointerUp '
        'afterRebuild=${column.width} '
        'pointerUp=${calculationWatch.elapsedMicroseconds}us '
        'rebuild=${rebuildWatch.elapsedMicroseconds}us',
      );

      await mouse.removePointer();
    },
  );
}
