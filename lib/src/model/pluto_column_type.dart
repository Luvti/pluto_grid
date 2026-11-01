// ignore_for_file: avoid_annotating_with_dynamic

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

enum PlutoColumnTypeEnum {
  text,
  bool,
  number,
  currency,
  select,
  date,
  time,
  double,
}

abstract class PlutoColumnType {
  const PlutoColumnType({required this.type});

  dynamic get defaultValue;

  final PlutoColumnTypeEnum type;

  /// Set as a string column.
  factory PlutoColumnType.text({dynamic defaultValue = ''}) {
    return PlutoColumnTypeText(defaultValue: defaultValue);
  }

  /// Set as a bool column.
  factory PlutoColumnType.bool() {
    return const PlutoColumnTypeBool();
  }

  /// Set to numeric column.
  ///
  /// [format]
  /// '#,###' (Comma every three digits)
  /// '#,###.###' (Allow three decimal places)
  ///
  /// [negative] Allow negative numbers
  ///
  /// [applyFormatOnInit] When the editor loads, it resets the value to [format].
  ///
  /// [allowFirstDot] When accepting negative numbers, a dot is allowed at the beginning.
  /// This option is required on devices where the .- symbol works with one button.
  ///
  /// [locale] Specifies the numeric locale of the column.
  /// If not specified, the default locale is used.
  factory PlutoColumnType.number({
    num defaultValue = 0,
    bool negative = true,
    String format = '#,###',
    bool applyFormatOnInit = true,
    bool allowFirstDot = false,
    String? locale,
  }) {
    return PlutoColumnTypeNumber(
      defaultValue: defaultValue,
      format: format,
      negative: negative,
      applyFormatOnInit: applyFormatOnInit,
      allowFirstDot: allowFirstDot,
      locale: locale,
    );
  }

  factory PlutoColumnType.double({
    double defaultValue = 0,
    bool negative = true,
    String format = '###.0#',
    bool applyFormatOnInit = true,
    bool allowFirstDot = false,
    String? locale,
  }) {
    return PlutoColumnTypeDouble(
      defaultValue: defaultValue,
      format: format,
      negative: negative,
      applyFormatOnInit: applyFormatOnInit,
      allowFirstDot: allowFirstDot,
      locale: locale,
    );
  }

