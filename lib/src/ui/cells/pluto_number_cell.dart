import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import 'decimal_input_formatter.dart';
import 'text_cell.dart';

class PlutoNumberCell extends StatefulWidget implements TextCell {
  @override
  final PlutoGridStateManager stateManager;

  @override
  final PlutoCell cell;

  @override
  final PlutoColumn column;

  @override
  final PlutoRow row;

  const PlutoNumberCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    super.key,
  });

  @override
  PlutoNumberCellState createState() => PlutoNumberCellState();
}

class PlutoNumberCellState extends State<PlutoNumberCell>
    with TextCellState<PlutoNumberCell> {
  late final int decimalRange;

  late final bool activatedNegative;

  late final bool allowFirstDot;

  late final String decimalSeparator;

  @override
  late final TextInputType keyboardType;

  @override
  late final List<TextInputFormatter>? inputFormatters;

  @override
  void initState() {
    super.initState();

    final PlutoColumnType columnType = widget.column.type;

    if (columnType is PlutoColumnTypeWithNumberFormat) {
      final PlutoColumnTypeWithNumberFormat numberColumn =
          columnType as PlutoColumnTypeWithNumberFormat;

      decimalRange = numberColumn.decimalPoint;

      activatedNegative = numberColumn.negative;

      allowFirstDot = numberColumn.allowFirstDot;

      decimalSeparator = numberColumn.numberFormat.symbols.DECIMAL_SEP;
    } else if (columnType is PlutoColumnTypeWithDoubleFormat) {
      final PlutoColumnTypeWithDoubleFormat doubleColumn =
          columnType as PlutoColumnTypeWithDoubleFormat;

      decimalRange = doubleColumn.decimalPoint;

      activatedNegative = doubleColumn.negative;

      allowFirstDot = doubleColumn.allowFirstDot;

      decimalSeparator = doubleColumn.numberFormat.symbols.DECIMAL_SEP;
    } else {
      throw TypeError();
    }

    inputFormatters = [
      DecimalTextInputFormatter(
        decimalRange: decimalRange,
        activatedNegativeValues: activatedNegative,
        allowFirstDot: allowFirstDot,
        decimalSeparator: decimalSeparator,
      ),
    ];

    keyboardType = TextInputType.numberWithOptions(
      decimal: decimalRange > 0,
      signed: activatedNegative,
    );
  }
}
