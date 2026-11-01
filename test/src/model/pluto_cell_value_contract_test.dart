// Characterization of PlutoCell values by column type, recorded before the
// cell fields were slimmed down. Each expectation shows the runtime type, so a
// change from `int` to `double` or from a raw to a formatted value fails here.
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  for (final _Case c in _Contract.cases) {
    test('${c.type} ${_Contract.describe(c.raw)}', () {
      final PlutoColumn column = PlutoColumn(
        title: '',
        field: 'f',
        type: _Contract.types[c.type]!(),
      );

      // Initialized like the grid and sorted before the cell was rendered.
      final PlutoCell sortedFirst = _Contract.initialized(column, c.raw);
      final String init = _Contract.describe(sortedFirst.currentValue);
      final String sort = _Contract.describe(sortedFirst.valueForSorting);
      final String formatted = _Contract.describe(sortedFirst.valueFormatted);
      final String currentAfter = _Contract.describe(sortedFirst.currentValue);
      final String sortAfter = _Contract.describe(sortedFirst.valueForSorting);

      // Rendered (formatted) before it was sorted.
      final PlutoCell renderedFirst = _Contract.initialized(column, c.raw);
      final String renderedFormatted = _Contract.describe(
        renderedFirst.valueFormatted,
      );
      final String renderedSort = _Contract.describe(
        renderedFirst.valueForSorting,
      );

      // Edited after initialization.
      final Object? raw = c.raw;
      final PlutoCell edited = _Contract.initialized(column, raw)
        ..value = raw is num ? raw * 10 : raw;
      final String editSort = _Contract.describe(edited.valueForSorting);
      final String editFormatted = _Contract.describe(edited.valueFormatted);

      expect(
        <String, String>{
          'init': init,
          'sort': sort,
          'formatted': formatted,
          'currentAfter': currentAfter,
          'sortAfter': sortAfter,
          'renderedFormatted': renderedFormatted,
          'renderedSort': renderedSort,
          'editSort': editSort,
          'editFormatted': editFormatted,
        },
        c.expected,
      );
    });
  }
}

class _Contract {
  static PlutoCell initialized(PlutoColumn column, Object? raw) {
    final PlutoCell cell = PlutoCell(value: raw);
    PlutoGridStateManager.initializeRows(
      <PlutoColumn>[column],
      <PlutoRow<dynamic>>[
        PlutoRow<dynamic>(cells: <String, PlutoCell>{'f': cell}),
      ],
    );
    return cell;
  }

  static String describe(Object? value) =>
      value == null ? 'null' : '${value.runtimeType}($value)';

  static final Map<String, PlutoColumnType Function()> types =
      <String, PlutoColumnType Function()>{
        'text': PlutoColumnType.text,
        'bool': PlutoColumnType.bool,
        'number': PlutoColumnType.number,
        'number #,###.0': () =>
            PlutoColumnType.number(format: '#,###.0', locale: 'en'),
        'number without format on init': () =>
            PlutoColumnType.number(applyFormatOnInit: false),
        'double': PlutoColumnType.double,
        'currency': () => PlutoColumnType.currency(
          locale: 'en_US',
          symbol: r'$',
          decimalDigits: 2,
        ),
        'date': PlutoColumnType.date,
        'date dd.MM.yyyy': () => PlutoColumnType.date(format: 'dd.MM.yyyy'),
        'time': PlutoColumnType.time,
        'select': () => PlutoColumnType.select(<String>['b', 'a', 'c']),
      };

  static Map<String, String> values({
    required String init,
    required String sort,
    required String formatted,
    required String editSort,
    required String editFormatted,
    String? currentAfter,
    String? sortAfter,
    String? renderedFormatted,
    String? renderedSort,
  }) => <String, String>{
    'init': init,
    'sort': sort,
    'formatted': formatted,
    'currentAfter': currentAfter ?? formatted,
    'sortAfter': sortAfter ?? sort,
    'renderedFormatted': renderedFormatted ?? formatted,
    'renderedSort': renderedSort ?? sort,
    'editSort': editSort,
    'editFormatted': editFormatted,
  };