  /// Set to currency column.
  ///
  /// [format]
  /// '#,###' (Comma every three digits)
  /// '#,###.###' (Allow three decimal places)
  ///
  /// [negative] Allow negative numbers
  ///
  /// [applyFormatOnInit] When the editor loads, it resets the value to [format].
  ///
  /// [allowFirstDot] When accepting negative numbers, a dot is allowed at the beginning.
  /// This option is required on devices where the .- symbol works with one button.
  ///
  /// [locale] Specifies the currency locale of the column.
  /// If not specified, the default locale is used.
  factory PlutoColumnType.currency({
    dynamic defaultValue = 0,
    bool negative = true,
    String? format,
    bool applyFormatOnInit = true,
    bool allowFirstDot = false,
    String? locale,
    String? name,
    String? symbol,
    int? decimalDigits,
  }) {
    return PlutoColumnTypeCurrency(
      defaultValue: defaultValue,
      format: format,
      negative: negative,
      applyFormatOnInit: applyFormatOnInit,
      allowFirstDot: allowFirstDot,
      locale: locale,
      name: name,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
  }

  /// Provides a selection list and sets it as a selection column.
  ///
  /// If [enableColumnFilter] is true, column filtering is enabled in the selection popup.
  ///
  /// Set the suffixIcon in the [popupIcon] cell. Tapping this icon will open a selection popup.
  /// The default icon is displayed, and if this value is set to null , the icon does not appear.
  factory PlutoColumnType.select(
    List<dynamic> items, {
    Function(PlutoGridOnSelectedEvent event)? onItemSelected,
    dynamic defaultValue = '',
    bool enableColumnFilter = false,
    IconData? popupIcon = Icons.arrow_drop_down,
    Widget Function(dynamic item)? builder,
  }) {
    return PlutoColumnTypeSelect(
      onItemSelected: onItemSelected ?? (event) {},
      defaultValue: defaultValue,
      items: items,
      enableColumnFilter: enableColumnFilter,
      popupIcon: popupIcon,
      builder: builder,
    );
  }

  /// Set as a date column.
  ///
  /// [startDate] Range start date (If there is no value, Can select the date without limit)
  ///
  /// [endDate] Range end date
  ///
  /// [format] 'yyyy-MM-dd' (2020-01-01)
  ///
  /// [headerFormat] 'yyyy-MM' (2020-01)
  /// Display year and month in header in date picker popup.
  ///
  /// [applyFormatOnInit] When the editor loads, it resets the value to [format].
  ///
  /// Set the suffixIcon in the [popupIcon] cell. Tap this icon to open the date selection popup.
  /// The default icon is displayed, and if this value is set to null , the icon does not appear.
  factory PlutoColumnType.date({
    dynamic defaultValue = '',
    DateTime? startDate,
    DateTime? endDate,
    String format = 'yyyy-MM-dd',
    String headerFormat = 'yyyy-MM',
    bool applyFormatOnInit = true,
    IconData? popupIcon = Icons.date_range,
  }) {
    return PlutoColumnTypeDate(
      defaultValue: defaultValue,
      startDate: startDate,
      endDate: endDate,
      format: format,
      headerFormat: headerFormat,
      applyFormatOnInit: applyFormatOnInit,
      popupIcon: popupIcon,
    );
  }

  /// A column for the time type.
  ///
  /// Set the suffixIcon in the [popupIcon] cell. Tap this icon to open the time selection popup.
  /// The default icon is displayed, and if this value is set to null , the icon does not appear.
  factory PlutoColumnType.time({
    dynamic defaultValue = '00:00',
    IconData? popupIcon = Icons.access_time,
  }) {
    return PlutoColumnTypeTime(
      defaultValue: defaultValue,
      popupIcon: popupIcon,
    );
  }

  bool isValid(dynamic value);

  int compare(dynamic a, dynamic b);

  dynamic makeCompareValue(dynamic v);
}

extension PlutoColumnTypeExtension on PlutoColumnType {
  bool get isText => this is PlutoColumnTypeText;

  bool get isNumber => this is PlutoColumnTypeNumber;

  bool get isDouble => this is PlutoColumnTypeDouble;

  bool get isCurrency => this is PlutoColumnTypeCurrency;

  bool get isSelect => this is PlutoColumnTypeSelect;

  bool get isDate => this is PlutoColumnTypeDate;

  bool get isTime => this is PlutoColumnTypeTime;

  PlutoColumnTypeText get text {
    if (this is! PlutoColumnTypeText) {
      throw TypeError();
    }

    return this as PlutoColumnTypeText;
  }

  PlutoColumnTypeNumber get number {
    if (this is! PlutoColumnTypeNumber) {
      throw TypeError();
    }

    return this as PlutoColumnTypeNumber;
  }

  PlutoColumnTypeCurrency get currency {
    if (this is! PlutoColumnTypeCurrency) {
      throw TypeError();
    }

    return this as PlutoColumnTypeCurrency;
  }

  PlutoColumnTypeSelect get select {
    if (this is! PlutoColumnTypeSelect) {
      throw TypeError();
    }

    return this as PlutoColumnTypeSelect;
  }

  PlutoColumnTypeDate get date {
    if (this is! PlutoColumnTypeDate) {
      throw TypeError();
    }

    return this as PlutoColumnTypeDate;
  }

  PlutoColumnTypeTime get time {
    if (this is! PlutoColumnTypeTime) {
      throw TypeError();
    }

    return this as PlutoColumnTypeTime;
  }

  bool get hasFormat => this is PlutoColumnTypeHasFormat;

  bool get applyFormatOnInit =>
      hasFormat ? (this as PlutoColumnTypeHasFormat).applyFormatOnInit : false;

  dynamic applyFormat(dynamic value) =>
      hasFormat ? (this as PlutoColumnTypeHasFormat).applyFormat(value) : value;
}

class PlutoColumnTypeText extends PlutoColumnType {
  @override
  final dynamic defaultValue;

  const PlutoColumnTypeText({
    this.defaultValue,
    super.type = PlutoColumnTypeEnum.text,
  });

