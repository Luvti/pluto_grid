import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

/// Frames, CPU time and the longest frame of incremental
/// [PlutoAggregateColumnFooter] totals for a large table (default 200k rows ×
/// sum, average, min and max footers).
///
/// Footer calculations run only inside frame callbacks, so every pump is timed
/// with a real clock: its duration is the event-loop stall of that frame. Wall
/// time is modelled at 60 Hz because frames shorter than a vsync interval still
/// wait for the next one. The printed summary is the median of the runs after
/// the first (JIT warm-up) one.
///
/// ```sh
/// AGGREGATE_REPORT=/tmp/aggregate.json flutter test benchmark/aggregate_footer_async_test.dart
/// ```
void main() {
  final int rowCount = int.parse(
    Platform.environment['AGGREGATE_ROWS'] ?? '200000',
  );
  final int runs = int.parse(Platform.environment['AGGREGATE_RUNS'] ?? '5');
  const Duration vsync = Duration(microseconds: 16667);
  const List<PlutoAggregateColumnType> types = <PlutoAggregateColumnType>[
    PlutoAggregateColumnType.sum,
    PlutoAggregateColumnType.average,
    PlutoAggregateColumnType.min,
    PlutoAggregateColumnType.max,
  ];

  testWidgets('aggregate footers on $rowCount rows', (
    WidgetTester tester,
  ) async {
    final List<PlutoColumn> columns = <PlutoColumn>[
      for (int index = 0; index < types.length; index++)
        PlutoColumn(
          title: 'c$index',
          field: 'c$index',
          type: PlutoColumnType.number(),
        ),
    ];
    final List<PlutoRow<dynamic>> rows = <PlutoRow<dynamic>>[
      for (int row = 0; row < rowCount; row++)
        PlutoRow<dynamic>(
          cells: <String, PlutoCell>{
            for (int index = 0; index < columns.length; index++)
              columns[index].field: PlutoCell(
                value: (row * 7919 + index * 104729) % 100003,
              ),
          },
        ),
    ];
    final FocusNode focus = FocusNode();
    final PlutoGridStateManager state = PlutoGridStateManager(
      columns: columns,
      rows: rows,
      gridFocusNode: focus,
      scroll: PlutoGridScrollController(),
    );
    addTearDown(() {
      state.dispose();
      focus.dispose();
    });

    // The same totals without yielding: the CPU floor of the work itself.
    final Stopwatch syncClock = Stopwatch()..start();
    final List<String> expected = <String>[
      for (int index = 0; index < types.length; index++)
        NumberFormat('#,###').format(
          switch (types[index]) {
            PlutoAggregateColumnType.sum => PlutoAggregateHelper.sum,
            PlutoAggregateColumnType.average => PlutoAggregateHelper.average,
            PlutoAggregateColumnType.min => PlutoAggregateHelper.min,
            PlutoAggregateColumnType.max => PlutoAggregateHelper.max,
            _ => throw UnsupportedError('${types[index]}'),
          }(rows: state.refRows, column: columns[index]),
        ),
    ];
    final int syncMs = syncClock.elapsedMilliseconds;

    final List<Map<String, Object>> results = <Map<String, Object>>[];
    for (int run = 0; run < runs; run++) {
      // A new key mounts fresh footers, each starting a full calculation.
      final Stopwatch frame = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            key: ValueKey<int>(run),
            children: <Widget>[
              for (int index = 0; index < types.length; index++)
                PlutoAggregateColumnFooter(
                  rendererContext: PlutoColumnFooterRendererContext(
                    stateManager: state,
                    column: columns[index],
                  ),
                  type: types[index],
                ),
            ],
          ),
        ),
      );
      final List<int> frameUs = <int>[frame.elapsedMicroseconds];
      while (tester.binding.hasScheduledFrame) {
        frame.reset();
        await tester.pump(vsync);
        frameUs.add(frame.elapsedMicroseconds);
      }

      final List<String> shown = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(PlutoAggregateColumnFooter),
              matching: find.byType(Text),
            ),
          )
          .map((Text text) => text.textSpan!.toPlainText())
          .toList();
      expect(shown, expected);

      // The mount frame builds the tree; the calculation runs in the rest.
      final List<int> calculationUs = frameUs.sublist(1);
      int cpuUs = 0;
      int wallUs = 0;
      for (final int us in calculationUs) {
        cpuUs += us;
        wallUs += max(us, vsync.inMicroseconds);
      }
      results.add(<String, Object>{
        'frames': calculationUs.length,
        'cpuMs': (cpuUs / 1000).toStringAsFixed(1),
        'wallMsAt60Hz': (wallUs / 1000).toStringAsFixed(0),
        'p50FrameMs':
            ((List<int>.of(calculationUs)..sort())[calculationUs.length ~/ 2] /
                    1000)
                .toStringAsFixed(2),
        'maxFrameMs': (calculationUs.reduce(max) / 1000).toStringAsFixed(2),
        'nsPerRowPerFooter': (cpuUs * 1000 / (rowCount * types.length)).round(),
        'stepsPerFrame': (rowCount * types.length / calculationUs.length)
            .round(),
      });
    }

    // The first run includes JIT warm-up; report the median steady run.
    final List<Map<String, Object>> steady =
        (results.length > 1 ? results.sublist(1) : results).toList()..sort(
          (Map<String, Object> a, Map<String, Object> b) => double.parse(
            a['cpuMs']! as String,
          ).compareTo(double.parse(b['cpuMs']! as String)),
        );
    final Map<String, Object> median = steady[steady.length ~/ 2];
    final Map<String, Object> report = <String, Object>{
      'rows': rowCount,
      'footers': types.length,
      'syncMs': syncMs,
      ...median,
      'runs': results,
    };
    // ignore: avoid_print
    print('PLUTO_AGGREGATE_FOOTER_ASYNC ${jsonEncode(report)}');
    final String? out = Platform.environment['AGGREGATE_REPORT'];
    if (out != null) {
      File(out).writeAsStringSync(jsonEncode(report));
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
