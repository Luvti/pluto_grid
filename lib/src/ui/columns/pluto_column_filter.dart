import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:pluto_grid_plus/src/ui/ui.dart';

class PlutoColumnFilter extends PlutoStatefulWidget {
  final PlutoGridStateManager stateManager;

  final PlutoColumn column;

  PlutoColumnFilter({
    required this.stateManager,
    required this.column,
    Key? key,
  }) : super(key: key ?? ValueKey<String>('column_filter_${column.key}'));

  @override
  PlutoColumnFilterState createState() => PlutoColumnFilterState();
}

class PlutoColumnFilterState extends PlutoStateWithChange<PlutoColumnFilter> {
  List<PlutoRow> _filterRows = <PlutoRow>[];

  String _text = '';

  String _betweenStart = '';

  String _betweenEnd = '';

  bool _enabled = false;

  late final StreamSubscription _event;

  late final FocusNode _focusNode;

  late final FocusNode _betweenStartFocusNode;

  late final FocusNode _betweenEndFocusNode;

  late final FocusNode _customBuilderFocusNode;

  late final TextEditingController _controller;

  late final TextEditingController _betweenStartController;

  late final TextEditingController _betweenEndController;

  String get _filterValue {
    return _filterRows.isEmpty
        ? ''
        : _filterRows.first.cells[FilterHelper.filterFieldValue]!.value
              .toString();
  }

  List<String> get _betweenValues {
    if (_filterRows.isEmpty) {
      return <String>['', ''];
    }

    final PlutoCell cell =
        _filterRows.first.cells[FilterHelper.filterFieldValue]!;

    return FilterHelper.resolveBetweenValues(
      search: cell.value?.toString(),
      searchObject: cell.filterValue,
    );
  }

  bool get _hasCompositeFilter {
    return _filterRows.length > 1 ||
        stateManager
            .filterRowsByField(FilterHelper.filterFieldAllColumns)
            .isNotEmpty;
  }

  bool get _isBetween => currentFilter is PlutoFilterTypeBetween;

  InputBorder get _border => OutlineInputBorder(
    borderSide: BorderSide(
      color: stateManager.configuration.style.borderColor,
      width: 0,
    ),
    borderRadius: BorderRadius.zero,
  );

  InputBorder get _enabledBorder => OutlineInputBorder(
    borderSide: BorderSide(
      color: stateManager.configuration.style.activatedBorderColor,
      width: 0,
    ),
    borderRadius: BorderRadius.zero,
  );

  InputBorder get _disabledBorder => OutlineInputBorder(
    borderSide: BorderSide(
      color: stateManager.configuration.style.inactivatedBorderColor,
      width: 0,
    ),
    borderRadius: BorderRadius.zero,
  );

  Color get _textFieldColor => _enabled
      ? stateManager.configuration.style.cellColorInEditState
      : stateManager.configuration.style.cellColorInReadOnlyState;

  EdgeInsets get _padding =>
      widget.column.filterPadding ??
      stateManager.configuration.style.defaultColumnFilterPadding;

  @override
  PlutoGridStateManager get stateManager => widget.stateManager;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode(onKeyEvent: _handleOnKey);
    _betweenStartFocusNode = FocusNode(onKeyEvent: _handleOnKey);
    _betweenEndFocusNode = FocusNode(onKeyEvent: _handleOnKey);
    _customBuilderFocusNode = FocusNode(onKeyEvent: _handleOnKey);

    widget.column.setFilterFocusNode(_focusNode);

    _controller = TextEditingController(text: _filterValue);
    _betweenStartController = TextEditingController();
    _betweenEndController = TextEditingController();

    _event = stateManager.eventManager!.listener(_handleFocusFromRows);

    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  @override
  void dispose() {
    unawaited(_event.cancel());

    _controller.dispose();
    _betweenStartController.dispose();
    _betweenEndController.dispose();
    _focusNode.dispose();
    _betweenStartFocusNode.dispose();
    _betweenEndFocusNode.dispose();
    _customBuilderFocusNode.dispose();

    super.dispose();
  }

