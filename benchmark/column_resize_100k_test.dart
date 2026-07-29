import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

const int _columnCount = 50;
const int _rowCount = 100_000;

void main() {
  testWidgets(
    'resizes a column with 50 columns and 100000 rows',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final int rssBefore = ProcessInfo.currentRss;
      final Stopwatch generationWatch = Stopwatch()..start();
      final List<String> fields = List<String>.generate(
        _columnCount,
        (int index) => 'column_$index',
        growable: false,
      );
      final List<PlutoColumn> columns = List<PlutoColumn>.generate(
        _columnCount,
        (int index) => PlutoColumn(
          title: 'Column ${index + 1}',
          field: fields[index],
          type: PlutoColumnType.number(),
          width: 140,
          enableContextMenu: false,
        ),
        growable: false,
      );
      final List<PlutoColumnGroup> columnGroups =
          List<PlutoColumnGroup>.generate(
            _columnCount ~/ 10,
            (int groupIndex) => PlutoColumnGroup(
              title: 'Group ${groupIndex + 1}',
              fields: fields.sublist(groupIndex * 10, (groupIndex + 1) * 10),
            ),
            growable: false,
          );
      final List<PlutoRow<dynamic>> rows = List<PlutoRow<dynamic>>.generate(
        _rowCount,
        (int rowIndex) {
          final Map<String, PlutoCell> cells = <String, PlutoCell>{};

          for (
            int columnIndex = 0;
            columnIndex < _columnCount;
            columnIndex += 1
          ) {
            cells[fields[columnIndex]] = PlutoCell(
              value: rowIndex * _columnCount + columnIndex,
            );
          }

          return PlutoRow<dynamic>(cells: cells);
        },
        growable: false,
      );
      generationWatch.stop();

      late PlutoGridStateManager stateManager;
      final Stopwatch firstRenderWatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoGrid(
              columns: columns,
              columnGroups: columnGroups,
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
              },
              configuration: const PlutoGridConfiguration(
                style: PlutoGridStyleConfig(
                  columnBorderWidth: 0.5,
                  rowBorderWidth: 0.5,
                  showColumnHeaderIcon: false,
                  columnResizeIndicatorMode:
                      PlutoColumnResizeIndicatorMode.fullHeight,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      firstRenderWatch.stop();

      expect(stateManager.columns.length, _columnCount);
      expect(stateManager.refRows.length, _rowCount);

      final Finder cellHandles = find.byWidgetPredicate((Widget widget) {
        final Key? key = widget.key;

        return key is ValueKey<String> &&
            key.value.startsWith('cell_resize_handle_');
      });
      final int mountedCellHandleCount = cellHandles.evaluate().length;

      expect(mountedCellHandleCount, greaterThan(0));
      expect(mountedCellHandleCount, lessThan(1000));

      final Finder firstHandle = find.byKey(
        const ValueKey<String>('cell_resize_handle_column_0_0'),
      );
      expect(firstHandle, findsOneWidget);

      final double widthBefore = columns.first.width;
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      final Offset handleCenter = tester.getCenter(firstHandle);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(handleCenter);
      await tester.pump(const Duration(milliseconds: 120));

      expect(
        find.byKey(
          const ValueKey<String>('FullHeightColumnResizeIndicator'),
        ),
        findsOneWidget,
      );

      final Stopwatch dragWatch = Stopwatch()..start();

      await mouse.down(handleCenter);

      for (int frame = 0; frame < 120; frame += 1) {
        await mouse.moveBy(const Offset(0.5, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }

      await mouse.up();
      await tester.pump(const Duration(milliseconds: 120));
      dragWatch.stop();

      expect(columns.first.width, greaterThan(widthBefore));

      final Stopwatch autoFitWatch = Stopwatch()..start();

      stateManager.autoFitColumn(
        tester.element(find.byType(PlutoGrid)),
        columns.last,
      );
      await tester.pump();
      autoFitWatch.stop();

      final int rssAfter = ProcessInfo.currentRss;
      final double rssDeltaMb = (rssAfter - rssBefore) / 1024 / 1024;

      // Kept outside test/ so this intentionally heavy benchmark does not run
      // as part of the normal unit-test suite.
      // ignore: avoid_print
      print(
        'COLUMN_RESIZE_STRESS '
        'data=${generationWatch.elapsedMilliseconds}ms '
        'firstRender=${firstRenderWatch.elapsedMilliseconds}ms '
        'drag120Frames=${dragWatch.elapsedMilliseconds}ms '
        'autoFitLastColumn=${autoFitWatch.elapsedMilliseconds}ms '
        'mountedHandles=$mountedCellHandleCount '
        'rssDelta=${rssDeltaMb.toStringAsFixed(1)}MB',
      );

      await mouse.removePointer();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
