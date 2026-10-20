import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

/// Wall time and the longest event-loop stall of [PlutoGridStateManager.initializeRowsAsync]
/// for a large table (default 200k rows × 21 columns, like an ASO.dev report).
///
/// ```sh
/// INIT_ROWS_REPORT=/tmp/init-rows.json flutter test benchmark/initialize_rows_async_test.dart
/// ```
void main() {
  final int rowCount = int.parse(
    Platform.environment['INIT_ROWS_COUNT'] ?? '200000',
  );
  const int columnCount = 21;

  test('initializeRowsAsync on $rowCount rows', () async {
    final List<PlutoColumn> columns = <PlutoColumn>[
      for (int index = 0; index < columnCount; index++)
        PlutoColumn(
          title: 'c$index',
          field: 'c$index',
          type: index.isEven
              ? PlutoColumnType.text()
              : PlutoColumnType.number(),
        ),
    ];
    final List<PlutoRow> rows = <PlutoRow>[
      for (int row = 0; row < rowCount; row++)
        PlutoRow(
          cells: <String, PlutoCell>{
            for (final PlutoColumn column in columns)
              column.field: PlutoCell(value: row),
          },
        ),
    ];

    // A 1 ms heartbeat: its largest gap is the longest time the event loop
    // (and therefore frames and input) was blocked.
    final Stopwatch clock = Stopwatch()..start();
    int lastBeat = 0;
    int maxGapUs = 0;
    int beats = 0;
    final Timer heartbeat = Timer.periodic(const Duration(milliseconds: 1), (
      _,
    ) {
      final int now = clock.elapsedMicroseconds;
      maxGapUs = max(maxGapUs, now - lastBeat);
      lastBeat = now;
      beats++;
    });

    final String? budgetMs = Platform.environment['INIT_ROWS_BUDGET_MS'];
    final List<PlutoRow> result = budgetMs == null
        ? await PlutoGridStateManager.initializeRowsAsync(columns, rows)
        : await PlutoGridStateManager.initializeRowsAsync(
            columns,
            rows,
            frameBudget: Duration(milliseconds: int.parse(budgetMs)),
          );
    final int totalMs = clock.elapsedMilliseconds;
    heartbeat.cancel();

    expect(result.length, rowCount);
    expect(result.last.sortIdx, rowCount - 1);
    expect(result.last.cells['c0']!.row, same(result.last));

    // The same work without yielding, on fresh rows: the CPU cost itself.
    final List<PlutoRow> syncRows = <PlutoRow>[
      for (int row = 0; row < rowCount; row++)
        PlutoRow(
          cells: <String, PlutoCell>{
            for (final PlutoColumn column in columns)
              column.field: PlutoCell(value: row),
          },
        ),
    ];
    final Stopwatch syncClock = Stopwatch()..start();
    PlutoGridStateManager.initializeRows(columns, syncRows);
    final int syncMs = syncClock.elapsedMilliseconds;

    final Map<String, Object> report = <String, Object>{
      'syncMs': syncMs,
      'rows': rowCount,
      'columns': columnCount,
      'totalMs': totalMs,
      'maxEventLoopStallMs': (maxGapUs / 1000).toStringAsFixed(1),
      'heartbeats': beats,
    };
    // ignore: avoid_print
    print('PLUTO_INIT_ROWS_ASYNC ${jsonEncode(report)}');
    final String? out = Platform.environment['INIT_ROWS_REPORT'];
    if (out != null) {
      File(out).writeAsStringSync(jsonEncode(report));
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
