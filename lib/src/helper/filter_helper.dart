// ignore_for_file: prefer_asserts_with_message, avoid_annotating_with_dynamic

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

typedef SetFilterPopupHandler =
    void Function(PlutoGridStateManager? stateManager);

class FilterHelper {
  /// A value to identify all column searches when searching filters.
  static const String filterFieldAllColumns = 'plutoFilterAllColumns';

  /// The field name of the column that includes the field values of the column
  /// when searching for a filter.
  static const String filterFieldColumn = 'column';

  /// The field name of the column including the filter type
  /// when searching for a filter.
  static const String filterFieldType = 'type';

  /// The field name of the column containing the value to be searched
  /// when searching for a filter.
  static const String filterFieldValue = 'value';

  static const List<PlutoFilterType> defaultStringFilters = <PlutoFilterType>[
    PlutoFilterTypeContains(),
    PlutoFilterTypeNotContains(),
    PlutoFilterTypeEquals(),
    PlutoFilterTypeNotEquals(),
    PlutoFilterTypeStartsWith(),
    PlutoFilterTypeEndsWith(),
    PlutoFilterTypeIsEmpty(),
    PlutoFilterTypeIsNotEmpty(),
  ];

  static const List<PlutoFilterType> defaultNumbersFilters = <PlutoFilterType>[
    PlutoFilterTypeGreaterThan(),
    PlutoFilterTypeGreaterThanOrEqualTo(),
    PlutoFilterTypeLessThan(),
    PlutoFilterTypeLessThanOrEqualTo(),
    PlutoFilterTypeBetween(),
    PlutoFilterTypeIsEmpty(),
    PlutoFilterTypeIsNotEmpty(),
  ];

  static const List<PlutoFilterType> defaultDatesFilters = <PlutoFilterType>[
    PlutoFilterTypeGreaterThan(),
    PlutoFilterTypeGreaterThanOrEqualTo(),
    PlutoFilterTypeLessThan(),
    PlutoFilterTypeLessThanOrEqualTo(),
    PlutoFilterTypeBetween(),
    PlutoFilterTypeIsEmpty(),
    PlutoFilterTypeIsNotEmpty(),
  ];

  static const List<PlutoFilterType> defaultSetFilters = <PlutoFilterType>[
    PlutoFilterTypeContainsSet(),
    PlutoFilterTypeNotContainsSet(),
    PlutoFilterTypeIsEmptySet(),
    PlutoFilterTypeIsNotEmptySet(),
  ];

  static const List<PlutoFilterType> defaultBoolFilters = <PlutoFilterType>[
    PlutoFilterTypeEquals(),
    PlutoFilterTypeNotEquals(),
    PlutoFilterTypeIsEmpty(),
    PlutoFilterTypeIsNotEmpty(),
  ];

  /// Create a row to contain filter information.
  static PlutoRow createFilterRow({
    String? columnField,
    PlutoFilterType? filterType,
    String? filterValue,
    dynamic filterValueObject,
  }) {
    return PlutoRow(
      cells: <String, PlutoCell>{
        filterFieldColumn: PlutoCell(
          value: columnField ?? filterFieldAllColumns,
        ),
        filterFieldType: PlutoCell(
          value: filterType ?? const PlutoFilterTypeContains(),
        ),
        filterFieldValue: PlutoCell(
          value: filterValue ?? '',
          filterValue: filterValueObject,
        ),
      },
    );
  }

