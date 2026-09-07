import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import '../ui/ui.dart';

/// {@template pluto_aggregate_filter}
/// Returns whether to be filtered according to the value of [PlutoCell.value].
/// {@endtemplate}
typedef PlutoAggregateFilter = bool Function(PlutoCell);

/// {@template pluto_aggregate_column_type}
/// Determine the aggregate type.
/// {@endtemplate}
enum PlutoAggregateColumnType {
  /// Returns the sum of all values.
  sum,

  /// Returns the result of adding up all values and dividing by the number of elements.
  average,

  /// Returns the smallest value among all values.
  min,

  /// Returns the largest value out of all values.
  max,

  /// Returns the total count.
  count,

  /// Returns the total count.
  uniqueCount,
}

/// {@template pluto_aggregate_column_iterate_row_type}
/// Determine the condition of the rows to be included in the aggregation.
/// {@endtemplate}
enum PlutoAggregateColumnIterateRowType {
  /// Include all rows in the aggregation.
  all,

  /// Include the rows of the filtered result in the aggregation.
  filtered,

  /// Include rows from filtered and paginated results in aggregates.
  filteredAndPaginated;

  bool get isAll => this == PlutoAggregateColumnIterateRowType.all;

  bool get isFiltered => this == PlutoAggregateColumnIterateRowType.filtered;

  bool get isFilteredAndPaginated =>
      this == PlutoAggregateColumnIterateRowType.filteredAndPaginated;
}

/// {@template pluto_aggregate_column_grouped_row_type}
/// When grouping row is applied, set the condition of row to be aggregated.
/// {@endtemplate}
enum PlutoAggregateColumnGroupedRowType {
  /// processes both groups and rows.
  all,

  /// processes only the group and the children of the expanded group.
  expandedAll,

  /// processes non-group rows.
  rows,

  /// processes only expanded rows, not groups.
  expandedRows;

  bool get isAll => this == PlutoAggregateColumnGroupedRowType.all;

  bool get isExpandedAll =>
      this == PlutoAggregateColumnGroupedRowType.expandedAll;

  bool get isRows => this == PlutoAggregateColumnGroupedRowType.rows;

  bool get isExpandedRows =>
      this == PlutoAggregateColumnGroupedRowType.expandedRows;

  bool get isExpanded => isExpandedAll || isExpandedRows;

  bool get isRowsOnly => isRows || isExpandedRows;
}

/// Widget for outputting the sum, average, minimum,
/// and maximum values of all values in a column.
/// Totals are calculated in small batches across frames. The previous completed
/// total remains visible while data changes are being processed.
///
/// Example) [PlutoColumn.footerRenderer] Implement column footer as return value of callback
/// ```dart
/// PlutoColumn(
///   title: 'column',
///   field: 'column',
///   type: PlutoColumnType.number(format: '#,###.###'),
///   textAlign: PlutoColumnTextAlign.right,
///   footerRenderer: (rendererContext) {
///     return PlutoAggregateColumnFooter(
///       rendererContext: rendererContext,
///       type: PlutoAggregateColumnType.sum,
///       format: 'Sum : #,###.###',
///       alignment: Alignment.center,
///     );
///   },
/// ),
/// ```
///
/// [PlutoAggregateColumnFooter]
/// You can also return a [Widget] you wrote yourself instead of a widget.
/// However, you must implement the process
/// of updating according to the value change yourself.
class PlutoAggregateColumnFooter extends PlutoStatefulWidget {
  /// Contains information needed to implement the widget.
  final PlutoColumnFooterRendererContext rendererContext;

  /// {@macro pluto_aggregate_column_type}
  final PlutoAggregateColumnType type;

  /// {@macro pluto_aggregate_column_iterate_row_type}
  final PlutoAggregateColumnIterateRowType iterateRowType;

  /// {@macro pluto_aggregate_column_grouped_row_type}
  final PlutoAggregateColumnGroupedRowType groupedRowType;

  /// {@macro pluto_aggregate_filter}
  ///
  /// Example) Only when the value of [PlutoCell.value] is Android,
  /// it is included in the aggregate list.
  /// ```dart
  /// filter: (cell) => cell.value == 'Android',
  /// ```
  final PlutoAggregateFilter? filter;

  /// Set the format of aggregated result values.
  ///
  /// Example)
  /// ```dart
  /// format: 'Android: #,###', // Android: 100 (if the result is 100)
  /// format: '#,###.###', // 1,000,000.123 (expressed to 3 decimal places)
  /// ```
  final String format;

  /// Setting the locale of the resulting value.
  ///
  /// Example)
  /// ```dart
  /// locale: 'da_DK',
  /// ```
  final String? locale;

  /// You can customize the resulting values.
  ///
  /// Example)
  /// ```dart
  /// titleSpanBuilder: (text) {
  ///   return [
  ///     const TextSpan(
  ///       text: 'Sum',
  ///       style: TextStyle(color: Colors.red),
  ///     ),
  ///     const TextSpan(text: ' : '),
  ///     TextSpan(text: text),
  ///   ];
  /// },
  /// ```
  final List<InlineSpan> Function(String)? titleSpanBuilder;

