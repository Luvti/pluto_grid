import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

/// Run with --enable-vmservice. Object counts after full GC verify that even
/// a consumer retaining a disposed manager cannot retain the old grid data.
void main() {
  test(
    'repeated disposal releases 200000 cells with a retained manager',
    () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final _AllocationProfile profile = _AllocationProfile();
        try {
          await profile.connect();
          final List<Map<String, Object>> cycles = <Map<String, Object>>[];
          for (int cycle = 0; cycle < 3; cycle++) {
            final Map<String, int> before = await profile.snapshot();
            _retainedManager = _createManager();
            final Map<String, int> loaded = await profile.snapshot();
            _retainedManager!.dispose();
            final Map<String, int> disposed = await profile.snapshot();
            expect(_retainedManager!.columnsMap, isEmpty);
            expect(_retainedManager!.dragRows, isEmpty);
            expect(
              loaded['PlutoCell']! - before['PlutoCell']!,
              _rowCount * _columnCount,
            );
            expect(loaded['PlutoRow']! - before['PlutoRow']!, _rowCount);
            expect(
              loaded['PlutoColumn']! - before['PlutoColumn']!,
              _columnCount,
            );
            for (final String name in <String>[
              'PlutoCell',
              'PlutoRow',
              'PlutoColumn',
            ]) {
              expect(
                disposed[name],
                before[name],
                reason: '$name retained after cycle $cycle',
              );
            }
            cycles.add(<String, Object>{
              'cycle': cycle + 1,
              'loadedHeapBytes': loaded['heapBytes']! - before['heapBytes']!,
              'retainedHeapBytes':
                  disposed['heapBytes']! - before['heapBytes']!,
              'retainedCells': disposed['PlutoCell']! - before['PlutoCell']!,
              'retainedRows': disposed['PlutoRow']! - before['PlutoRow']!,
              'retainedColumns':
                  disposed['PlutoColumn']! - before['PlutoColumn']!,
            });
            _retainedManager!.gridFocusNode.dispose();
            _retainedManager = null;
          }
          final Map<String, Object> report = <String, Object>{
            'rows': _rowCount,
            'columns': _columnCount,
            'cellsPerCycle': _rowCount * _columnCount,
            'cycles': cycles,
          };
          // ignore: avoid_print
          print('GRID_DISPOSAL_MEMORY ${jsonEncode(report)}');
          final String? output =
              Platform.environment['PLUTO_GRID_DISPOSAL_MEMORY_REPORT'];
          if (output != null) {
            await File(output).writeAsString(
              '${const JsonEncoder.withIndent('  ').convert(report)}\n',
            );
          }
        } finally {
          final PlutoGridStateManager? manager = _retainedManager;
          if (manager != null) {
            if (!manager.streamNotifier.isClosed) {
              manager.dispose();
            }
            manager.gridFocusNode.dispose();
          }
          _retainedManager = null;
          profile.dispose();
        }
      }, _RealHttp());
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

const int _rowCount = 10000;
const int _columnCount = 20;
PlutoGridStateManager? _retainedManager;

PlutoGridStateManager _createManager() {
  final List<PlutoColumn> columns = List<PlutoColumn>.generate(
    _columnCount,
    (int index) => PlutoColumn(
      title: '',
      field: 'field$index',
      type: PlutoColumnType.text(),
    ),
  );
  final List<PlutoRow<dynamic>> rows = List<PlutoRow<dynamic>>.generate(
    _rowCount,
    (int index) => PlutoRow<dynamic>(
      cells: <String, PlutoCell>{
        for (final PlutoColumn column in columns)
          column.field: PlutoCell(value: index),
      },
    ),
  );
  return PlutoGridStateManager(
    columns: columns,
    rows: rows,
    gridFocusNode: FocusNode(),
    scroll: PlutoGridScrollController(),
  )..setDragRows(rows, notify: false);
}

class _RealHttp extends HttpOverrides {}

class _AllocationProfile {
  final HttpClient _client = HttpClient();
  late final Uri _service;
  late final String _isolate;

  Future<void> connect() async {
    final ServiceProtocolInfo info = await Service.getInfo();
    _service =
        info.serverUri ?? (throw StateError('Run with --enable-vmservice'));
    _isolate = Service.getIsolateId(Isolate.current)!;
  }

  Future<Map<String, int>> snapshot() async {
    final Uri uri = _service
        .resolve('getAllocationProfile')
        .replace(
          queryParameters: <String, String>{
            'isolateId': _isolate,
            'gc': 'true',
          },
        );
    final HttpClientRequest request = await _client.getUrl(uri);
    final HttpClientResponse response = await request.close();
    final Map<String, dynamic> json =
        jsonDecode(await response.transform(utf8.decoder).join())
            as Map<String, dynamic>;
    if (json['error'] != null) {
      throw StateError('${json['error']}');
    }
    final Map<String, dynamic> result = json['result'] as Map<String, dynamic>;
    final Map<String, int> stats = <String, int>{
      'heapBytes':
          (result['memoryUsage'] as Map<String, dynamic>)['heapUsage'] as int,
      'PlutoCell': 0,
      'PlutoRow': 0,
      'PlutoColumn': 0,
    };
    for (final Map<String, dynamic> member
        in (result['members'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final String name =
          (member['class'] as Map<String, dynamic>)['name'] as String;
      if (name == 'PlutoCell' || name == 'PlutoRow' || name == 'PlutoColumn') {
        stats[name] = member['instancesCurrent'] as int;
      }
    }
    return stats;
  }

  void dispose() => _client.close(force: true);
}