  /// Converts rows containing filter information into comparison functions.
  static FilteredListFilter<PlutoRow?>? convertRowsToFilter(
    List<PlutoRow?> rows,
    List<PlutoColumn>? enabledFilterColumns,
  ) {
    if (rows.isEmpty) {
      return null;
    }

    final Map<String, PlutoColumn> capturedColumns = {
      if (enabledFilterColumns != null)
        for (final PlutoColumn element in enabledFilterColumns)
          element.field: PlutoColumn(
            title: element.title,
            field: element.field,
            type: element.type,
            formatter: element.formatter,
          ),
    };

    return (PlutoRow? row) {
      bool? flag;
      if (row == null) {
        return false;
      }
      for (final PlutoRow? e in rows) {
        if (e == null) {
          continue;
        }
        final PlutoCell? cellValue = e.cells[filterFieldType];
        if (cellValue == null) {
          continue;
        }
        final PlutoFilterType? filterType =
            cellValue.currentValue as PlutoFilterType?;
        if (filterType == null) {
          continue;
        }
        if (e.cells[filterFieldColumn]!.currentValue == filterFieldAllColumns) {
          bool? flagAllColumns;

          row.cells.forEach((String key, PlutoCell value) {
            final PlutoColumn? foundColumn = capturedColumns[key];

            if (foundColumn != null) {
              flagAllColumns = compareOr(
                flagAllColumns,
                compareByFilterType(
                  filterType: filterType,
                  base: value.currentValue?.toString(),
                  baseObject: value.filterValue,
                  search:
                      e.cells[filterFieldValue]?.currentValue?.toString() ?? '',
                  searchObject: e.cells[filterFieldValue]?.filterValue,
                  column: foundColumn,
                ),
              );
            }
          });

          flag = compareAnd(flag, flagAllColumns);
        } else {
          final PlutoColumn? foundColumn =
              capturedColumns[e.cells[filterFieldColumn]?.currentValue];

          if (foundColumn != null) {
            flag = compareAnd(
              flag,
              compareByFilterType(
                filterType: filterType,
                base:
                    row
                        .cells[e.cells[filterFieldColumn]?.currentValue]
                        ?.currentValue
                        ?.toString() ??
                    '',
                baseObject: row
                    .cells[e.cells[filterFieldColumn]?.currentValue]
                    ?.filterValue,
                search:
                    e.cells[filterFieldValue]?.currentValue?.toString() ?? '',
                searchObject: e.cells[filterFieldValue]?.filterValue,
                column: foundColumn,
              ),
            );
          }
        }
      }

      return flag ?? false;
    };
  }

  /// Converts List&lt;PlutoRow&gt; type with filtering information to Map type.
  ///
  /// [allField] determines the key value of the filter applied to the entire scope.
  /// Default is all.
  ///
  /// ```dart
  /// // The return value below is an example of the condition
  /// in which two filtering is applied with the Contains type condition to all ranges.
  /// {all: [{Contains: abc}, {Contains: 123}]}
  ///
  /// // If filtering is applied to a column, the key is the field name of the column.
  /// {column1: [{Contains: abc}]}
  /// ```
  static Map<String, List<Map<String, String>>> convertRowsToMap(
    List<PlutoRow> filterRows, {
    String allField = 'all',
  }) {
    final Map<String, List<Map<String, String>>> map =
        <String, List<Map<String, String>>>{};

    if (filterRows.isEmpty) {
      return map;
    }

    for (final PlutoRow row in filterRows) {
      String columnField =
          row.cells[FilterHelper.filterFieldColumn]!.currentValue;

      if (columnField == FilterHelper.filterFieldAllColumns) {
        columnField = allField;
      }

      final String filterType =
          (row.cells[FilterHelper.filterFieldType]!.currentValue
                  as PlutoFilterType)
              .title;

      final filterValue =
          row.cells[FilterHelper.filterFieldValue]!.currentValue;

      if (map.containsKey(columnField)) {
        map[columnField]!.add(<String, String>{filterType: filterValue});
      } else {
        map[columnField] = <Map<String, String>>[
          <String, String>{filterType: filterValue},
        ];
      }
    }

    return map;
  }

  /// Whether [column] is included in [filteredRows].
  ///
  /// That is, check if it is a filtered column.
  /// If there is a search condition for all columns in [filteredRows],
  /// it is regarded as a filtering column.
  static bool isFilteredColumn(
    PlutoColumn column,
    List<PlutoRow?>? filteredRows,
  ) {
    if (filteredRows == null || filteredRows.isEmpty) {
      return false;
    }

    for (PlutoRow? row in filteredRows) {
      if (row!.cells[filterFieldColumn]!.currentValue ==
              filterFieldAllColumns ||
          row.cells[filterFieldColumn]!.currentValue == column.field) {
        return true;
      }
    }

    return false;
  }

