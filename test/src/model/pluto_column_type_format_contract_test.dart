// Characterization of formatting, parsing and comparison by column type,
// recorded before cell values and conversions were optimized. One line per
// column and input: a changed line shows exactly which result moved.
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  String d(Object? value) =>
      value == null ? 'null' : '${value.runtimeType}($value)';
  String safe(Object? Function() f) {
    try {
      return d(f());
    } catch (e) {
      return 'throws ${e.runtimeType}';
    }
  }

  test('formatting and comparison results by column type', () {
    final List<String> actual = <String>[];
    final Map<String, PlutoColumn> columns = {
      'text': PlutoColumn(title: '', field: 'f', type: PlutoColumnType.text()),
      'bool': PlutoColumn(title: '', field: 'f', type: PlutoColumnType.bool()),
      'number': PlutoColumn(
        title: '',
        field: 'f',
        type: PlutoColumnType.number(),
      ),
      'number#,###.0 de': PlutoColumn(
        title: '',
        field: 'f',
        type: PlutoColumnType.number(format: '#,###.0', locale: 'de'),
      ),
      'number!neg': PlutoColumn(
        title: '',
        field: 'f',
        type: PlutoColumnType.number(negative: false),
      ),
      'double': PlutoColumn(
        title: '',
        field: 'f',
        type: PlutoColumnType.double(),
      ),
      'currency': PlutoColumn(
        title: '',
        field: 'f',
        type: PlutoColumnType.currency(
          locale: 'en_US',
          symbol: r'$',
          decimalDigits: 2,
        ),
      ),
      'date dd.MM.yyyy': PlutoColumn(
        title: '',
        field: 'f',
        type: PlutoColumnType.date(format: 'dd.MM.yyyy'),
      ),
      'time': PlutoColumn(title: '', field: 'f', type: PlutoColumnType.time()),
      'select': PlutoColumn(
        title: '',
        field: 'f',
        type: PlutoColumnType.select(['b', 'a', 'c']),
      ),
      'number+formatter': PlutoColumn(
        title: '',
        field: 'f',
        type: PlutoColumnType.number(),
        formatter: (v) => '#$v',
      ),
      'select+formatter': PlutoColumn(
        title: '',
        field: 'f',
        type: PlutoColumnType.select(['b', 'a']),
        formatter: (v) => '[$v]',
      ),
    };
    final Map<String, List<Object?>> inputs = {
      'text': ['b', 3, 1.5, null],
      'bool': [true, 'false', null],
      'number': [1234.5, -3, '1,234.5', '12', 'x', null],
      'number#,###.0 de': [1234.56, '1234,56', '1.234,5', null],
      'number!neg': [-3, 5],
      'double': [1.456, 2, '3.25', 'x', null],
      'currency': [12.345, '-7', '\$1,000.50', null],
      'date dd.MM.yyyy': [
        '2026-01-02',
        '02.01.2026',
        DateTime(2026, 3, 4),
        '',
        null,
      ],
      'time': ['09:30', '9:5', null],
      'select': ['a', 'z', null],
      'number+formatter': [1234.5, null],
      'select+formatter': ['a', null],
    };
    for (final entry in columns.entries) {
      final column = entry.value;
      final type = column.type;
      for (final v in inputs[entry.key]!) {
        final parts = <String>[
          'applyFormat=${safe(() => type.applyFormat(v))}',
          'forType=${safe(() => column.formattedValueForType(v))}',
          'forDisplay=${safe(() => column.formattedValueForDisplay(v))}',
          'inEditing=${safe(() => column.formattedValueForDisplayInEditing(v))}',
          'compareValue=${safe(() => type.makeCompareValue(v))}',
          'isValid=${safe(() => type.isValid(v))}',
          if (type is PlutoColumnTypeWithNumberFormat)
            'toNumber=${safe(() => (type as PlutoColumnTypeWithNumberFormat).toNumber(v?.toString()))}',
          if (type is PlutoColumnTypeWithDoubleFormat)
            'toDouble=${safe(() => (type as PlutoColumnTypeWithDoubleFormat).toDouble(v?.toString() ?? ''))}',
        ];
        actual.add('${entry.key} | ${d(v)} | ${parts.join(' | ')}');
      }
    }
    final pairs = <String, List<List<Object?>>>{
      'text': [
        ['a', 'b'],
        ['b', 'a'],
        ['10', '9'],
        [null, 'a'],
        ['a', null],
        [null, null],
      ],
      'number': [
        [1, 2],
        [2.5, 2.5],
        ['10', 9],
        ['1,000', '999'],
        [null, 1],
      ],
      'double': [
        [1.5, 1.25],
        ['2', 10.0],
      ],
      'currency': [
        ['\$10.00', '\$9.00'],
        [1, 2],
      ],
      'date dd.MM.yyyy': [
        ['02.01.2026', '10.01.2025'],
        [DateTime(2026, 1, 2), DateTime(2025, 1, 10)],
        ['2026-01-02', '2025-01-10'],
      ],
      'time': [
        ['09:30', '10:00'],
        ['9:5', '09:05'],
      ],
      'select': [
        ['b', 'a'],
        ['a', 'c'],
        ['z', 'a'],
      ],
      'bool': [
        [true, false],
        [false, true],
      ],
    };
    for (final entry in pairs.entries) {
      for (final p in entry.value) {
        actual.add(
          'compare ${entry.key} | ${d(p[0])} vs ${d(p[1])} = ${safe(() => columns[entry.key]!.type.compare(p[0], p[1]))}',
        );
      }
    }
    expect(actual, _Expected.lines);
  });
}

