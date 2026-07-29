import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

const int stressColumnCount = 50;
const int stressRowCount = 100_000;

void main() {
  runApp(const ColumnResizeStressApp());
}

class ColumnResizeStressApp extends StatelessWidget {
  const ColumnResizeStressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Column resize stress test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const ColumnResizeStressPage(),
    );
  }
}

class ColumnResizeStressPage extends StatefulWidget {
  const ColumnResizeStressPage({super.key});

  @override
  State<ColumnResizeStressPage> createState() => _ColumnResizeStressPageState();
}

class _ColumnResizeStressPageState extends State<ColumnResizeStressPage> {
  final _FrameMetrics _frameMetrics = _FrameMetrics();

  List<PlutoColumn>? _columns;
  List<PlutoColumnGroup>? _columnGroups;
  List<PlutoRow>? _rows;
  Timer? _metricsTimer;
  Stopwatch? _gridLoadWatch;
  int? _dataGenerationMs;
  int? _gridLoadMs;
  int _renderedMetricsFrameCount = 0;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addTimingsCallback(_handleFrameTimings);
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          _renderedMetricsFrameCount != _frameMetrics.totalFrameCount) {
        setState(() {
          _renderedMetricsFrameCount = _frameMetrics.totalFrameCount;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateData();
    });
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_handleFrameTimings);
    super.dispose();
  }

  void _handleFrameTimings(List<FrameTiming> timings) {
    for (final FrameTiming timing in timings) {
      _frameMetrics.add(timing);
    }
  }

  void _generateData() {
    final Stopwatch watch = Stopwatch()..start();
    final List<String> fields = List<String>.generate(
      stressColumnCount,
      (int columnIndex) => 'column_$columnIndex',
      growable: false,
    );
    final List<PlutoColumn> columns = List<PlutoColumn>.generate(
      stressColumnCount,
      (int columnIndex) => PlutoColumn(
        title: 'Column ${columnIndex + 1}',
        field: fields[columnIndex],
        type: PlutoColumnType.number(),
        width: 140,
        enableContextMenu: false,
      ),
      growable: false,
    );
    final List<PlutoColumnGroup> columnGroups = List<PlutoColumnGroup>.generate(
      stressColumnCount ~/ 10,
      (int groupIndex) => PlutoColumnGroup(
        title: 'Group ${groupIndex + 1}',
        fields: fields.sublist(groupIndex * 10, (groupIndex + 1) * 10),
      ),
      growable: false,
    );
    final List<PlutoRow> rows = List<PlutoRow>.generate(stressRowCount, (
      int rowIndex,
    ) {
      final Map<String, PlutoCell> cells = <String, PlutoCell>{};

      for (
        int columnIndex = 0;
        columnIndex < stressColumnCount;
        columnIndex += 1
      ) {
        cells[fields[columnIndex]] = PlutoCell(
          value: rowIndex * stressColumnCount + columnIndex,
        );
      }

      return PlutoRow(cells: cells);
    }, growable: false);
    watch.stop();

    debugPrint(
      'Column resize stress: generated $stressColumnCount columns x '
      '$stressRowCount rows in ${watch.elapsedMilliseconds} ms.',
    );

    if (!mounted) {
      return;
    }

    _gridLoadWatch = Stopwatch()..start();
    setState(() {
      _columns = columns;
      _columnGroups = columnGroups;
      _rows = rows;
      _dataGenerationMs = watch.elapsedMilliseconds;
    });
  }

  void _handleGridLoaded(PlutoGridOnLoadedEvent event) {
    final Stopwatch? watch = _gridLoadWatch;

    if (watch == null || !watch.isRunning) {
      return;
    }

    watch.stop();
    _gridLoadMs = watch.elapsedMilliseconds;
    debugPrint(
      'Column resize stress: PlutoGrid onLoaded after $_gridLoadMs ms.',
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _resetFrameMetrics() {
    setState(() {
      _frameMetrics.reset();
      _renderedMetricsFrameCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<PlutoColumn>? columns = _columns;
    final List<PlutoColumnGroup>? columnGroups = _columnGroups;
    final List<PlutoRow>? rows = _rows;

    return Scaffold(
      appBar: AppBar(
        title: const Text('$stressColumnCount columns × $stressRowCount rows'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reset frame metrics',
            onPressed: _resetFrameMetrics,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: columns == null || columnGroups == null || rows == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating 5,000,000 cells…'),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _StressMetricsPanel(
                  dataGenerationMs: _dataGenerationMs,
                  gridLoadMs: _gridLoadMs,
                  frameMetrics: _frameMetrics.snapshot,
                ),
                Expanded(
                  child: PlutoGrid(
                    columns: columns,
                    columnGroups: columnGroups,
                    rows: rows,
                    onLoaded: _handleGridLoaded,
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
              ],
            ),
    );
  }
}

class _StressMetricsPanel extends StatelessWidget {
  final int? dataGenerationMs;
  final int? gridLoadMs;
  final _FrameMetricsSnapshot frameMetrics;

  const _StressMetricsPanel({
    required this.dataGenerationMs,
    required this.gridLoadMs,
    required this.frameMetrics,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle? labelStyle = Theme.of(context).textTheme.bodySmall;

    return ColoredBox(
      color: const Color(0xFFEFF6FF),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Wrap(
          spacing: 24,
          runSpacing: 6,
          children: <Widget>[
            Text('Data: ${dataGenerationMs ?? '…'} ms', style: labelStyle),
            Text('Grid onLoaded: ${gridLoadMs ?? '…'} ms', style: labelStyle),
            Text('Frames: ${frameMetrics.count}', style: labelStyle),
            Text(
              'Total p95: ${frameMetrics.totalP95.toStringAsFixed(1)} ms',
              style: labelStyle,
            ),
            Text(
              'Build p95: ${frameMetrics.buildP95.toStringAsFixed(1)} ms',
              style: labelStyle,
            ),
            Text(
              'Raster p95: ${frameMetrics.rasterP95.toStringAsFixed(1)} ms',
              style: labelStyle,
            ),
            Text('>16.7 ms: ${frameMetrics.slowFrameCount}', style: labelStyle),
          ],
        ),
      ),
    );
  }
}

class _FrameMetrics {
  static const int _sampleLimit = 600;

  final ListQueue<double> _totalMs = ListQueue<double>();
  final ListQueue<double> _buildMs = ListQueue<double>();
  final ListQueue<double> _rasterMs = ListQueue<double>();

  int totalFrameCount = 0;
  int slowFrameCount = 0;

  void add(FrameTiming timing) {
    final double totalMs = timing.totalSpan.inMicroseconds / 1000;

    totalFrameCount += 1;

    if (totalMs > 16.7) {
      slowFrameCount += 1;
    }

    _addBounded(_totalMs, totalMs);
    _addBounded(_buildMs, timing.buildDuration.inMicroseconds / 1000);
    _addBounded(_rasterMs, timing.rasterDuration.inMicroseconds / 1000);
  }

  void reset() {
    _totalMs.clear();
    _buildMs.clear();
    _rasterMs.clear();
    totalFrameCount = 0;
    slowFrameCount = 0;
  }

  _FrameMetricsSnapshot get snapshot => _FrameMetricsSnapshot(
    count: totalFrameCount,
    slowFrameCount: slowFrameCount,
    totalP95: _percentile95(_totalMs),
    buildP95: _percentile95(_buildMs),
    rasterP95: _percentile95(_rasterMs),
  );

  void _addBounded(ListQueue<double> values, double value) {
    if (values.length == _sampleLimit) {
      values.removeFirst();
    }

    values.addLast(value);
  }

  double _percentile95(Iterable<double> values) {
    if (values.isEmpty) {
      return 0;
    }

    final List<double> sorted = values.toList(growable: false)..sort();
    final int index = ((sorted.length - 1) * 0.95).round();

    return sorted[index];
  }
}

class _FrameMetricsSnapshot {
  final int count;
  final int slowFrameCount;
  final double totalP95;
  final double buildP95;
  final double rasterP95;

  const _FrameMetricsSnapshot({
    required this.count,
    required this.slowFrameCount,
    required this.totalP95,
    required this.buildP95,
    required this.rasterP95,
  });
}