  @override
  void updateState(PlutoNotifierEvent event) {
    _filterRows = update<List<PlutoRow>>(
      _filterRows,
      stateManager.filterRowsByField(widget.column.field),
      compare: listEquals,
    );

    final bool hasFilterFocus =
        _focusNode.hasPrimaryFocus ||
        _betweenStartFocusNode.hasPrimaryFocus ||
        _betweenEndFocusNode.hasPrimaryFocus;
    _customBuilderFocusNode.hasPrimaryFocus;

    if (hasFilterFocus != true) {
      if (_isBetween) {
        final List<String> values = _betweenValues;

        _betweenStart = update<String>(
          _betweenStart,
          values.isNotEmpty ? values.first : '',
        );

        _betweenEnd = update<String>(
          _betweenEnd,
          values.length > 1 ? values[1] : '',
        );

        if (changed) {
          _betweenStartController.text = _betweenStart;
          _betweenEndController.text = _betweenEnd;
        }
      } else {
        _text = update<String>(_text, _filterValue);

        if (changed) {
          _controller.text = _text;
        }
      }
    }

    _enabled = update<bool>(
      _enabled,
      widget.column.enableFilterMenuItem && !_hasCompositeFilter,
    );

    widget.column.setFilterFocusNode(
      widget.column.filterWidgetBuilder != null
          ? _customBuilderFocusNode
          : _isBetween
          ? _betweenStartFocusNode
          : _focusNode,
    );
  }

  void _moveDown({required bool focusToPreviousCell}) {
    if (!focusToPreviousCell || stateManager.currentCell == null) {
      stateManager.setCurrentCell(
        stateManager.refRows.first.cells[widget.column.field],
        0,
        notify: false,
      );

      stateManager.scrollByDirection(PlutoMoveDirection.down, 0);
    }

    stateManager.setKeepFocus(true, notify: false);
    stateManager.gridFocusNode.requestFocus();
    stateManager.notifyListeners();
  }

  KeyEventResult _handleOnKey(FocusNode node, KeyEvent event) {
    final PlutoKeyManagerEvent keyManager = PlutoKeyManagerEvent(
      focusNode: node,
      event: event,
    );

    if (keyManager.isKeyUpEvent) {
      return KeyEventResult.handled;
    }

    final bool handleMoveDown =
        (keyManager.isDown || keyManager.isEnter || keyManager.isEsc) &&
        stateManager.refRows.isNotEmpty;

    final bool isBetweenEmpty =
        _betweenStartController.text.isEmpty &&
        _betweenEndController.text.isEmpty;

    final bool handleMoveHorizontal =
        keyManager.isTab ||
        ((_isBetween ? isBetweenEmpty : _controller.text.isEmpty) &&
            keyManager.isHorizontal);

    final bool skip =
        !(handleMoveDown || handleMoveHorizontal || keyManager.isF3);

    if (skip) {
      if (keyManager.isUp) {
        return KeyEventResult.handled;
      }

      return stateManager.keyManager!.eventResult.skip(KeyEventResult.ignored);
    }

    if (handleMoveDown) {
      _moveDown(focusToPreviousCell: keyManager.isEsc);
    } else if (handleMoveHorizontal) {
      if (_isBetween && keyManager.isTab && !keyManager.isShiftPressed) {
        if (node == _betweenStartFocusNode) {
          _betweenEndFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }

      if (_isBetween && keyManager.isTab && keyManager.isShiftPressed) {
        if (node == _betweenEndFocusNode) {
          _betweenStartFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }

      stateManager.nextFocusOfColumnFilter(
        widget.column,
        reversed: keyManager.isLeft || keyManager.isShiftPressed,
      );
    } else if (keyManager.isF3) {
      stateManager.showFilterPopup(
        _focusNode.context!,
        calledColumn: widget.column,
        onClosed: () {
          stateManager.setKeepFocus(true, notify: false);
          _focusNode.requestFocus();
        },
      );
    }

    return KeyEventResult.handled;
  }

  void _handleFocusFromRows(PlutoGridEvent plutoEvent) {
    if (!_enabled) {
      return;
    }

    if (plutoEvent is PlutoGridCannotMoveCurrentCellEvent &&
        plutoEvent.direction.isUp) {
      final bool isCurrentColumn =
          widget
              .stateManager
              .refColumns[stateManager.columnIndexesByShowFrozen[plutoEvent
                  .cellPosition
                  .columnIdx!]]
              .key ==
          widget.column.key;

      if (isCurrentColumn) {
        stateManager
          ..clearCurrentCell(notify: false)
          ..setKeepFocus(false);
        _focusNode.requestFocus();
      }
    }
  }

  void _handleOnTap() {
    stateManager.setKeepFocus(false);
  }

  PlutoFilterType? get currentFilter {
    // ignore: always_specify_types
    final List<PlutoRow> filterRow = stateManager.filterColumns;
    final PlutoRow<dynamic>? filterRowValues = filterRow.firstWhereOrNull(
      (PlutoRow<dynamic> c) =>
          c.cells[FilterHelper.filterFieldColumn]?.value == widget.column.field,
    );
    final PlutoFilterType? filterFieldType =
        filterRowValues?.cells[FilterHelper.filterFieldType]?.value ??
        widget.column.defaultFilter;

    return filterFieldType;
  }

  void _handleOnChanged(String changed) {
    stateManager.eventManager!.addEvent(
      PlutoGridChangeColumnFilterEvent(
        column: widget.column,
        filterType: currentFilter ?? widget.column.defaultFilter,
        filterValue: changed,
        filterValueObject: null,
        debounceMilliseconds:
            stateManager.configuration.columnFilter.debounceMilliseconds,
      ),
    );
  }

  void _handleBetweenChanged({required String start, required String end}) {
    final String merged = start.isEmpty && end.isEmpty
        ? ''
        : '${start} ~ ${end}'.trim();

    stateManager.eventManager!.addEvent(
      PlutoGridChangeColumnFilterEvent(
        column: widget.column,
        filterType: currentFilter ?? widget.column.defaultFilter,
        filterValue: merged,
        filterValueObject: <String>[start, end],
        debounceMilliseconds:
            stateManager.configuration.columnFilter.debounceMilliseconds,
      ),
    );
  }

  void _handleOnEditingComplete() {
    // empty for ignore event of OnEditingComplete.
  }

  String get _filterHintText {
    return widget.column.filterHintText ??
        currentFilter?.title ??
        (_enabled ? widget.column.defaultFilter.title : '');
  }

  InputDecoration _betweenDecoration(
    PlutoGridStyleConfig style, {
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      hintStyle:
          style.filterHintTextStyle ??
          TextStyle(color: widget.column.filterHintTextColor),
      fillColor: _textFieldColor,
      border: _border,
      enabledBorder: _border,
      disabledBorder: _disabledBorder,
      focusedBorder: _enabledBorder,
      contentPadding: const EdgeInsets.all(5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PlutoGridStyleConfig style = stateManager.style;

    return SizedBox(
      height: stateManager.columnFilterHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            top: BorderSide(color: style.borderColor),
            end: style.enableColumnBorderVertical
                ? BorderSide(color: style.borderColor)
                : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: _padding,
          child: (widget.column.type is PlutoColumnTypeBool)
              ? _plutoColumnTypeBool()
              : _buildFilterInput(style),
        ),
      ),
    );
  }

  Widget _buildFilterInput(PlutoGridStyleConfig style) {
    final Widget? custom = widget.column.filterWidgetBuilder?.call(
      _customBuilderFocusNode,
      _controller,
      _enabled,
      _handleOnChanged,
      stateManager,
    );

    if (custom != null) {
      return Focus(
        focusNode: _focusNode,
        canRequestFocus: _enabled,
        child: custom,
      );
    }

    if (_isBetween) {
      return Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              focusNode: _betweenStartFocusNode,
              controller: _betweenStartController,
              enabled: _enabled,
              style: style.filterTextStyle,
              onTap: _handleOnTap,
              onChanged: (value) => _handleBetweenChanged(
                start: value,
                end: _betweenEndController.text,
              ),
              onEditingComplete: _handleOnEditingComplete,
              decoration: _betweenDecoration(
                style,
                hintText: stateManager.configuration.localeText.filterFrom,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              focusNode: _betweenEndFocusNode,
              controller: _betweenEndController,
              enabled: _enabled,
              style: style.filterTextStyle,
              onTap: _handleOnTap,
              onChanged: (value) => _handleBetweenChanged(
                start: _betweenStartController.text,
                end: value,
              ),
              onEditingComplete: _handleOnEditingComplete,
              decoration: _betweenDecoration(
                style,
                hintText: stateManager.configuration.localeText.filterTo,
              ),
            ),
          ),
        ],
      );
    }