  @override
  bool isValid(dynamic value) {
    return value is String || value is num;
  }

  @override
  int compare(dynamic a, dynamic b) {
    return _compareWithNull(a, b, () => a.toString().compareTo(b.toString()));
  }

  @override
  dynamic makeCompareValue(dynamic v) {
    return v.toString();
  }
}

class PlutoColumnTypeBool extends PlutoColumnType {
  @override
  final dynamic defaultValue;

  const PlutoColumnTypeBool({
    this.defaultValue,
    super.type = PlutoColumnTypeEnum.bool,
  });

  @override
  bool isValid(dynamic value) {
    return value is bool? || value is bool;
  }

  @override
  int compare(dynamic a, dynamic b) {
    return _compareWithNull(a, b, () => a.toString().compareTo(b.toString()));
  }

  @override
  dynamic makeCompareValue(dynamic v) {
    return v.toString();
  }
}

class PlutoColumnTypeNumber
    with PlutoColumnTypeWithNumberFormat
    implements PlutoColumnType, PlutoColumnTypeHasFormat<String> {
  @override
  final dynamic defaultValue;

  @override
  final bool negative;

  @override
  final String format;

  @override
  final bool applyFormatOnInit;

  @override
  final bool allowFirstDot;

  @override
  final String? locale;

  @override
  final PlutoColumnTypeEnum type = PlutoColumnTypeEnum.number;

  PlutoColumnTypeNumber({
    this.defaultValue,
    required this.negative,
    required this.format,
    required this.applyFormatOnInit,
    required this.allowFirstDot,
    required this.locale,
  }) : numberFormat = intl.NumberFormat(format, locale),
       decimalPoint = _getDecimalPoint(format);

  @override
  final intl.NumberFormat numberFormat;

  @override
  final int decimalPoint;

  static int _getDecimalPoint(String format) {
    final int dotIndex = format.indexOf('.');

    return dotIndex < 0 ? 0 : format.substring(dotIndex).length - 1;
  }
}

class PlutoColumnTypeDouble
    with PlutoColumnTypeWithDoubleFormat
    implements PlutoColumnType, PlutoColumnTypeHasFormat<String> {
  @override
  final dynamic defaultValue;

  @override
  final bool negative;

  @override
  final String format;

  @override
  final bool applyFormatOnInit;

  @override
  final bool allowFirstDot;

  @override
  final String? locale;

  @override
  final PlutoColumnTypeEnum type = PlutoColumnTypeEnum.double;

  PlutoColumnTypeDouble({
    required this.negative,
    required this.format,
    required this.applyFormatOnInit,
    required this.allowFirstDot,
    required this.locale,
    this.defaultValue,
  }) : numberFormat = intl.NumberFormat(format, locale),
       decimalPoint = _getDecimalPoint(format);

  @override
  final intl.NumberFormat numberFormat;

  @override
  final int decimalPoint;

  static int _getDecimalPoint(String format) {
    final int dotIndex = format.indexOf('.');

    return dotIndex < 0 ? 0 : format.substring(dotIndex).length - 1;
  }
}

class PlutoColumnTypeCurrency
    with PlutoColumnTypeWithNumberFormat
    implements PlutoColumnType, PlutoColumnTypeHasFormat<String?> {
  @override
  final dynamic defaultValue;

  @override
  final bool negative;

  @override
  final bool applyFormatOnInit;

  @override
  final bool allowFirstDot;

  @override
  final String? format;

  @override
  final String? locale;

  final String? name;

  final String? symbol;
  @override
  final PlutoColumnTypeEnum type = PlutoColumnTypeEnum.currency;
  PlutoColumnTypeCurrency({
    this.defaultValue,
    required this.negative,
    required this.format,
    required this.applyFormatOnInit,
    required this.allowFirstDot,
    required this.locale,
    this.name,
    this.symbol,
    int? decimalDigits,
  }) : numberFormat = intl.NumberFormat.currency(
         locale: locale,
         name: name,
         symbol: symbol,
         decimalDigits: decimalDigits,
         customPattern: format,
       ) {
    decimalPoint = numberFormat.decimalDigits ?? defaultValue;
  }

  @override
  final intl.NumberFormat numberFormat;

  @override
  late final int decimalPoint;
}

class PlutoColumnTypeSelect
    implements PlutoColumnType, PlutoColumnTypeHasPopupIcon {
  @override
  final dynamic defaultValue;

  final List<dynamic> items;

  final Widget Function(dynamic item)? builder;

  final bool enableColumnFilter;
  final Function(PlutoGridOnSelectedEvent event) onItemSelected;

  @override
  final PlutoColumnTypeEnum type = PlutoColumnTypeEnum.select;

  @override
  final IconData? popupIcon;

  const PlutoColumnTypeSelect({
    required this.onItemSelected,
    this.defaultValue,
    required this.items,
    required this.enableColumnFilter,
    this.popupIcon,
    this.builder,
  });

  @override
  bool isValid(dynamic value) => items.contains(value) == true;

  @override
  int compare(dynamic a, dynamic b) {
    return _compareWithNull(a, b, () {
      return items.indexOf(a).compareTo(items.indexOf(b));
    });
  }

  @override
  dynamic makeCompareValue(dynamic v) {
    return v;
  }
}

class PlutoColumnTypeDate
    implements
        PlutoColumnType,
        PlutoColumnTypeHasFormat<String>,
        PlutoColumnTypeHasDateFormat,
        PlutoColumnTypeHasPopupIcon {
  @override
  final dynamic defaultValue;

  final DateTime? startDate;

  final DateTime? endDate;

  @override
  final String format;

  @override
  final String headerFormat;

  @override
  final bool applyFormatOnInit;

  @override
  final IconData? popupIcon;

  @override
  final PlutoColumnTypeEnum type = PlutoColumnTypeEnum.date;

  PlutoColumnTypeDate({
    this.defaultValue,
    this.startDate,
    this.endDate,
    required this.format,
    required this.headerFormat,
    required this.applyFormatOnInit,
    this.popupIcon,
  }) : dateFormat = intl.DateFormat(format),
       headerDateFormat = intl.DateFormat(headerFormat);

  @override
  final intl.DateFormat dateFormat;

  @override
  final intl.DateFormat headerDateFormat;

  /// Dates repeat across the rows of a table (seven dates for 10k keywords):
  /// each text is parsed and each date formatted once, and equal cells share
  /// the resulting DateTime and String.
  final _Memo<String, Object> _compareDates = _Memo<String, Object>();
  final _Memo<Object, String> _formattedDates = _Memo<Object, String>();

  @override
  bool isValid(dynamic value) {
    if (value == null) {
      return false;
    }
    if (value is DateTime) {
      return true;
    }

    final DateTime? parsedDate = DateTime.tryParse(value.toString());

    if (parsedDate == null) {
      return false;
    }

    if (startDate != null && parsedDate.isBefore(startDate!)) {
      return false;
    }

    if (endDate != null && parsedDate.isAfter(endDate!)) {
      return false;
    }

    return true;
  }

  @override
  int compare(dynamic a, dynamic b) {
    return _compareWithNull(
      a,
      b,
      // Sort values are dates: compare them without formatting both as text.
      () => a is DateTime && b is DateTime
          ? a.compareTo(b)
          : a.toString().compareTo(b.toString()),
    );
  }

  @override
  dynamic makeCompareValue(dynamic v) {
    if (v is! String) {
      return _compareValue(v);
    }
    final Object? cached = _compareDates[v];
    if (cached != null) {
      return identical(cached, _Memo.none) ? null : cached;
    }
    final DateTime? date = _compareValue(v);
    _compareDates.store(v, date ?? _Memo.none);
    return date;
  }

  DateTime? _compareValue(dynamic v) {
    DateTime? dateFormatValue;

    try {
      if (v == null || v.toString().isEmpty) {
        return null;
      }
      if (v is DateTime) {
        dateFormatValue = v;
      } else {
        dateFormatValue = dateFormat.parse(v.toString());
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      debugPrint(e.toString());
      dateFormatValue = null;
    }

    return dateFormatValue;
  }

  @override
  String applyFormat(dynamic value) {
    if (value is! String && value is! DateTime) {
      return _format(value);
    }
    return _formattedDates[value as Object] ??
        _formattedDates.store(value, _format(value));
  }

  String _format(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '';
    }

    final DateTime? parseValue = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    if (parseValue == null) {
      return '';
    }

    // Parsing the text again gave back the same date.
    return dateFormat.format(parseValue);
  }
}

class PlutoColumnTypeTime
    implements PlutoColumnType, PlutoColumnTypeHasPopupIcon {
  @override
  final dynamic defaultValue;

  @override
  final IconData? popupIcon;

  const PlutoColumnTypeTime({this.defaultValue, this.popupIcon});

  static final RegExp _timeFormat = RegExp(r'^([0-1]?\d|2[0-3]):[0-5]\d$');

  @override
  final PlutoColumnTypeEnum type = PlutoColumnTypeEnum.time;

  @override
  bool isValid(dynamic value) {
    return _timeFormat.hasMatch(value.toString());
  }

  @override
  int compare(dynamic a, dynamic b) {
    return _compareWithNull(a, b, () => a.toString().compareTo(b.toString()));
  }

  @override
  dynamic makeCompareValue(dynamic v) {
    return v;
  }
}

abstract class PlutoColumnTypeHasFormat<T> {
  const PlutoColumnTypeHasFormat({
    required this.format,
    required this.applyFormatOnInit,
  });

