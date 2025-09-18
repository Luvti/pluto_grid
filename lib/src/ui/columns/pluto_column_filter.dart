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

  bool _enabled = false;

  late final StreamSubscription _event;

  late final FocusNode _focusNode;

  late final TextEditingController _controller;

  String get _filterValue {
    return _filterRows.isEmpty
        ? ''
        : _filterRows.first.cells[FilterHelper.filterFieldValue]!.value
              .toString();
  }

  bool get _hasCompositeFilter {
    return _filterRows.length > 1 ||
        stateManager
            .filterRowsByField(FilterHelper.filterFieldAllColumns)
            .isNotEmpty;
  }

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

    widget.column.setFilterFocusNode(_focusNode);

    _controller = TextEditingController(text: _filterValue);

    _event = stateManager.eventManager!.listener(_handleFocusFromRows);

    updateState(PlutoNotifierEventForceUpdate.instance);
  }

  @override
  void dispose() {
    unawaited(_event.cancel());

    _controller.dispose();

    _focusNode.dispose();

    super.dispose();
  }

  @override
  void updateState(PlutoNotifierEvent event) {
    _filterRows = update<List<PlutoRow>>(
      _filterRows,
      stateManager.filterRowsByField(widget.column.field),
      compare: listEquals,
    );

    if (_focusNode.hasPrimaryFocus != true) {
      _text = update<String>(_text, _filterValue);

      if (changed) {
        _controller.text = _text;
      }
    }

    _enabled = update<bool>(
      _enabled,
      widget.column.enableFilterMenuItem && !_hasCompositeFilter,
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

    final bool handleMoveHorizontal =
        keyManager.isTab ||
        (_controller.text.isEmpty && keyManager.isHorizontal);

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
    // final String? filterValue =
    //     filterRowValues?.cells[FilterHelper.filterFieldValue]?.value;
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

  void _handleOnEditingComplete() {
    // empty for ignore event of OnEditingComplete.
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
              : // Center(child: child),
                widget.column.filterWidgetBuilder?.call(
                      _focusNode,
                      _controller,
                      _enabled,
                      _handleOnChanged,
                      stateManager,
                    ) ??
                    TextField(
                      focusNode: _focusNode,
                      controller: _controller,
                      enabled: _enabled,
                      style: style.filterTextStyle,
                      onTap: _handleOnTap,
                      onChanged: _handleOnChanged,
                      onEditingComplete: _handleOnEditingComplete,
                      decoration: InputDecoration(
                        suffixIcon: widget.column.filterSuffixIcon,
                        hintText:
                            currentFilter?.title ??
                            widget.column.filterHintText ??
                            (_enabled ? widget.column.defaultFilter.title : ''),
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
                        // This gets called when the user taps the "Done" button
                        FocusScope.of(
                          context,
                        ).unfocus(); // This hides the keyboard
                      },
                    ),
        ),
      ),
    );
  }

  Widget _textField(PlutoGridStyleConfig style) {
    return Tooltip(
      message:
          widget.column.filterHintText ??
          (_enabled ? widget.column.defaultFilter.title : ''),
      showDuration: const Duration(milliseconds: 300),
      child: TextField(
        focusNode: _focusNode,
        controller: _controller,
        enabled: _enabled,
        style: style.cellTextStyle,
        onTap: _handleOnTap,
        onChanged: _handleOnChanged,
        onEditingComplete: _handleOnEditingComplete,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(5),
          hintText:
              widget.column.filterHintText ??
              (_enabled ? widget.column.defaultFilter.title : ''),
          hintStyle: TextStyle(color: widget.column.filterHintTextColor),
          filled: true,
          fillColor: _textFieldColor,
          border: _border,
          enabledBorder: _border,
          disabledBorder: _disabledBorder,
          focusedBorder: _enabledBorder,
          suffixIcon: widget.column.filterSuffixIcon,
          suffix: IconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              color: stateManager.configuration.style.filterHeaderIconColor,
              size: stateManager.configuration.style.iconSize,
            ),
            tooltip: stateManager.configuration.localeText.filter,
            onPressed: _handleOnPressedFilter,
          ),
        ),
      ),
    );
  }

  void _handleOnPressedFilter() {
    stateManager.showFilterPopup(context, calledColumn: widget.column);
  }

  Widget _plutoColumnTypeBool() {
    return Checkbox(
      tristate: true,
      value: _controller.text == 'true'
          ? true
          : _controller.text == 'false'
          ? false
          : null,
      onChanged: (value) => _handleOnChanged(value?.toString() ?? ''),
    );
  }
}