  /// Opens a pop-up for filtering.
  static void filterPopup(FilterPopupState popupState) {
    PlutoGridPopup(
      width: popupState.width,
      height: popupState.height,
      context: popupState.context,
      createHeader: popupState.createHeader,
      columns: popupState.makeColumns(),
      rows: popupState.filterRows,
      configuration: popupState.configuration,
      onLoaded: popupState.onLoaded,
      onChanged: popupState.onChanged,
      onSelected: popupState.onSelected,
      mode: PlutoGridMode.popup,
    );
  }

  /// 'or' comparison with null values
  static bool compareOr(bool? a, bool b) {
    return a != true ? a == true || b : true;
  }

  /// 'and' comparison with null values
  static bool? compareAnd(bool? a, bool? b) {
    return a != false ? b : false;
  }

  /// Compare [base] and [search] with [PlutoFilterType.compare].
  static bool compareByFilterType({
    required PlutoFilterType filterType,
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String search,
    required PlutoColumn column,
  }) {
    bool compare = false;

    if (column.type is PlutoColumnTypeWithNumberFormat) {
      final PlutoColumnTypeWithNumberFormat numberColumn =
          column.type as PlutoColumnTypeWithNumberFormat;

      compare =
          compare ||
          filterType.compare(
            base: numberColumn.applyFormat(base),
            search: search,
            searchObject: searchObject,
            baseObject: baseObject,
            column: column,
          );

      search = search.replaceFirst(
        numberColumn.numberFormat.symbols.DECIMAL_SEP,
        '.',
      );
    }

    return compare ||
        filterType.compare(
          base: base,
          baseObject: baseObject,
          search: search,
          searchObject: searchObject,
          column: column,
        );
  }