  final T format;

  final bool applyFormatOnInit;

  dynamic applyFormat(dynamic value);
}

abstract class PlutoColumnTypeHasDateFormat {
  const PlutoColumnTypeHasDateFormat({
    required this.dateFormat,
    required this.headerFormat,
    required this.headerDateFormat,
  });

  final intl.DateFormat dateFormat;

  final String headerFormat;

  final intl.DateFormat headerDateFormat;
}

abstract class PlutoColumnTypeHasPopupIcon {
  IconData? get popupIcon;
}

mixin PlutoColumnTypeWithNumberFormat {
  intl.NumberFormat get numberFormat;

  /// Table numbers repeat (ranks, counts): each one is formatted and each
  /// formatted text parsed once, and equal cells share the result.
  final _Memo<int, String> _formattedInts = _Memo<int, String>();
  final _Memo<double, String> _formattedDoubles = _Memo<double, String>();
  final _Memo<String, num> _parsedNumbers = _Memo<String, num>();
  final _Memo<int, num> _shownInts = _Memo<int, num>();
  final _Memo<double, num> _shownDoubles = _Memo<double, num>();

  /// [value] as the column shows it: [applyFormat] read back by [toNumber]
  /// (a `#,###` column shows 1.4 as 1).
  num formattedNumber(num value) {
    if (value is int) {
      return _shownInts[value] ??
          _shownInts.store(value, toNumber(applyFormat(value)));
    }
    final double number = value.toDouble();
    if (_Memo.isPlain(number)) {
      return _shownDoubles[number] ??
          _shownDoubles.store(number, toNumber(applyFormat(number)));
    }
    return toNumber(applyFormat(value));
  }

  /// Whether [toNumber] reads [value]'s own text back as [value]: always for an
  /// int, for a double written without an exponent when the decimal separator
  /// is a dot.
  bool readsBackAsItself(num value) => PlutoColumnTypeNumberText.readsBack(
    value,
    numberFormat.symbols.DECIMAL_SEP,
  );

  bool get negative;

  int get decimalPoint;

  bool get allowFirstDot;

  String? get locale;

  dynamic defaultValue;

  bool isValid(dynamic value) {
    if (!isNumeric(value)) {
      return false;
    }

    if (negative == false && num.parse(value.toString()) < 0) {
      return false;
    }

    return true;
  }

  int compare(dynamic a, dynamic b) {
    return _compareWithNull(
      a,
      b,
      () => (a is num ? a : toNumber(a.toString())).compareTo(
        b is num ? b : toNumber(b.toString()),
      ),
    );
  }

  dynamic makeCompareValue(dynamic v) {
    // A number is its own comparison value; parsing its string gives it back.
    if (v is num) {
      return v;
    }
    return num.tryParse(v.toString()) ?? defaultValue;
  }

  String applyFormat(dynamic value) {
    if (value is int) {
      return _formattedInts[value] ??
          _formattedInts.store(value, _formatNumber(value));
    }
    if (value is double && _Memo.isPlain(value)) {
      return _formattedDoubles[value] ??
          _formattedDoubles.store(value, _formatNumber(value));
    }
    return _formatNumber(value);
  }

  String _formatNumber(dynamic value) {
    num? number = value is num
        ? value
        : num.tryParse(
                value.toString().replaceAll(
                  numberFormat.symbols.DECIMAL_SEP,
                  '.',
                ),
              ) ??
              defaultValue;

    if (number != null && negative == false && number < 0) {
      number = defaultValue;
    }
    if (number == null) {
      return '';
    }
    return numberFormat.format(number);
  }

  /// Convert [String] converted to [applyFormat] to [number].
  num toNumber(String? formatted) {
    if (formatted == null || formatted.isEmpty) {
      return defaultValue;
    }
    return _parsedNumbers[formatted] ??
        _parsedNumbers.store(formatted, _parseNumber(formatted));
  }

  num _parseNumber(String formatted) {
    String match = '0-9\\-${numberFormat.symbols.DECIMAL_SEP}';

    if (negative) {
      match += numberFormat.symbols.MINUS_SIGN;
    }

    final RegExp other = _NonNumericPattern.of(match);
    // ignore: parameter_assignments
    formatted =
        (other.hasMatch(formatted)
                ? formatted.replaceAll(other, '')
                : formatted)
            .replaceFirst(numberFormat.symbols.DECIMAL_SEP, '.');

    final num formattedNumber = num.tryParse(formatted) ?? defaultValue;

    return formattedNumber.isFinite ? formattedNumber : defaultValue;
  }

  bool isNumeric(dynamic s) {
    if (s == null) {
      return false;
    }
    if (s is num) {
      return true;
    }
    return num.tryParse(s.toString()) != null;
  }
}

/// Conversion results of one column type by value.
///
/// Holds up to [_maxEntries] values. A column whose values barely repeat
/// would only pay map lookups and inserts, so when a full memo saw few hits
/// the next [_bypassCalls] conversions skip it.
class _Memo<K extends Object, V extends Object> {
  static const int _maxEntries = 1024;
  static const int _minHits = _maxEntries ~/ 4;
  static const int _bypassCalls = _maxEntries * 16;

