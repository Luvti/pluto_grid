import 'package:material_ui/material_ui.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

/// A cell of a [PlutoRow].
///
/// Large grids hold one cell per column of every row, so a cell keeps only
/// seven fields (64 bytes on 64-bit VMs). A cell key and an [onChanged]
/// callback are kept outside the object: only rendered or selected cells get a
/// key, and few cells have a callback.
class PlutoCell {
  PlutoCell({
    dynamic value,
    this.referenceValue,
    this.filterValue,
    Function({dynamic value, dynamic referenceValue})? onChanged,
    Key? key,
  }) : _value = value,
       _valueForSorting = value,
       _flags = _rawSortValueFlag {
    if (key != null) {
      _keys[this] = key;
      _cellsByKey[key] = this;
      _flags |= _keyFlag;
    }
    if (onChanged != null) {
      this.onChanged = onChanged;
    }
  }

  static final Expando<Key> _keys = Expando<Key>('PlutoCell.key');

  /// The cell each key was given to; a key identifies one cell.
  static final Expando<PlutoCell> _cellsByKey = Expando<PlutoCell>(
    'PlutoCell.byKey',
  );

  /// The cell [key] belongs to, when it is a key this cell API created or was
  /// given. Finding its position then needs only the cell's own row.
  static PlutoCell? withKey(Key key) => _cellsByKey[key];

  static final Expando<Function> _onChangedCallbacks = Expando<Function>(
    'PlutoCell.onChanged',
  );

  /// The column formats [_value] once when [valueFormatted] is first read.
  static const int _formatOnInitFlag = 1;

  /// [_valueForSorting] holds the latest raw value: the initial or last
  /// assigned value, before formatting. It is converted for the column only
  /// when the cell is compared.
  static const int _rawSortValueFlag = 2;

  /// [_keys] holds this cell's key.
  static const int _keyFlag = 4;

  /// [_onChangedCallbacks] holds this cell's callback.
  static const int _onChangedFlag = 8;

  /// Bits that describe the cell itself rather than its current column.
  static const int _ownFlags = _keyFlag | _onChangedFlag;

  dynamic _value;

  /// for operation on cell, include custom render and change
  dynamic referenceValue;
  dynamic filterValue;

  /// Either the latest raw value ([_rawSortValueFlag]) or its comparison value
  /// for the current column.
  ///
  /// Formatting may round [_value] (`#,###` shows 1.4 as 1), so sorting reads
  /// this value instead. It survives [clear] and a new [setColumn] when it is a
  /// number or bool, which compare as themselves.
  dynamic _valueForSorting;

  int _flags;

  PlutoColumn? _column;

  PlutoRow? _row;

  /// Called with the new value whenever [value] changes.
  Function({dynamic value, dynamic referenceValue})? get onChanged =>
      (_flags & _onChangedFlag) == 0
      ? null
      : _onChangedCallbacks[this]
            as Function({
              dynamic value,
              dynamic referenceValue,
            })?;

  set onChanged(Function({dynamic value, dynamic referenceValue})? callback) {
    _onChangedCallbacks[this] = callback;
    _flags = callback == null
        ? _flags & ~_onChangedFlag
        : _flags | _onChangedFlag;
  }

  bool get _needToApplyFormatOnInit => (_flags & _formatOnInitFlag) != 0;

  /// Allocate widget identity only when a cell is rendered or selected.
  Key get key {
    if ((_flags & _keyFlag) != 0) {
      return _keys[this]!;
    }
    final Key key = UniqueKey();
    _keys[this] = key;
    _cellsByKey[key] = this;
    _flags |= _keyFlag;
    return key;
  }

  /// Check identity without allocating keys for cells outside the viewport.
  bool hasKey(Key key) => (_flags & _keyFlag) != 0 && _keys[this] == key;

  bool get initialized => _column != null && _row != null;

  PlutoColumn get column {
    _assertUnInitializedCell(_column != null);

    return _column!;
  }

  PlutoRow get row {
    _assertUnInitializedCell(_row != null);

    return _row!;
  }

  dynamic get valueFormatted {
    if (_needToApplyFormatOnInit) {
      _applyFormatOnInit();
    }

    return _value;
  }

  // deprecated
  @Deprecated('Use valueFormatted instead or currentValue')
  dynamic get value {
    if (_needToApplyFormatOnInit) {
      _applyFormatOnInit();
    }

    return _value;
  }

