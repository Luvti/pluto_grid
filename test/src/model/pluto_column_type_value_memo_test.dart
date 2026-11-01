import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  test(
    'cells with the same date share one sort value and one formatted text',
    () {
      final PlutoColumn column = PlutoColumn(
        title: 'date',
        field: 'date',
        type: PlutoColumnType.date(format: 'dd.MM.yyyy'),
      );
      final List<PlutoRow<dynamic>> rows = <PlutoRow<dynamic>>[
        for (int index = 0; index < 3; index++)
          PlutoRow<dynamic>(
            cells: <String, PlutoCell>{
              // Equal texts from JSON are separate String objects.
              'date': PlutoCell(
                value: String.fromCharCodes('02.01.2026'.codeUnits),
              ),
            },
          ),
      ];
      PlutoGridStateManager.initializeRows(<PlutoColumn>[column], rows);

      final List<dynamic> sortValues = rows
          .map((PlutoRow<dynamic> row) => row.cells['date']!.valueForSorting)
          .toList();
      expect(sortValues.first, DateTime(2026, 1, 2));
      expect(identical(sortValues[0], sortValues[1]), isTrue);
      expect(identical(sortValues[1], sortValues[2]), isTrue);

      final PlutoColumnTypeDate type = column.type as PlutoColumnTypeDate;
      final String first = type.applyFormat(
        String.fromCharCodes('2026-01-02'.codeUnits),
      );
      final String second = type.applyFormat(
        String.fromCharCodes('2026-01-02'.codeUnits),
      );
      expect(first, '02.01.2026');
      expect(identical(first, second), isTrue);
      expect(type.applyFormat(DateTime(2026, 1, 2)), '02.01.2026');
    },
  );

  test('a date text that cannot be parsed is reported once', () {
    final PlutoColumnTypeDate type =
        PlutoColumnType.date(format: 'dd.MM.yyyy') as PlutoColumnTypeDate;
    final List<String?> messages = <String?>[];
    final DebugPrintCallback previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => messages.add(message);
    try {
      expect(type.makeCompareValue('2026-01-02'), isNull);
      expect(type.makeCompareValue('2026-01-02'), isNull);
    } finally {
      debugPrint = previous;
    }
    expect(messages, hasLength(1));
  });

  test('numbers format the same with and without the memo', () {
    final PlutoColumnTypeNumber type = PlutoColumnType.number(
      format: '#,###.0',
      locale: 'en',
    ) as PlutoColumnTypeNumber;
    final PlutoColumnTypeNumber reference = PlutoColumnType.number(
      format: '#,###.0',
      locale: 'en',
    ) as PlutoColumnTypeNumber;

    // More distinct values than the memo holds, then repeated ones.
    for (int index = 0; index < 20000; index++) {
      expect(
        type.applyFormat(index * 1.25),
        reference.numberFormat.format(index * 1.25),
      );
    }
    for (int index = 0; index < 3000; index++) {
      final int value = index % 200;
      expect(type.applyFormat(value), reference.numberFormat.format(value));
      expect(type.toNumber(type.applyFormat(value)), value);
    }

    // An int and an equal double, and the zero signs, are not mixed up.
    expect(type.applyFormat(2), reference.numberFormat.format(2));
    expect(type.applyFormat(2.0), reference.numberFormat.format(2.0));
    expect(type.applyFormat(0), reference.numberFormat.format(0));
    expect(type.applyFormat(-0.0), reference.numberFormat.format(-0.0));
    expect(type.applyFormat(0), reference.numberFormat.format(0));
    expect(
      type.applyFormat(double.nan),
      reference.numberFormat.format(double.nan),
    );
  });

  test('doubles format the same with and without the memo', () {
    final PlutoColumnTypeDouble type =
        PlutoColumnType.double() as PlutoColumnTypeDouble;
    final PlutoColumnTypeDouble reference =
        PlutoColumnType.double() as PlutoColumnTypeDouble;
    for (int index = 0; index < 5000; index++) {
      final double value = (index % 300) / 7;
      expect(type.applyFormat(value), reference.numberFormat.format(value));
      expect(
        type.applyFormat(index % 300),
        reference.numberFormat.format(index % 300),
      );
      expect(
        type.toDouble(type.applyFormat(value)),
        reference.toDouble(reference.numberFormat.format(value)),
      );
    }
  });
}
