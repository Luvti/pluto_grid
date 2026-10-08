import 'package:material_ui/material_ui.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

class PlutoCell {
  PlutoCell({
    dynamic value,
    this.referenceValue,
    this.filterValue,
    this.onChanged,
    Key? key,
  }) : _key = key,
       _value = value,
       _originalValue = value;

  Key? _key;

  static const int _formatOnInitFlag = 1;
  static const int _pendingSortValueFlag = 2;

  dynamic _value;

  /// for operation on cell, include custom render and change
  dynamic referenceValue;
  dynamic filterValue;

  ///
  Function({dynamic value, dynamic referenceValue})? onChanged;
  final dynamic _originalValue;

  dynamic _valueForSorting;

  /// Deferred initial formatting and comparison conversion flags.
  ///
  /// Sharing one field keeps cell instances the same size. [setColumn] enables
  /// initial formatting according to the column setting. [valueFormatted]
  /// applies it once; [valueForSorting] separately converts the captured
  /// initial value only when comparison is requested.
  int _flags = 0;

  bool get _needToApplyFormatOnInit => (_flags & _formatOnInitFlag) != 0;

  PlutoColumn? _column;

  PlutoRow? _row;

  /// Allocate widget identity only when a cell is rendered or selected.
  Key get key => _key ??= UniqueKey();

  /// Check identity without allocating keys for cells outside the viewport.
  bool hasKey(Key key) => _key == key;

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
    // if (canUseOriginalValueForSorting) {
    //   return _originalValue;
    // }

    if (_needToApplyFormatOnInit) {
      _applyFormatOnInit();
    }

    return _value;
  }

  // deprecated
  @Deprecated('Use valueFormatted instead or currentValue')
  dynamic get value {
    // if (canUseOriginalValueForSorting) {
    //   return _originalValue;
    // }

    if (_needToApplyFormatOnInit) {
      _applyFormatOnInit();
    }

    return _value;
  }

  @Deprecated('Use currentValue instead')
  dynamic get originalValue {
    return _originalValue;
  }

  dynamic get currentValue {
    return _value;
  }

  set value(dynamic changed) {
    if (_value == changed) {
      return;
    }

    _value = changed;

    _valueForSorting = null;
    _flags &= ~_pendingSortValueFlag;

    onChanged?.call(value: _value, referenceValue: referenceValue);
  }

  dynamic get valueForSorting {
    if ((_flags & _pendingSortValueFlag) != 0) {
      // Preserve the value at setColumn time, even if formatting has since
      // changed _value. Only sorted columns need the converted value.
      _valueForSorting = canUseOriginalValueForSorting
          ? _originalValue
          : _column!.type.makeCompareValue(_valueForSorting);
      _flags &= ~_pendingSortValueFlag;
    }
    _valueForSorting ??= _getValueForSorting();

    return _valueForSorting;
  }

  void setColumn(PlutoColumn column) {
    _column = column;
    if (_needToApplyFormatOnInit && !canUseOriginalValueForSorting) {
      _applyFormatOnInit();
    }
    _valueForSorting = _value;
    _flags =
        _pendingSortValueFlag |
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
    _valueForSorting = null;
    _flags = 0;
  }

  dynamic _getValueForSorting() {
    if (_column == null) {
      return _value;
    }

    if (canUseOriginalValueForSorting) {
      return _originalValue;
    }

    if (_needToApplyFormatOnInit) {
      _applyFormatOnInit();
    }

    return _column!.type.makeCompareValue(_value);
  }

  bool get canUseOriginalValueForSorting {
    if (_column == null) {
      return false;
    }

    if (column.type.type == PlutoColumnTypeEnum.number &&
        _originalValue is num) {
      return true;
    }

    if (column.type.type == PlutoColumnTypeEnum.double &&
        _originalValue is double) {
      return true;
    }

    if (column.type.type == PlutoColumnTypeEnum.bool &&
        _originalValue is bool) {
      return true;
    }

    return false;
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