  /// Whether [search] is contains in [base].
  static bool compareContains({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    return _compareWithRegExp(RegExp.escape(search!), base!);
  }

  /// Whether [search] is not contains in [base].
  static bool compareNotContains({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    return !_compareWithRegExp(RegExp.escape(search!), base!);
  }

  static bool compareContainsSet({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    final Set<String>? searchSet = _resolveSearchSet(
      searchObject: searchObject,
      search: search,
    );

    if (searchSet == null || searchSet.isEmpty) {
      return true;
    }

    return _setContainsAny(
          baseObject: baseObject,
          searchSet: searchSet,
        ) ??
        true;
  }

  static bool compareNotContainsSet({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    final Set<String>? searchSet = _resolveSearchSet(
      searchObject: searchObject,
      search: search,
    );

    if (searchSet == null || searchSet.isEmpty) {
      return true;
    }

    final bool? containsAny = _setContainsAny(
      baseObject: baseObject,
      searchSet: searchSet,
    );

    if (containsAny == null) {
      return true;
    }

    return !containsAny;
  }

  static Set<String>? _resolveSearchSet({
    required dynamic searchObject,
    required String? search,
  }) {
    Set<String>? searchSet;

    if (searchObject is Set<String>) {
      searchSet = searchObject;
    } else if (searchObject is Set<String?>) {
      searchSet = searchObject.whereType<String>().toSet();
    }

    if (searchSet == null && search != null && search.isNotEmpty) {
      searchSet = search
          .split(RegExp('[;,]'))
          .map((String e) => e.trim().replaceAll('{', '').replaceAll('}', ''))
          .where((String e) => e.isNotEmpty)
          .toSet();

      if (searchSet.isEmpty) {
        searchSet = <String>{search};
      }
    }

    return searchSet;
  }

  static bool? _setContainsAny({
    required dynamic baseObject,
    required Set<String> searchSet,
  }) {
    if (baseObject is Set<String>) {
      return baseObject.any((String e) => searchSet.contains(e));
    }

    if (baseObject is Set<String?>) {
      return baseObject.any((String? e) => e != null && searchSet.contains(e));
    }

    return null;
  }

  static bool compareIsEmptySet({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    if (baseObject != null && baseObject is Set) {
      return baseObject.isEmpty;
    }
    return base == null || base.isEmpty;
  }

  static bool compareIsNotEmptySet({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    if (baseObject != null && baseObject is Set) {
      return baseObject.isNotEmpty;
    }
    return base != null && base.isNotEmpty;
  }

  /// Whether [search] is equals to [base].
  static bool compareEquals({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    return _compareWithRegExp(
      // ignore: prefer_interpolation_to_compose_strings
      r'^' + RegExp.escape(search!) + r'$',
      base!,
    );
  }

  /// Whether [search] is not equals to [base].
  static bool compareNotEquals({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    return !_compareWithRegExp(
      // ignore: prefer_interpolation_to_compose_strings
      r'^' + RegExp.escape(search!) + r'$',
      base!,
    );
  }

  /// Whether [base] starts with [search].
  static bool compareStartsWith({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    return _compareWithRegExp(
      // ignore: prefer_interpolation_to_compose_strings
      r'^' + RegExp.escape(search!),
      base!,
    );
  }

  /// Whether [base] ends with [search].
  static bool compareEndsWith({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    return _compareWithRegExp(
      // ignore: prefer_interpolation_to_compose_strings
      RegExp.escape(search!) + r'$',
      base!,
    );
  }

  static bool compareGreaterThan({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    return column.type.compare(base, search) == 1;
  }

  static bool compareGreaterThanOrEqualTo({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    return column.type.compare(base, search) > -1;
  }

  static bool compareLessThan({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    return column.type.compare(base, search) == -1;
  }

  static bool compareLessThanOrEqualTo({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    return column.type.compare(base, search) < 1;
  }

  static bool compareBetween({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    if (base == null || base.isEmpty) {
      return false;
    }

    final List<String> values = resolveBetweenValues(
      search: search,
      searchObject: searchObject,
    );

    if (values.isEmpty) {
      return true;
    }

    final String start = values.first;
    final String end = values.length > 1 ? values[1] : '';

    if (start.isNotEmpty && column.type.compare(base, start) < 0) {
      return false;
    }

    if (end.isNotEmpty && column.type.compare(base, end) > 0) {
      return false;
    }

    return true;
  }

  static bool _compareWithRegExp(
    String pattern,
    String value, {
    bool caseSensitive = false,
  }) {
    return RegExp(pattern, caseSensitive: caseSensitive).hasMatch(value);
  }

  static bool compareIsEmpty({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    return base == null || base.isEmpty;
  }

  static bool compareIsNotEmpty({
    required dynamic baseObject,
    required String? base,
    required dynamic searchObject,
    required String? search,
    required PlutoColumn column,
  }) {
    return base != null && base.isNotEmpty;
  }

  static List<String> resolveBetweenValues({
    required String? search,
    required dynamic searchObject,
  }) {
    if (searchObject is List<String>) {
      if (searchObject.isEmpty) {
        return <String>[];
      }

      return searchObject;
    }

    if (searchObject is List) {
      return searchObject
          .map((dynamic value) => value?.toString() ?? '')
          .toList(growable: false);
    }

    if (search == null || search.isEmpty) {
      return <String>[];
    }

    final List<String> parts = search
        .split(RegExp(r'\s*(?:\.\.|~|;|,)\s*'))
        .map((String value) => value.trim())
        .toList(growable: false);

    if (parts.isEmpty) {
      return <String>[];
    }

    if (parts.length == 1) {
      return <String>[parts.first, ''];
    }

    return <String>[parts[0], parts[1]];
  }

  static List<PlutoFilterType> defaultFilter({
    required PlutoColumnTypeEnum type,
  }) {
    switch (type) {
      case PlutoColumnTypeEnum.text:
        return defaultStringFilters;
      case PlutoColumnTypeEnum.time:
      case PlutoColumnTypeEnum.date:
        return defaultDatesFilters;
      case PlutoColumnTypeEnum.currency:
      case PlutoColumnTypeEnum.number:
      case PlutoColumnTypeEnum.double:
        return defaultNumbersFilters;
      case PlutoColumnTypeEnum.select:
        return defaultStringFilters;
      case PlutoColumnTypeEnum.bool:
        return defaultBoolFilters;
    }
  }
}

/// State for calling filter pop
class FilterPopupState {
  /// [BuildContext] for calling [showDialog]
  final BuildContext context;

  /// [PlutoGridConfiguration] to call [PlutoGridPopup]
  final PlutoGridConfiguration configuration;

  /// A callback function called when adding a new filter.
  final SetFilterPopupHandler handleAddNewFilter;

  /// A callback function called when filter information changes.
  final SetFilterPopupHandler handleApplyFilter;

  /// List of columns to be filtered.
  final List<PlutoColumn> columns;

  /// List with filtering condition information
  final List<PlutoRow> filterRows;

  /// The filter popup opens and focuses on the filter value in the first row.
  final bool focusFirstFilterValue;

  /// Width of filter popup
  final double width;

  /// Height of filter popup
  final double height;

  final void Function()? onClosed;

  FilterPopupState({
    required this.context,
    required this.configuration,
    required this.handleAddNewFilter,
    required this.handleApplyFilter,
    required this.columns,
    required this.filterRows,
    required this.focusFirstFilterValue,
    this.width = 600,
    this.height = 450,
    this.onClosed,
  }) : assert(columns.isNotEmpty),
       _previousFilterRows = <PlutoRow?>[...filterRows];

  PlutoGridStateManager? _stateManager;
  List<PlutoRow?> _previousFilterRows;

  void onLoaded(PlutoGridOnLoadedEvent e) {
    _stateManager = e.stateManager;

    _stateManager!.setSelectingMode(PlutoGridSelectingMode.row, notify: false);

    if (_stateManager!.rows.isNotEmpty) {
      _stateManager!.setKeepFocus(true, notify: false);

      _stateManager!.setCurrentCell(
        _stateManager!.rows.first.cells[FilterHelper.filterFieldValue],
        0,
        notify: false,
      );

      if (focusFirstFilterValue) {
        _stateManager!.setEditing(true, notify: false);
      }
    }

    _stateManager!.notifyListeners();

    _stateManager!.addListener(stateListener);
  }

  void onChanged(PlutoGridOnChangedEvent e) {
    applyFilter();
  }

  void onSelected(PlutoGridOnSelectedEvent e) {
    _stateManager!.removeListener(stateListener);

    if (onClosed != null) {
      onClosed!();
    }
  }

  void stateListener() {
    if (listEquals(_previousFilterRows, _stateManager!.rows) == false) {
      _previousFilterRows = <PlutoRow?>[..._stateManager!.rows];
      applyFilter();
    }
  }

  void applyFilter() {
    handleApplyFilter(_stateManager);
  }

  PlutoGridFilterPopupHeader createHeader(PlutoGridStateManager stateManager) {
    return PlutoGridFilterPopupHeader(
      stateManager: stateManager,
      configuration: configuration,
      handleAddNewFilter: handleAddNewFilter,
    );
  }

  List<PlutoColumn> makeColumns() {
    return _makeFilterColumns(configuration: configuration, columns: columns);
  }

  Map<String, String> _makeFilterColumnMap({
    required PlutoGridConfiguration configuration,
    required List<PlutoColumn> columns,
  }) {
    final Map<String, String> columnMap = <String, String>{
      FilterHelper.filterFieldAllColumns:
          configuration.localeText.filterAllColumns,
    };

    columns
        .where((PlutoColumn element) => element.enableFilterMenuItem)
        .forEach((PlutoColumn element) {
          columnMap[element.field] = element.titleWithGroup;
        });

    return columnMap;
  }

  List<PlutoColumn> _makeFilterColumns({
    required PlutoGridConfiguration configuration,
    required List<PlutoColumn> columns,
  }) {
    final Map<String, String> columnMap = _makeFilterColumnMap(
      configuration: configuration,
      columns: columns,
    );

    return <PlutoColumn>[
      PlutoColumn(
        title: configuration.localeText.filterColumn.toUpperCase(),
        field: FilterHelper.filterFieldColumn,
        type: PlutoColumnType.select(columnMap.keys.toList(growable: false)),
        enableFilterMenuItem: false,
        applyFormatterInEditing: true,
        formatter: (dynamic value) {
          return columnMap[value] ?? '';
        },
      ),
      PlutoColumn(
        title: configuration.localeText.filterType.toUpperCase(),
        field: FilterHelper.filterFieldType,
        type: PlutoColumnType.select(
          configuration.columnFilter.filters(
                type: PlutoColumnTypeEnum.select,
                field: FilterHelper.filterFieldType,
              ) ??
              [],
        ),
        enableFilterMenuItem: false,
        applyFormatterInEditing: true,
        formatter: (dynamic value) {
          return (value?.title ?? '').toString();
        },
      ),
      PlutoColumn(
        title: configuration.localeText.filterValue.toUpperCase(),
        field: FilterHelper.filterFieldValue,
        type: PlutoColumnType.text(),
        enableFilterMenuItem: false,
        enableEditingMode: false,
        enableAutoEditing: false,
        renderer: (rendererContext) =>
            PlutoFilterValueCell(rendererContext: rendererContext),
      ),
    ];
  }
}

class PlutoGridFilterPopupHeader extends StatelessWidget {
  final PlutoGridStateManager? stateManager;
  final PlutoGridConfiguration? configuration;
  final SetFilterPopupHandler? handleAddNewFilter;

  const PlutoGridFilterPopupHeader({
    super.key,
    this.stateManager,
    this.configuration,
    this.handleAddNewFilter,
  });

  void handleAddButton() {
    handleAddNewFilter!(stateManager);
  }

  void handleRemoveButton() {
    if (stateManager!.currentSelectingRows.isEmpty) {
      stateManager!.removeCurrentRow();
    } else {
      stateManager!.removeRows(stateManager!.currentSelectingRows);
    }
  }

  void handleClearButton() {
    if (stateManager!.rows.isEmpty) {
      Navigator.of(stateManager!.gridFocusNode.context!).pop();
    } else {
      stateManager!.removeRows(stateManager!.rows);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.add,
                size: configuration!.style.iconSize,
                color:
                    configuration?.style.addIconColor ??
                    theme.colorScheme.primary,
              ),
              tooltip: configuration?.localeText.addFilter,
              iconSize: configuration!.style.iconSize,
              onPressed: handleAddButton,
            ),
            SizedBox(width: configuration!.style.iconSize),
            IconButton(
              icon: Icon(
                Icons.remove,
                size: configuration!.style.iconSize,
                color:
                    configuration!.style.removeIconColor ??
                    theme.colorScheme.error,
              ),
              tooltip: configuration?.localeText.deleteSelectedFilter,
              iconSize: configuration!.style.iconSize,
              onPressed: handleRemoveButton,
            ),
            SizedBox(width: configuration!.style.iconSize),
            IconButton(
              icon: Icon(
                Icons.delete_forever,
                size: configuration!.style.iconSize,
                color:
                    configuration!.style.removeIconColor ??
                    theme.colorScheme.error,
              ),
              color:
                  configuration!.style.removeIconColor ??
                  theme.colorScheme.error,
              iconSize: configuration!.style.iconSize,
              onPressed: handleClearButton,
              tooltip: configuration!.localeText.resetFilter,
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close),
          color: configuration!.style.iconColor,
          iconSize: configuration!.style.iconSize,
          tooltip: configuration!.localeText.close,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class PlutoFilterValueCell extends StatefulWidget {
  final PlutoColumnRendererContext rendererContext;

  const PlutoFilterValueCell({super.key, required this.rendererContext});

  @override
  State<PlutoFilterValueCell> createState() => _PlutoFilterValueCellState();
}

class _PlutoFilterValueCellState extends State<PlutoFilterValueCell> {
  late final TextEditingController _singleController;
  late final TextEditingController _startController;
  late final TextEditingController _endController;

  PlutoRow get _row => widget.rendererContext.row;

  PlutoCell get _cell => widget.rendererContext.cell;

  PlutoGridStateManager get _stateManager =>
      widget.rendererContext.stateManager;

  PlutoGridStyleConfig get _style => _stateManager.style;

  PlutoFilterType? get _filterType =>
      _row.cells[FilterHelper.filterFieldType]?.currentValue
          as PlutoFilterType?;

  bool get _isBetween => _filterType is PlutoFilterTypeBetween;

  @override
  void initState() {
    super.initState();
    _singleController = TextEditingController();
    _startController = TextEditingController();
    _endController = TextEditingController();
    _syncFromCell();
  }

  @override
  void didUpdateWidget(covariant PlutoFilterValueCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromCell();
  }

  @override
  void dispose() {
    _singleController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _syncFromCell() {
    if (_isBetween) {
      final List<String> values = FilterHelper.resolveBetweenValues(
        search: _cell.valueFormatted?.toString(),
        searchObject: _cell.filterValue,
      );
      _startController.text = values.isNotEmpty ? values.first : '';
      _endController.text = values.length > 1 ? values[1] : '';
    } else {
      _singleController.text = _cell.valueFormatted?.toString() ?? '';
    }
  }

  void _updateSingleValue(String value) {
    _cell.filterValue = null;
    _stateManager.changeCellValue(_cell, value, callOnChangedEvent: true);
  }

  void _updateBetweenValue({required String start, required String end}) {
    _cell.filterValue = <String>[start, end];
    final String merged = start.isEmpty && end.isEmpty
        ? ''
        : '${start} ~ ${end}'.trim();
    _stateManager.changeCellValue(_cell, merged, callOnChangedEvent: true);
  }

  InputDecoration _inputDecoration() {
    return const InputDecoration(
      isDense: true,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSingleField() {
    return TextField(
      controller: _singleController,
      style: _style.filterTextStyle,
      decoration: _inputDecoration(),
      onChanged: _updateSingleValue,
    );
  }

  Widget _buildBetweenFields() {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _startController,
            style: _style.filterTextStyle,
            decoration: _inputDecoration(),
            onChanged: (value) =>
                _updateBetweenValue(start: value, end: _endController.text),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _endController,
            style: _style.filterTextStyle,
            decoration: _inputDecoration(),
            onChanged: (value) =>
                _updateBetweenValue(start: _startController.text, end: value),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: _isBetween ? _buildBetweenFields() : _buildSingleField(),
    );
  }
}

/// [base] is the cell values of the column on which the search is based.
/// [search] is the value entered by the user to search.
typedef PlutoCompareFunction =
    bool Function({
      required dynamic baseObject,
      required String? base,
      required dynamic searchObject,
      required String? search,
      // required dynamic? searchObject,
      required PlutoColumn column,
    });

abstract class PlutoFilterType {
  String get title => throw UnimplementedError();

  PlutoCompareFunction get compare => throw UnimplementedError();
}

class PlutoFilterTypeContains implements PlutoFilterType {
  static String name = 'Contains';

  @override
  String get title => PlutoFilterTypeContains.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareContains;

  const PlutoFilterTypeContains();
}

class PlutoFilterTypeNotContains implements PlutoFilterType {
  static String name = 'Not contains';

  @override
  String get title => PlutoFilterTypeNotContains.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareNotContains;

  const PlutoFilterTypeNotContains();
}

class PlutoFilterTypeContainsSet implements PlutoFilterType {
  static String name = 'Contains';

  @override
  String get title => PlutoFilterTypeContainsSet.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareContainsSet;

  const PlutoFilterTypeContainsSet();
}

class PlutoFilterTypeNotContainsSet implements PlutoFilterType {
  static String name = 'Not contains';

  @override
  String get title => PlutoFilterTypeNotContainsSet.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareNotContainsSet;

  const PlutoFilterTypeNotContainsSet();
}

class PlutoFilterTypeEquals implements PlutoFilterType {
  static String name = 'Equals';

  @override
  String get title => PlutoFilterTypeEquals.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareEquals;

  const PlutoFilterTypeEquals();
}

//PlutoFilterTypeNotEquals
class PlutoFilterTypeNotEquals implements PlutoFilterType {
  static String name = 'Not equals';

  @override
  String get title => PlutoFilterTypeNotEquals.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareNotEquals;

  const PlutoFilterTypeNotEquals();
}

class PlutoFilterTypeStartsWith implements PlutoFilterType {
  static String name = 'Starts with';

  @override
  String get title => PlutoFilterTypeStartsWith.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareStartsWith;

  const PlutoFilterTypeStartsWith();
}

class PlutoFilterTypeEndsWith implements PlutoFilterType {
  static String name = 'Ends with';

  @override
  String get title => PlutoFilterTypeEndsWith.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareEndsWith;

  const PlutoFilterTypeEndsWith();
}

class PlutoFilterTypeGreaterThan implements PlutoFilterType {
  static String name = 'Greater than';

  @override
  String get title => PlutoFilterTypeGreaterThan.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareGreaterThan;

  const PlutoFilterTypeGreaterThan();
}

class PlutoFilterTypeGreaterThanOrEqualTo implements PlutoFilterType {
  static String name = 'Greater than or equal to';

  @override
  String get title => PlutoFilterTypeGreaterThanOrEqualTo.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareGreaterThanOrEqualTo;

  const PlutoFilterTypeGreaterThanOrEqualTo();
}

class PlutoFilterTypeLessThan implements PlutoFilterType {
  static String name = 'Less than';

  @override
  String get title => PlutoFilterTypeLessThan.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareLessThan;

  const PlutoFilterTypeLessThan();
}

class PlutoFilterTypeLessThanOrEqualTo implements PlutoFilterType {
  static String name = 'Less than or equal to';

  @override
  String get title => PlutoFilterTypeLessThanOrEqualTo.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareLessThanOrEqualTo;

  const PlutoFilterTypeLessThanOrEqualTo();
}

class PlutoFilterTypeBetween implements PlutoFilterType {
  static String name = 'Between';

  @override
  String get title => PlutoFilterTypeBetween.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareBetween;

  const PlutoFilterTypeBetween();
}

class PlutoFilterTypeIsEmpty implements PlutoFilterType {
  static String name = 'Is empty';

  @override
  String get title => PlutoFilterTypeIsEmpty.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareIsEmpty;

  const PlutoFilterTypeIsEmpty();
}

class PlutoFilterTypeIsEmptySet implements PlutoFilterType {
  static String name = 'Is empty';

  @override
  String get title => PlutoFilterTypeIsEmptySet.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareIsEmptySet;

  const PlutoFilterTypeIsEmptySet();
}

class PlutoFilterTypeIsNotEmpty implements PlutoFilterType {
  static String name = 'Is not empty';

  @override
  String get title => PlutoFilterTypeIsNotEmpty.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareIsNotEmpty;

  const PlutoFilterTypeIsNotEmpty();
}

class PlutoFilterTypeIsNotEmptySet implements PlutoFilterType {
  static String name = 'Is not empty';

  @override
  String get title => PlutoFilterTypeIsNotEmptySet.name;

  @override
  PlutoCompareFunction get compare => FilterHelper.compareIsNotEmptySet;

  const PlutoFilterTypeIsNotEmptySet();
}