  final AlignmentGeometry? alignment;

  final EdgeInsets? padding;

  final bool formatAsCurrency;

  const PlutoAggregateColumnFooter({
    required this.rendererContext,
    required this.type,
    this.iterateRowType =
        PlutoAggregateColumnIterateRowType.filteredAndPaginated,
    this.groupedRowType = PlutoAggregateColumnGroupedRowType.all,
    this.filter,
    this.format = '#,###',
    this.locale,
    this.titleSpanBuilder,
    this.alignment,
    this.padding,
    this.formatAsCurrency = false,
    super.key,
  });

  @override
  PlutoAggregateColumnFooterState createState() =>
      PlutoAggregateColumnFooterState();
}

class PlutoAggregateColumnFooterState
    extends State<PlutoAggregateColumnFooter> {
  num? _aggregatedValue;
  late NumberFormat _numberFormat;
  late StreamSubscription<PlutoNotifierEvent> _subscription;
  PlutoGridAsyncCalculation? _calculation;

  PlutoGridStateManager get stateManager => widget.rendererContext.stateManager;
  PlutoColumn get column => widget.rendererContext.column;

  @override
  void initState() {
    super.initState();
    _setFormat();
    _subscribe();
    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  void _setFormat() {
    _numberFormat = widget.formatAsCurrency
        ? NumberFormat.simpleCurrency(locale: widget.locale)
        : NumberFormat(widget.format, widget.locale);
  }

  void _subscribe() {
    final PlutoChangeNotifierFilter<PlutoAggregateColumnFooter> filter =
        stateManager.resolveNotifierFilter<PlutoAggregateColumnFooter>();
    _subscription = stateManager.streamNotifier.stream
        .where(
          (PlutoNotifierEvent event) =>
              !PlutoChangeNotifierFilter.enabled || filter.any(event),
        )
        .listen(updateState);
  }

  @override
  void didUpdateWidget(covariant PlutoAggregateColumnFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.rendererContext.stateManager, stateManager)) {
      unawaited(_subscription.cancel());
      _subscribe();
    }
    if (oldWidget.format != widget.format ||
        oldWidget.locale != widget.locale ||
        oldWidget.formatAsCurrency != widget.formatAsCurrency) {
      _setFormat();
    }
    if (!identical(oldWidget.rendererContext.stateManager, stateManager) ||
        oldWidget.rendererContext.column != column ||
        oldWidget.type != widget.type ||
        oldWidget.iterateRowType != widget.iterateRowType ||
        oldWidget.groupedRowType != widget.groupedRowType ||
        oldWidget.filter != widget.filter) {
      if (!identical(oldWidget.rendererContext.stateManager, stateManager) ||
          oldWidget.rendererContext.column != column ||
          oldWidget.type != widget.type) {
        _aggregatedValue = null;
      }
      updateState(PlutoNotifierEventForceUpdate.instance);
    }
  }

  @override
  void dispose() {
    _calculation?.cancel();
    unawaited(_subscription.cancel());
    super.dispose();
  }

  void updateState(PlutoNotifierEvent event) {
    _calculation?.cancel();
    final PlutoAggregateColumnFooter footer = widget;
    final PlutoGridStateManager manager = stateManager;
    num? result;
    _calculation = PlutoGridAsyncCalculation(
      steps: () sync* {
        final _AggregateCalculator calculator = _AggregateCalculator(footer);
        if (!calculator.finished) {
          final Iterable<PlutoRow<dynamic>> roots;
          switch (footer.iterateRowType) {
            case PlutoAggregateColumnIterateRowType.all:
              roots = manager.refRows.originalListView;
            case PlutoAggregateColumnIterateRowType.filtered:
              roots = manager.refRows.filterOrOriginalListView;
            case PlutoAggregateColumnIterateRowType.filteredAndPaginated:
              roots = manager.refRows;
          }
          final bool grouped = manager.enabledRowGroups;
          if (!grouped &&
              footer.type == PlutoAggregateColumnType.count &&
              footer.filter == null) {
            // Every root source is a list with constant-time length access.
            result = PlutoAggregateHelper.count(
              rows: roots,
              column: footer.rendererContext.column,
            );
            return;
          }
          outer:
          for (final PlutoRow<dynamic> root in roots) {
            if (!grouped) {
              calculator.add(root);
              yield null;
              if (calculator.finished) {
                break;
              }
              continue;
            }
            if (!root.isMain) {
              yield null;
              continue;
            }
            final Iterable<PlutoRow<dynamic>> rows =
                PlutoRowGroupHelper.iterateWithFilter(
                  <PlutoRow<dynamic>>[root],
                  childrenFilter: (PlutoRow<dynamic> row) {
                    if (!row.type.isGroup ||
                        (footer.groupedRowType.isExpanded &&
                            !row.type.group.expanded)) {
                      return null;
                    }
                    return footer.iterateRowType.isAll
                        ? row.type.group.children.originalListView.iterator
                        : row.type.group.children.iterator;
                  },
                );
            for (final PlutoRow<dynamic> row in rows) {
              if (!footer.groupedRowType.isRowsOnly || !row.type.isGroup) {
                calculator.add(row);
              }
              yield null;
              if (calculator.finished) {
                break outer;
              }
            }
          }
        }
        result = calculator.value;
      },
      onCompleted: () {
        if (mounted && result != _aggregatedValue) {
          setState(() => _aggregatedValue = result);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTitleSpan = widget.titleSpanBuilder != null;

    final formattedValue = _aggregatedValue == null
        ? ''
        : _numberFormat.format(_aggregatedValue);

    final text = hasTitleSpan ? null : formattedValue;

    final children = hasTitleSpan
        ? widget.titleSpanBuilder!(formattedValue)
        : null;

    return Padding(
      padding: widget.padding ?? PlutoGridSettings.columnTitlePadding,
      child: Align(
        alignment: widget.alignment ?? AlignmentDirectional.centerStart,
        child: Text.rich(
          TextSpan(text: text, children: children),
          style: stateManager.configuration.style.cellTextStyle.copyWith(
            decoration: TextDecoration.none,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// Incremental counterpart of PlutoAggregateHelper. Formatting happens only once,
// after every selected row has been processed.
class _AggregateCalculator {
  _AggregateCalculator(PlutoAggregateColumnFooter footer)
    : type = footer.type,
      columnType = footer.rendererContext.column.type,
      field = footer.rendererContext.column.field,
      filter = footer.filter {
    final bool numeric = columnType is PlutoColumnTypeWithNumberFormat;
    finished = switch (type) {
      PlutoAggregateColumnType.sum ||
      PlutoAggregateColumnType.min ||
      PlutoAggregateColumnType.max => !numeric,
      PlutoAggregateColumnType.average => !numeric && !isDoubleAverage,
      _ => false,
    };
  }

  final PlutoAggregateColumnType type;
  final PlutoColumnType columnType;
  final String field;
  final PlutoAggregateFilter? filter;
  bool finished = false;
  bool _hasField = false;
  bool _started = false;
  int _count = 0;
  num _sum = 0;
  double _average = 0;
  num? _extreme;
  final Set<Object?> _unique = <Object?>{};

  bool get isDoubleAverage =>
      type == PlutoAggregateColumnType.average &&
      columnType is PlutoColumnTypeWithDoubleFormat;

  void add(PlutoRow<dynamic> row) {
    if (!_started) {
      _started = true;
      _hasField = row.cells.containsKey(field);
      if (!_hasField && !isDoubleAverage) {
        finished = true;
        return;
      }
    }
    final PlutoCell? cell = row.cells[field];
    if (filter != null && !filter!(cell!)) {
      return;
    }
    switch (type) {
      case PlutoAggregateColumnType.count:
        _count += 1;
      case PlutoAggregateColumnType.uniqueCount:
        _unique.add(cell?.currentValue);
      case PlutoAggregateColumnType.sum:
      case PlutoAggregateColumnType.average:
        final num? number = isDoubleAverage
            ? cell?.valueForSorting as double?
            : cell?.currentValue as num?;
        if (number != null) {
          _count += 1;
          if (type == PlutoAggregateColumnType.sum) {
            _sum += number;
          } else {
            _average += (number - _average) / _count;
          }
        }
      case PlutoAggregateColumnType.min:
      case PlutoAggregateColumnType.max:
        final num number = cell!.currentValue as num;
        if (_extreme == null ||
            number.isNaN ||
            (type == PlutoAggregateColumnType.min
                ? number < _extreme!
                : number > _extreme!)) {
          _extreme = number;
        }
        if (number.isNaN) {
          finished = true;
        }
    }
  }

  num? get value {
    switch (type) {
      case PlutoAggregateColumnType.count:
        return _count;
      case PlutoAggregateColumnType.uniqueCount:
        return _unique.length;
      case PlutoAggregateColumnType.min:
      case PlutoAggregateColumnType.max:
        return _extreme;
      case PlutoAggregateColumnType.sum:
        if (_count == 0) {
          return 0;
        }
        final PlutoColumnTypeWithNumberFormat numberColumn =
            columnType as PlutoColumnTypeWithNumberFormat;
        return numberColumn.toNumber(numberColumn.applyFormat(_sum));
      case PlutoAggregateColumnType.average:
        if (isDoubleAverage) {
          if (_count == 0) {
            return null;
          }
          final PlutoColumnTypeWithDoubleFormat doubleColumn =
              columnType as PlutoColumnTypeWithDoubleFormat;
          return doubleColumn.toDouble(doubleColumn.applyFormat(_average));
        }
        if (!_hasField) {
          return 0;
        }
        if (_count == 0) {
          return null;
        }
        final PlutoColumnTypeWithNumberFormat numberColumn =
            columnType as PlutoColumnTypeWithNumberFormat;
        return numberColumn.toNumber(numberColumn.applyFormat(_average));
    }
  }
}