  static final List<_Case> cases = <_Case>[
    _Case(
      'text',
      'b',
      values(
        init: 'String(b)',
        sort: 'String(b)',
        formatted: 'String(b)',
        editSort: 'String(b)',
        editFormatted: 'String(b)',
      ),
    ),
    _Case(
      'text',
      3,
      values(
        init: 'int(3)',
        sort: 'String(3)',
        formatted: 'int(3)',
        editSort: 'String(30)',
        editFormatted: 'int(30)',
      ),
    ),
    _Case(
      'text',
      null,
      values(
        init: 'null',
        sort: 'String(null)',
        formatted: 'null',
        editSort: 'String(null)',
        editFormatted: 'null',
      ),
    ),
    _Case(
      'bool',
      true,
      values(
        init: 'bool(true)',
        sort: 'bool(true)',
        formatted: 'bool(true)',
        editSort: 'bool(true)',
        editFormatted: 'bool(true)',
      ),
    ),
    _Case(
      'bool',
      false,
      values(
        init: 'bool(false)',
        sort: 'bool(false)',
        formatted: 'bool(false)',
        editSort: 'bool(false)',
        editFormatted: 'bool(false)',
      ),
    ),
    _Case(
      'bool',
      null,
      values(
        init: 'null',
        sort: 'String(null)',
        formatted: 'null',
        editSort: 'String(null)',
        editFormatted: 'null',
      ),
    ),
    // Formatting rounds the shown value; sorting keeps the raw number.
    _Case(
      'number',
      1.4,
      values(
        init: 'double(1.4)',
        sort: 'double(1.4)',
        formatted: 'int(1)',
        // Stale: an edited number keeps sorting by its first value.
        editSort: 'double(1.4)',
        editFormatted: 'int(14)',
      ),
    ),
    _Case(
      'number',
      1234,
      values(
        init: 'int(1234)',
        sort: 'int(1234)',
        formatted: 'int(1234)',
        // Stale: an edited number keeps sorting by its first value.
        editSort: 'int(1234)',
        editFormatted: 'int(12340)',
      ),
    ),
    // A string a number column cannot parse becomes 0 when initialized.
    _Case(
      'number',
      '1,234.5',
      values(
        init: 'String(1,234.5)',
        sort: 'int(0)',
        formatted: 'int(0)',
        editSort: 'int(0)',
        editFormatted: 'int(0)',
      ),
    ),
    _Case(
      'number',
      null,
      values(
        init: 'null',
        sort: 'int(0)',
        formatted: 'int(0)',
        editSort: 'int(0)',
        editFormatted: 'int(0)',
      ),
    ),
    _Case(
      'number #,###.0',
      1.44,
      values(
        init: 'double(1.44)',
        sort: 'double(1.44)',
        formatted: 'double(1.4)',
        // Stale: an edited number keeps sorting by its first value.
        editSort: 'double(1.44)',
        editFormatted: 'double(14.4)',
      ),
    ),
    // A string keeps its pre-format comparison value (1234.567, not 1234.6).
    _Case(
      'number #,###.0',
      '1234.567',
      values(
        init: 'String(1234.567)',
        sort: 'double(1234.567)',
        formatted: 'double(1234.6)',
        editSort: 'double(1234.567)',
        editFormatted: 'double(1234.6)',
      ),
    ),
    _Case(
      'number #,###.0',
      7,
      values(
        init: 'int(7)',
        sort: 'int(7)',
        formatted: 'double(7.0)',
        // Stale: an edited number keeps sorting by its first value.
        editSort: 'int(7)',
        editFormatted: 'double(70.0)',
      ),
    ),
    _Case(
      'number #,###.0',
      null,
      values(
        init: 'null',
        sort: 'int(0)',
        formatted: 'double(0.0)',
        editSort: 'int(0)',
        editFormatted: 'double(0.0)',
      ),
    ),
    _Case(
      'number without format on init',
      1.4,
      values(
        init: 'double(1.4)',
        sort: 'double(1.4)',
        formatted: 'double(1.4)',
        // Stale: an edited number keeps sorting by its first value.
        editSort: 'double(1.4)',
        editFormatted: 'double(14.0)',
      ),
    ),
    _Case(
      'number without format on init',
      '12',
      values(
        init: 'String(12)',
        sort: 'int(12)',
        formatted: 'String(12)',
        editSort: 'int(12)',
        editFormatted: 'String(12)',
      ),
    ),
    _Case(
      'number without format on init',
      null,
      values(
        init: 'null',
        sort: 'int(0)',
        formatted: 'null',
        editSort: 'int(0)',
        editFormatted: 'null',
      ),
    ),
    _Case(
      'double',
      1.456,
      values(
        init: 'double(1.456)',
        sort: 'double(1.456)',
        formatted: 'double(1.46)',
        // Stale: an edited number keeps sorting by its first value.
        editSort: 'double(1.456)',
        editFormatted: 'double(14.56)',
      ),
    ),
    // An int in a double column compares as a converted double.
    _Case(
      'double',
      2,
      values(
        init: 'int(2)',
        sort: 'double(2.0)',
        formatted: 'double(2.0)',
        editSort: 'double(20.0)',
        editFormatted: 'double(20.0)',
      ),
    ),
    _Case(
      'double',
      '3.25',
      values(
        init: 'String(3.25)',
        sort: 'double(3.25)',
        formatted: 'double(3.25)',
        editSort: 'double(3.25)',
        editFormatted: 'double(3.25)',
      ),
    ),
    _Case(
      'double',
      null,
      values(
        init: 'null',
        sort: 'double(0.0)',
        formatted: 'double(0.0)',
        editSort: 'double(0.0)',
        editFormatted: 'double(0.0)',
      ),
    ),
    // Currency rounds the shown value; it sorts by the raw number and follows edits.
    _Case(
      'currency',
      12.345,
      values(
        init: 'double(12.345)',
        sort: 'double(12.345)',
        formatted: 'double(12.35)',
        editSort: 'double(123.45)',
        editFormatted: 'double(123.45)',
      ),
    ),
    _Case(
      'currency',
      '7',
      values(
        init: 'String(7)',
        sort: 'int(7)',
        formatted: 'double(7.0)',
        editSort: 'int(7)',
        editFormatted: 'double(7.0)',
      ),
    ),
    _Case(
      'currency',
      null,
      values(
        init: 'null',
        sort: 'int(0)',
        formatted: 'double(0.0)',
        editSort: 'int(0)',
        editFormatted: 'double(0.0)',
      ),
    ),
    _Case(
      'date',
      '2026-01-02',
      values(
        init: 'String(2026-01-02)',
        sort: 'DateTime(2026-01-02 00:00:00.000)',
        formatted: 'String(2026-01-02)',
        editSort: 'DateTime(2026-01-02 00:00:00.000)',
        editFormatted: 'String(2026-01-02)',
      ),
    ),
    // The format cannot read this string, so it shows empty but still sorts by date.
    _Case(
      'date',
      '2026-1-2 10:00:00',
      values(
        init: 'String(2026-1-2 10:00:00)',
        sort: 'DateTime(2026-01-02 00:00:00.000)',
        formatted: 'String()',
        editSort: 'DateTime(2026-01-02 00:00:00.000)',
        editFormatted: 'String()',
      ),
    ),
    _Case(
      'date',
      DateTime(2026, 3, 4),
      values(
        init: 'DateTime(2026-03-04 00:00:00.000)',
        sort: 'DateTime(2026-03-04 00:00:00.000)',
        formatted: 'String(2026-03-04)',
        editSort: 'DateTime(2026-03-04 00:00:00.000)',
        editFormatted: 'String(2026-03-04)',
      ),
    ),
    _Case(
      'date',
      null,
      values(
        init: 'null',
        sort: 'null',
        formatted: 'String()',
        editSort: 'null',
        editFormatted: 'String()',
      ),
    ),
    _Case(
      'date dd.MM.yyyy',
      '2026-01-02',
      values(
        init: 'String(2026-01-02)',
        sort: 'DateTime(2026-01-02 00:00:00.000)',
        formatted: 'String(02.01.2026)',
        editSort: 'DateTime(2026-01-02 00:00:00.000)',
        editFormatted: 'String(02.01.2026)',
      ),
    ),
    _Case(
      'date dd.MM.yyyy',
      '02.01.2026',
      values(
        init: 'String(02.01.2026)',
        sort: 'DateTime(2026-01-02 00:00:00.000)',
        formatted: 'String()',
        editSort: 'DateTime(2026-01-02 00:00:00.000)',
        editFormatted: 'String()',
      ),
    ),
    _Case(
      'date dd.MM.yyyy',
      null,
      values(
        init: 'null',
        sort: 'null',
        formatted: 'String()',
        editSort: 'null',
        editFormatted: 'String()',
      ),
    ),
    _Case(
      'time',
      '09:30',
      values(
        init: 'String(09:30)',
        sort: 'String(09:30)',
        formatted: 'String(09:30)',
        editSort: 'String(09:30)',
        editFormatted: 'String(09:30)',
      ),
    ),
    _Case(
      'time',
      '9:5',
      values(
        init: 'String(9:5)',
        sort: 'String(9:5)',
        formatted: 'String(9:5)',
        editSort: 'String(9:5)',
        editFormatted: 'String(9:5)',
      ),
    ),
    _Case(
      'time',
      null,
      values(
        init: 'null',
        sort: 'null',
        formatted: 'null',
        editSort: 'null',
        editFormatted: 'null',
      ),
    ),
    _Case(
      'select',
      'a',
      values(
        init: 'String(a)',
        sort: 'String(a)',
        formatted: 'String(a)',
        editSort: 'String(a)',
        editFormatted: 'String(a)',
      ),
    ),
    _Case(
      'select',
      'z',
      values(
        init: 'String(z)',
        sort: 'String(z)',
        formatted: 'String(z)',
        editSort: 'String(z)',
        editFormatted: 'String(z)',
      ),
    ),
    _Case(
      'select',
      null,
      values(
        init: 'null',
        sort: 'null',
        formatted: 'null',
        editSort: 'null',
        editFormatted: 'null',
      ),
    ),
  ];
}

class _Case {
  const _Case(this.type, this.raw, this.expected);

  final String type;
  final Object? raw;
  final Map<String, String> expected;
}