  /// Stored for a conversion whose result is null.
  static final Object none = Object();

  final Map<K, V> _values = <K, V>{};
  int _hits = 0;
  int _bypass = 0;
  bool _skipStore = false;

  V? operator [](K key) {
    if (_bypass > 0) {
      _bypass--;
      _skipStore = true;
      return null;
    }
    _skipStore = false;
    final V? cached = _values[key];
    if (cached != null) {
      _hits++;
    }
    return cached;
  }

  /// Stores the conversion of the key looked up last and returns it.
  V store(K key, V value) {
    if (_skipStore) {
      return value;
    }
    if (_values.length >= _maxEntries) {
      if (_hits < _minHits) {
        _bypass = _bypassCalls;
      }
      _values.clear();
      _hits = 0;
    }
    return _values[key] = value;
  }

  /// Whether [value] can be a key: NaN equals nothing, and -0.0 equals 0 but
  /// formats differently.
  static bool isPlain(double value) =>
      value.isFinite && !(value == 0 && value.isNegative);
}

/// How number columns read a number's own text (`toString`) back.
class PlutoColumnTypeNumberText {
  /// Whether [value]'s text, read by a number column whose decimal separator
  /// is [decimalSeparator], gives [value] back.
  ///
  /// Number columns drop every character but digits, minus signs and their
  /// decimal separator. An int's text keeps all of them; a double's text does
  /// with a dot separator and without an exponent (1e-6 <= |value| < 1e21).
  static bool readsBack(num value, String decimalSeparator) {
    if (value is int) {
      return true;
    }
    final double number = value.toDouble();
    if (!number.isFinite || decimalSeparator != '.') {
      return false;
    }
    final double magnitude = number.abs();
    return number == 0 || (magnitude >= 1e-6 && magnitude < 1e21);
  }
}

/// Compiled patterns of characters a number column drops before parsing.
///
/// `toNumber` runs for every formatted cell and every compared filter value; a
/// column type has one pattern, so compiling it once per call was the cost.
class _NonNumericPattern {
  static final Map<String, RegExp> _patterns = <String, RegExp>{};

