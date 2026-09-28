import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

/// Run with Flutter's --enable-vmservice flag. The eager fixture reproduces
/// the previous per-cell key and comparison allocations on the same model.
void main() {
  test('compares eager and lazy allocation for one million cells', () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final benchmark = _CellMemoryBenchmark();
      try {
        await benchmark.connect();
        final eager = await benchmark.measure(eager: true);
        final lazy = await benchmark.measure(eager: false);
        final report = <String, Object>{
          'rows': _CellMemoryBenchmark.rowCount,
          'columns': _CellMemoryBenchmark.columnCount,
          'cells':
              _CellMemoryBenchmark.rowCount * _CellMemoryBenchmark.columnCount,
          'comparison':
              'same model; previous eager allocation versus lazy allocation',
          'eager': eager,
          'lazy': lazy,
        };
        // ignore: avoid_print
        print('CELL_MEMORY ${jsonEncode(report)}');
        final output = Platform.environment['PLUTO_CELL_MEMORY_REPORT'];
        if (output != null) {
          await File(output).writeAsString(
            '${const JsonEncoder.withIndent('  ').convert(report)}\n',
          );
        }
        expect(
          lazy['keys'],
          _CellMemoryBenchmark.rowCount + _CellMemoryBenchmark.columnCount,
        );
        expect(
          eager['keys'],
          _CellMemoryBenchmark.rowCount *
                  (_CellMemoryBenchmark.columnCount + 1) +
              _CellMemoryBenchmark.columnCount,
        );
        expect(lazy['cellBytes'], eager['cellBytes']);
        expect(lazy['heapBytes']! < eager['heapBytes']!, isTrue);
      } finally {
        benchmark.dispose();
      }
    }, _RealHttp());
  }, timeout: const Timeout(Duration(minutes: 2)));
}

class _RealHttp extends HttpOverrides {}

class _CellMemoryBenchmark {
  static const int rowCount = 50000;
  static const int columnCount = 20;
  static List<PlutoRow> _rows = <PlutoRow>[];
  final HttpClient _client = HttpClient();
  late Uri _service;
  late String _isolate;

  Future<void> connect() async {
    final info = await Service.controlWebServer(enable: true);
    _service =
        info.serverUri ?? (throw StateError('Run with --enable-vmservice'));
    _isolate = Service.getIsolateId(Isolate.current)!;
  }

  Future<Map<String, int>> _snapshot() async {
    final uri = _service
        .resolve('getAllocationProfile')
        .replace(
          queryParameters: <String, String>{
            'isolateId': _isolate,
            'gc': 'true',
          },
        );
    final response = await (await _client.getUrl(uri)).close();
    final json =
        jsonDecode(await response.transform(utf8.decoder).join())
            as Map<String, dynamic>;
    if (json['error'] != null) throw StateError('${json['error']}');
    final result = json['result'] as Map<String, dynamic>;
    final stats = <String, int>{
      'heapBytes': result['memoryUsage']['heapUsage'] as int,
    };
    for (final member in result['members'] as List<dynamic>) {
      final name = member['class']['name'];
      if (name == 'UniqueKey')
        stats['keys'] = member['instancesCurrent'] as int;
      if (name == 'PlutoCell')
        stats['cellBytes'] = member['bytesCurrent'] as int;
      if (name == '_OneByteString')
        stats['stringBytes'] = member['bytesCurrent'] as int;
    }
    return stats;
  }

  Future<Map<String, int>> measure({required bool eager}) async {
    _rows = <PlutoRow>[];
    final before = await _snapshot();
    final columns = List<PlutoColumn>.generate(
      columnCount,
      (index) => PlutoColumn(
        title: '',
        field: 'field$index',
        type: PlutoColumnType.text(),
      ),
    );
    final watch = Stopwatch()..start();
    _rows = List<PlutoRow>.generate(
      rowCount,
      (index) => PlutoRow(
        cells: <String, PlutoCell>{
          for (final column in columns) column.field: PlutoCell(value: index),
        },
      ),
    );
    PlutoGridStateManager.initializeRows(columns, _rows);
    if (eager) {
      for (final row in _rows) {
        for (final cell in row.cells.values) {
          cell.key;
          cell.valueForSorting;
        }
      }
    }
    watch.stop();
    final after = await _snapshot();
    return <String, int>{
      for (final entry in after.entries)
        entry.key: entry.value - (before[entry.key] ?? 0),
      'initializationMs': watch.elapsedMilliseconds,
    };
  }

  void dispose() {
    _rows = <PlutoRow>[];
    _client.close(force: true);
  }
}
