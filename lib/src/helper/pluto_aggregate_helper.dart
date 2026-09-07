import 'package:collection/collection.dart'
    show IterableExtension, IterableNumberExtension;
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

class PlutoAggregateHelper {
  static num? sum({
    required Iterable<PlutoRow> rows,
    required PlutoColumn column,
    PlutoAggregateFilter? filter,
  }) {
    if (column.type is! PlutoColumnTypeWithNumberFormat) {
      return 0;
    }

    final String field = column.field;
    final Iterator<PlutoRow<dynamic>> iterator = rows.iterator;
    if (!iterator.moveNext() || !iterator.current.cells.containsKey(field)) {
      return 0;
    }

    final PlutoColumnTypeWithNumberFormat numberColumn =
        column.type as PlutoColumnTypeWithNumberFormat;
    num total = 0;
    bool hasValue = false;
    do {
      final PlutoCell? cell = iterator.current.cells[field];
      if (filter != null && !filter(cell!)) {
        continue;
      }
      final num? value = cell?.currentValue as num?;
      if (value != null) {
        total += value;
        hasValue = true;
      }
    } while (iterator.moveNext());

    return hasValue
        ? numberColumn.toNumber(numberColumn.applyFormat(total))
        : 0;
  }

  static num? average({
    required Iterable<PlutoRow> rows,
    required PlutoColumn column,
    PlutoAggregateFilter? filter,
  }) {
    final PlutoColumnType columnType = column.type;
    final bool isDouble = columnType is PlutoColumnTypeWithDoubleFormat;
    if (!isDouble && columnType is! PlutoColumnTypeWithNumberFormat) {
      return 0;
    }

    final String field = column.field;
    final Iterator<PlutoRow<dynamic>> iterator = rows.iterator;
    if (!iterator.moveNext() ||
        (!isDouble && !iterator.current.cells.containsKey(field))) {
      return isDouble ? null : 0;
    }

    double result = 0;
    int count = 0;
    do {
      final PlutoCell? cell = iterator.current.cells[field];
      if (filter != null && !filter(cell!)) {
        continue;
      }
      final num? value = isDouble
          ? cell?.valueForSorting as double?
          : cell?.currentValue as num?;
      if (value != null) {
        count += 1;
        // Preserve the incremental mean used by IterableNumberExtension.average.
        result += (value - result) / count;
      }
    } while (iterator.moveNext());

    if (count == 0) {
      return null;
    }
    if (columnType is PlutoColumnTypeWithDoubleFormat) {
      final PlutoColumnTypeWithDoubleFormat doubleColumn =
          columnType as PlutoColumnTypeWithDoubleFormat;
      return doubleColumn.toDouble(doubleColumn.applyFormat(result));
    }
    final PlutoColumnTypeWithNumberFormat numberColumn =
        columnType as PlutoColumnTypeWithNumberFormat;
    return numberColumn.toNumber(numberColumn.applyFormat(result));
  }

  static num? min({
    required Iterable<PlutoRow> rows,
    required PlutoColumn column,
    PlutoAggregateFilter? filter,
  }) {
    if (column.type is! PlutoColumnTypeWithNumberFormat ||
        !_hasColumnField(rows: rows, column: column)) {
      return null;
    }

    final Iterable<PlutoRow<dynamic>> foundItems = filter != null
        ? rows.where(
            (PlutoRow<dynamic> row) => filter(row.cells[column.field]!),
          )
        : rows;

    final Iterable<num> mapValues = foundItems.map(
      (PlutoRow<dynamic> e) => e.cells[column.field]!.currentValue,
    );

    return mapValues.minOrNull;
  }

  static num? max({
    required Iterable<PlutoRow> rows,
    required PlutoColumn column,
    PlutoAggregateFilter? filter,
  }) {
    if (column.type is! PlutoColumnTypeWithNumberFormat ||
        !_hasColumnField(rows: rows, column: column)) {
      return null;
    }

    final Iterable<PlutoRow<dynamic>> foundItems = filter != null
        ? rows.where(
            (PlutoRow<dynamic> row) => filter(row.cells[column.field]!),
          )
        : rows;

    final Iterable<num> mapValues = foundItems.map(
      (PlutoRow<dynamic> e) => e.cells[column.field]!.currentValue,
    );

    return mapValues.maxOrNull;
  }

  static int count({
    required Iterable<PlutoRow> rows,
    required PlutoColumn column,
    PlutoAggregateFilter? filter,
  }) {
    if (filter == null) {
      return _hasColumnField(rows: rows, column: column) ? rows.length : 0;
    }

    final String field = column.field;
    final Iterator<PlutoRow<dynamic>> iterator = rows.iterator;
    if (!iterator.moveNext() || !iterator.current.cells.containsKey(field)) {
      return 0;
    }

    int count = 0;
    do {
      if (filter(iterator.current.cells[field]!)) {
        count += 1;
      }
    } while (iterator.moveNext());

    return count;
  }

  static bool _hasColumnField({
    required Iterable<PlutoRow> rows,
    required PlutoColumn column,
  }) {
    return rows.firstOrNull?.cells.containsKey(column.field) == true;
  }

  static num? uniqueCount({
    required Iterable<PlutoRow> rows,
    required PlutoColumn column,
    PlutoAggregateFilter? filter,
  }) {
    if (!_hasColumnField(rows: rows, column: column)) {
      return 0;
    }

    final Iterable<PlutoRow<dynamic>> foundItems = filter != null
        ? rows.where(
            (PlutoRow<dynamic> row) => filter(row.cells[column.field]!),
          )
        : rows;

    return foundItems
        .map((PlutoRow<dynamic> c) => c.cells[column.field]?.currentValue)
        .toSet()
        .length;
  }
}