  static RegExp of(String allowed) =>
      _patterns.putIfAbsent(allowed, () => RegExp('[^$allowed]'));
}

int _compareWithNull(dynamic a, dynamic b, int Function() resolve) {
  if (a == null || b == null) {
    return a == b
        ? 0
        : a == null
        ? -1
        : 1;
  }

  return resolve();
}

mixin PlutoColumnTypeWithDoubleFormat {
  intl.NumberFormat get numberFormat;

  /// See [PlutoColumnTypeWithNumberFormat]: repeated values convert once.
  final _Memo<double, String> _formattedDoubles = _Memo<double, String>();
  final _Memo<String, double> _parsedDoubles = _Memo<String, double>();
  final _Memo<double, double> _shownDoubles = _Memo<double, double>();

  /// [value] as the column shows it: [applyFormat] read back by [toDouble].
  double formattedDouble(num value) {
    final double number = value.toDouble();
    if (_Memo.isPlain(number)) {
      return _shownDoubles[number] ??
          _shownDoubles.store(number, toDouble(applyFormat(number)));
    }
    return toDouble(applyFormat(value));
  }

  /// Whether [toDouble] reads [value]'s own text back as [value].
  bool readsBackAsItself(num value) => PlutoColumnTypeNumberText.readsBack(
    value,
    numberFormat.symbols.DECIMAL_SEP,
  );

  bool get negative;

  int get decimalPoint;

  bool get allowFirstDot;

  String? get locale;

  dynamic defaultValue;

  bool isValid(dynamic value) {
    if (!isDouble(value)) {
      return false;
    }

    if (negative == false && double.parse(value.toString()) < 0) {
      return false;
    }

    return true;
  }

  int compare(dynamic a, dynamic b) {
    return _compareWithNull(
      a,
      b,
      () => (a is double ? a : toDouble(a.toString())).compareTo(
        b is double ? b : toDouble(b.toString()),
      ),
    );
  }

  dynamic makeCompareValue(dynamic v) {
    return v.runtimeType != double
        ? double.tryParse(v.toString()) ?? defaultValue
        : v;
  }

  String applyFormat(dynamic value) {
    if (value is num) {
      final double number = value.toDouble();
      if (_Memo.isPlain(number)) {
        return _formattedDoubles[number] ??
            _formattedDoubles.store(number, _formatDouble(number));
      }
    }
    return _formatDouble(value);
  }

  String _formatDouble(dynamic value) {
    double number = value is num
        ? value.toDouble()
        : double.tryParse(
                value.toString().replaceAll(
                  numberFormat.symbols.DECIMAL_SEP,
                  '.',
                ),
              ) ??
              defaultValue;

    if (negative == false && number < 0) {
      number = defaultValue;
    }

    return numberFormat.format(number);
  }

  /// Convert [String] converted to [applyFormat] to [number].
  double toDouble(String formatted) {
    return _parsedDoubles[formatted] ??
        _parsedDoubles.store(formatted, _parseDouble(formatted));
  }

  double _parseDouble(String formatted) {
    String match = '0-9\\-${numberFormat.symbols.DECIMAL_SEP}';

    if (negative) {
      match += numberFormat.symbols.MINUS_SIGN;
    }

    final RegExp other = _NonNumericPattern.of(match);
    // ignore: parameter_assignments
    formatted =
        (other.hasMatch(formatted)
                ? formatted.replaceAll(other, '')
                : formatted)
            .replaceFirst(numberFormat.symbols.DECIMAL_SEP, '.');

    final double formattedNumber = double.tryParse(formatted) ?? defaultValue;

    return formattedNumber.isFinite ? formattedNumber : defaultValue;
  }

  bool isDouble(dynamic s) {
    if (s == null) {
      return false;
    }
    if (s is double) {
      return true;
    }
    return double.tryParse(s.toString()) != null;
  }
}