    return TextField(
      focusNode: _focusNode,
      controller: _controller,
      enabled: _enabled,
      style: style.filterTextStyle,
      onTap: _handleOnTap,
      onChanged: _handleOnChanged,
      onEditingComplete: _handleOnEditingComplete,
      decoration: InputDecoration(
        suffixIcon: widget.column.filterSuffixIcon,
        hintText: _filterHintText,
        filled: true,
        hintStyle:
            style.filterHintTextStyle ??
            TextStyle(color: widget.column.filterHintTextColor),
        fillColor: _textFieldColor,
        border: _border,
        enabledBorder: _border,
        disabledBorder: _disabledBorder,
        focusedBorder: _enabledBorder,
        contentPadding: const EdgeInsets.all(5),
      ),
      onSubmitted: (String value) {
        _handleOnChanged(value);
        FocusScope.of(stateManager.gridFocusNode.context!).unfocus();
      },
    );
  }

  Widget _plutoColumnTypeBool() {
    return Focus(
      focusNode: _focusNode,
      canRequestFocus: _enabled,
      child: Checkbox(
        tristate: true,
        value: _controller.text == 'true'
            ? true
            : _controller.text == 'false'
            ? false
            : null,
        onChanged: (value) => _handleOnChanged(value?.toString() ?? ''),
      ),
    );
  }
}