  dynamic get currentValue {
    return _value;
  }

  set value(dynamic changed) {
    if (_value == changed) {
      return;
    }

    _value = changed;

    // Sort by the new raw value, as the initial one: formatting cannot round it.
    _valueForSorting = changed;
    _flags |= _rawSortValueFlag;

    onChanged?.call(value: _value, referenceValue: referenceValue);
  }

  dynamic get valueForSorting {
    if ((_flags & _rawSortValueFlag) == 0 || _column == null) {
      return _valueForSorting;
    }
    final dynamic raw = _valueForSorting;
    dynamic converted = _comparesAsItself(raw)
        ? raw
        : _column!.type.makeCompareValue(raw);
    if (converted == null) {
      // Some values compare only in the column's own format, such as an ISO
      // date in a `dd.MM.yyyy` column: compare the formatted value instead.
      if (_needToApplyFormatOnInit) {
        _applyFormatOnInit();
      }
      converted = _column!.type.makeCompareValue(_value);
    }
    _valueForSorting = converted;
    _flags &= ~_rawSortValueFlag;

    return converted;
  }

  void setColumn(PlutoColumn column) {
    _column = column;
    if (_needToApplyFormatOnInit && !_comparesAsItself(_rawSortValue)) {
      _applyFormatOnInit();
    }
    _restoreRawSortValue();
    _flags =
        (_flags & ~_formatOnInitFlag) |
        (column.type.applyFormatOnInit ? _formatOnInitFlag : 0);
  }

  void setRow(PlutoRow row) {
    _row = row;
  }

  /// Clears references to column and row to help garbage collection
  /// when this cell is removed from the grid.
  void clear() {
    _column = null;
    _row = null;
    _restoreRawSortValue();
    _flags &= _ownFlags | _rawSortValueFlag;
  }

  /// The raw value [_valueForSorting] holds or was converted from.
  dynamic get _rawSortValue => (_flags & _rawSortValueFlag) != 0
      ? _valueForSorting
      : _restorableSortValue;

  dynamic get _restorableSortValue {
    final dynamic converted = _valueForSorting;
    return converted is num || converted is bool ? converted : _value;
  }

  /// Turns a comparison value of the previous column back into a raw value.
  ///
  /// Numbers and bools are kept: they are either the raw value or parsed from
  /// it more precisely than the formatted [_value]. Other comparison values
  /// (strings, dates) are released and rebuilt from [_value].
  void _restoreRawSortValue() {
    if ((_flags & _rawSortValueFlag) != 0) {
      return;
    }
    _valueForSorting = _restorableSortValue;
    _flags |= _rawSortValueFlag;
  }

  /// Whether [raw] is already the comparison value of the current column.
  bool _comparesAsItself(dynamic raw) {
    final PlutoColumn? column = _column;
    if (column == null) {
      return false;
    }

    switch (column.type.type) {
      case PlutoColumnTypeEnum.number:
        return raw is num;
      case PlutoColumnTypeEnum.double:
        return raw is double;
      case PlutoColumnTypeEnum.bool:
        return raw is bool;
      case PlutoColumnTypeEnum.text:
      case PlutoColumnTypeEnum.currency:
      case PlutoColumnTypeEnum.select:
      case PlutoColumnTypeEnum.date:
      case PlutoColumnTypeEnum.time:
        return false;
    }
  }

  void _applyFormatOnInit() {
    if (_column == null) {
      return;
    }
    _value = _column!.type.applyFormat(_value);

    if (_column!.type is PlutoColumnTypeWithNumberFormat) {
      _value = (_column!.type as PlutoColumnTypeWithNumberFormat).toNumber(
        _value,
      );
    }

    if (_column!.type is PlutoColumnTypeWithDoubleFormat) {
      _value = (_column!.type as PlutoColumnTypeWithDoubleFormat).toDouble(
        _value,
      );
    }

    _flags &= ~_formatOnInitFlag;
  }
}

void _assertUnInitializedCell(bool flag) {
  assert(
    flag,
    'PlutoCell is not initialized.'
    'When adding a column or row, if it is not added through PlutoGridStateManager, '
    'PlutoCell does not set the necessary information at runtime.'
    'If you add a column or row through PlutoGridStateManager and this error occurs, '
    'please contact Github issue.',
  );
}