class _Expected {
  static const List<String> lines = <String>[
    r'text | String(b) | applyFormat=String(b) | forType=String(b) | forDisplay=String(b) | inEditing=String(b) | compareValue=String(b) | isValid=bool(true)',
    r'text | int(3) | applyFormat=int(3) | forType=String(3) | forDisplay=String(3) | inEditing=String(3) | compareValue=String(3) | isValid=bool(true)',
    r'text | double(1.5) | applyFormat=double(1.5) | forType=String(1.5) | forDisplay=String(1.5) | inEditing=String(1.5) | compareValue=String(1.5) | isValid=bool(true)',
    r'text | null | applyFormat=null | forType=String(null) | forDisplay=String(null) | inEditing=String(null) | compareValue=String(null) | isValid=bool(false)',
    r'bool | bool(true) | applyFormat=bool(true) | forType=String(true) | forDisplay=String(true) | inEditing=String(true) | compareValue=String(true) | isValid=bool(true)',
    r'bool | String(false) | applyFormat=String(false) | forType=String(false) | forDisplay=String(false) | inEditing=String(false) | compareValue=String(false) | isValid=bool(false)',
    r'bool | null | applyFormat=null | forType=String(null) | forDisplay=String(null) | inEditing=String(null) | compareValue=String(null) | isValid=bool(true)',
    r'number | double(1234.5) | applyFormat=String(1,235) | forType=String(1,235) | forDisplay=String(1,235) | inEditing=String(1234.5) | compareValue=double(1234.5) | isValid=bool(true) | toNumber=double(1234.5)',
    r'number | int(-3) | applyFormat=String(-3) | forType=String(-3) | forDisplay=String(-3) | inEditing=String(-3) | compareValue=int(-3) | isValid=bool(true) | toNumber=int(-3)',
    r'number | String(1,234.5) | applyFormat=String(0) | forType=String(0) | forDisplay=String(0) | inEditing=String(1,234.5) | compareValue=int(0) | isValid=bool(false) | toNumber=double(1234.5)',
    r'number | String(12) | applyFormat=String(12) | forType=String(12) | forDisplay=String(12) | inEditing=String(12) | compareValue=int(12) | isValid=bool(true) | toNumber=int(12)',
    r'number | String(x) | applyFormat=String(0) | forType=String(0) | forDisplay=String(0) | inEditing=String(x) | compareValue=int(0) | isValid=bool(false) | toNumber=int(0)',
    r'number | null | applyFormat=String(0) | forType=String(0) | forDisplay=String(0) | inEditing=String(null) | compareValue=int(0) | isValid=bool(false) | toNumber=int(0)',
    r'number#,###.0 de | double(1234.56) | applyFormat=String(1.234,6) | forType=String(1.234,6) | forDisplay=String(1.234,6) | inEditing=String(1234,56) | compareValue=double(1234.56) | isValid=bool(true) | toNumber=int(123456)',
    r'number#,###.0 de | String(1234,56) | applyFormat=String(1.234,6) | forType=String(1.234,6) | forDisplay=String(1.234,6) | inEditing=String(1234,56) | compareValue=int(0) | isValid=bool(false) | toNumber=double(1234.56)',
    r'number#,###.0 de | String(1.234,5) | applyFormat=String(,0) | forType=String(,0) | forDisplay=String(,0) | inEditing=String(1,234,5) | compareValue=int(0) | isValid=bool(false) | toNumber=double(1234.5)',
    r'number#,###.0 de | null | applyFormat=String(,0) | forType=String(,0) | forDisplay=String(,0) | inEditing=String(null) | compareValue=int(0) | isValid=bool(false) | toNumber=int(0)',
    r'number!neg | int(-3) | applyFormat=String(0) | forType=String(0) | forDisplay=String(0) | inEditing=String(-3) | compareValue=int(-3) | isValid=bool(false) | toNumber=int(-3)',
    r'number!neg | int(5) | applyFormat=String(5) | forType=String(5) | forDisplay=String(5) | inEditing=String(5) | compareValue=int(5) | isValid=bool(true) | toNumber=int(5)',
    r'double | double(1.456) | applyFormat=String(1.46) | forType=String(1.46) | forDisplay=String(1.46) | inEditing=String(1.456) | compareValue=double(1.456) | isValid=bool(true) | toDouble=double(1.456)',
    r'double | int(2) | applyFormat=String(2.0) | forType=String(2.0) | forDisplay=String(2.0) | inEditing=String(2) | compareValue=double(2.0) | isValid=bool(true) | toDouble=double(2.0)',
    r'double | String(3.25) | applyFormat=String(3.25) | forType=String(3.25) | forDisplay=String(3.25) | inEditing=String(3.25) | compareValue=double(3.25) | isValid=bool(true) | toDouble=double(3.25)',
    r'double | String(x) | applyFormat=String(.0) | forType=String(.0) | forDisplay=String(.0) | inEditing=String(x) | compareValue=double(0.0) | isValid=bool(false) | toDouble=double(0.0)',
    r'double | null | applyFormat=String(.0) | forType=String(.0) | forDisplay=String(.0) | inEditing=String(null) | compareValue=double(0.0) | isValid=bool(false) | toDouble=double(0.0)',
    r'currency | double(12.345) | applyFormat=String($12.35) | forType=String($12.35) | forDisplay=String($12.35) | inEditing=String(12.345) | compareValue=double(12.345) | isValid=bool(true) | toNumber=double(12.345)',
    r'currency | String(-7) | applyFormat=String(-$7.00) | forType=String(-$7.00) | forDisplay=String(-$7.00) | inEditing=String(-7) | compareValue=int(-7) | isValid=bool(true) | toNumber=int(-7)',
    r'currency | String($1,000.50) | applyFormat=String($0.00) | forType=String($0.00) | forDisplay=String($0.00) | inEditing=String($1,000.50) | compareValue=int(0) | isValid=bool(false) | toNumber=double(1000.5)',
    r'currency | null | applyFormat=String($0.00) | forType=String($0.00) | forDisplay=String($0.00) | inEditing=String(null) | compareValue=int(0) | isValid=bool(false) | toNumber=int(0)',
    r'date dd.MM.yyyy | String(2026-01-02) | applyFormat=String(02.01.2026) | forType=String(2026-01-02) | forDisplay=String(2026-01-02) | inEditing=String(2026-01-02) | compareValue=null | isValid=bool(true)',
    r'date dd.MM.yyyy | String(02.01.2026) | applyFormat=String() | forType=String(02.01.2026) | forDisplay=String(02.01.2026) | inEditing=String(02.01.2026) | compareValue=DateTime(2026-01-02 00:00:00.000) | isValid=bool(false)',
    r'date dd.MM.yyyy | DateTime(2026-03-04 00:00:00.000) | applyFormat=String(04.03.2026) | forType=String(2026-03-04 00:00:00.000) | forDisplay=String(2026-03-04 00:00:00.000) | inEditing=String(2026-03-04 00:00:00.000) | compareValue=DateTime(2026-03-04 00:00:00.000) | isValid=bool(true)',
    r'date dd.MM.yyyy | String() | applyFormat=String() | forType=String() | forDisplay=String() | inEditing=String() | compareValue=null | isValid=bool(false)',
    r'date dd.MM.yyyy | null | applyFormat=String() | forType=String(null) | forDisplay=String(null) | inEditing=String(null) | compareValue=null | isValid=bool(false)',
    r'time | String(09:30) | applyFormat=String(09:30) | forType=String(09:30) | forDisplay=String(09:30) | inEditing=String(09:30) | compareValue=String(09:30) | isValid=bool(true)',
    r'time | String(9:5) | applyFormat=String(9:5) | forType=String(9:5) | forDisplay=String(9:5) | inEditing=String(9:5) | compareValue=String(9:5) | isValid=bool(false)',
    r'time | null | applyFormat=null | forType=String(null) | forDisplay=String(null) | inEditing=String(null) | compareValue=null | isValid=bool(false)',
    r'select | String(a) | applyFormat=String(a) | forType=String(a) | forDisplay=String(a) | inEditing=String(a) | compareValue=String(a) | isValid=bool(true)',
    r'select | String(z) | applyFormat=String(z) | forType=String(z) | forDisplay=String(z) | inEditing=String(z) | compareValue=String(z) | isValid=bool(false)',
    r'select | null | applyFormat=null | forType=String(null) | forDisplay=String(null) | inEditing=String(null) | compareValue=null | isValid=bool(false)',
    r'number+formatter | double(1234.5) | applyFormat=String(1,235) | forType=String(1,235) | forDisplay=String(#1234.5) | inEditing=String(1234.5) | compareValue=double(1234.5) | isValid=bool(true) | toNumber=double(1234.5)',
    r'number+formatter | null | applyFormat=String(0) | forType=String(0) | forDisplay=String(#null) | inEditing=String(null) | compareValue=int(0) | isValid=bool(false) | toNumber=int(0)',
    r'select+formatter | String(a) | applyFormat=String(a) | forType=String(a) | forDisplay=String([a]) | inEditing=String(a) | compareValue=String(a) | isValid=bool(true)',
    r'select+formatter | null | applyFormat=null | forType=String(null) | forDisplay=String([null]) | inEditing=String(null) | compareValue=null | isValid=bool(false)',
    r'compare text | String(a) vs String(b) = int(-1)',
    r'compare text | String(b) vs String(a) = int(1)',
    r'compare text | String(10) vs String(9) = int(-1)',
    r'compare text | null vs String(a) = int(-1)',
    r'compare text | String(a) vs null = int(1)',
    r'compare text | null vs null = int(0)',
    r'compare number | int(1) vs int(2) = int(-1)',
    r'compare number | double(2.5) vs double(2.5) = int(0)',
    r'compare number | String(10) vs int(9) = int(1)',
    r'compare number | String(1,000) vs String(999) = int(1)',
    r'compare number | null vs int(1) = int(-1)',
    r'compare double | double(1.5) vs double(1.25) = int(1)',
    r'compare double | String(2) vs double(10.0) = int(-1)',
    r'compare currency | String($10.00) vs String($9.00) = int(1)',
    r'compare currency | int(1) vs int(2) = int(-1)',
    r'compare date dd.MM.yyyy | String(02.01.2026) vs String(10.01.2025) = int(-1)',
    r'compare date dd.MM.yyyy | DateTime(2026-01-02 00:00:00.000) vs DateTime(2025-01-10 00:00:00.000) = int(1)',
    r'compare date dd.MM.yyyy | String(2026-01-02) vs String(2025-01-10) = int(1)',
    r'compare time | String(09:30) vs String(10:00) = int(-1)',
    r'compare time | String(9:5) vs String(09:05) = int(1)',
    r'compare select | String(b) vs String(a) = int(-1)',
    r'compare select | String(a) vs String(c) = int(-1)',
    r'compare select | String(z) vs String(a) = int(-1)',
    r'compare bool | bool(true) vs bool(false) = int(1)',
    r'compare bool | bool(false) vs bool(true) = int(-1)',
  ];
}
