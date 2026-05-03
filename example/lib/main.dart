import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ru', 'RU'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('ru', 'RU')],
      title: 'PlutoGrid Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PlutoGridExamplePage(),
    );
  }
}

/// PlutoGrid Example
//
/// For more examples, go to the demo web link on the github below.
class PlutoGridExamplePage extends StatefulWidget {
  const PlutoGridExamplePage({super.key});

  @override
  State<PlutoGridExamplePage> createState() => _PlutoGridExamplePageState();
}

class _PlutoGridExamplePageState extends State<PlutoGridExamplePage> {
  late final List<PlutoColumn> columns;

  final List<PlutoRow> rows = [
    PlutoRow(
      cells: {
        'id': PlutoCell(value: 'user1'),
        'name': PlutoCell(value: 'Mike'),
        'set': PlutoCell(
          value: 'set (1,2,3,4)',
          filterValue: {'1', '2', '3', '4'},
        ),
        'age': PlutoCell(value: 0.20),
        'age2': PlutoCell(value: 4.9),
        'age_double': PlutoCell(value: 10),
        'buy': PlutoCell(value: false),
        'role': PlutoCell(value: 'Programmer'),
        'role2': PlutoCell(value: 'Programmer'),
        'joined': PlutoCell(value: '2021-01-01'),
        'working_time': PlutoCell(value: '09:00'),
        'salary': PlutoCell(value: 300),
      },
    ),
    PlutoRow(
      cells: {
        'id': PlutoCell(value: 'user2'),
        'name': PlutoCell(value: 'Jack'),
        'set': PlutoCell(
          value: 'set (5,6,7,8)',
          filterValue: {'5', '6', '7', '8'},
        ),
        'age': PlutoCell(value: 2.0),
        'age2': PlutoCell(value: 12.0),
        'age_double': PlutoCell(value: 0.9),
        'buy': PlutoCell(value: true),
        'role': PlutoCell(value: 'Designer'),
        'role2': PlutoCell(value: 'Designer'),
        'joined': PlutoCell(value: '2021-02-01'),
        'working_time': PlutoCell(value: '10:00'),
        'salary': PlutoCell(value: 400),
      },
    ),
    PlutoRow(
      cells: {
        'id': PlutoCell(value: 'user3'),
        'name': PlutoCell(value: 'Suzi'),
        'set': PlutoCell(
          value: 'set (9,10,11,12)',
          filterValue: {'9', '10', '11', '12'},
        ),
        'age': PlutoCell(value: 2.1),
        'age2': PlutoCell(value: 17.2),
        'age_double': PlutoCell(value: 0.39),
        'buy': PlutoCell(value: null),
        'role': PlutoCell(value: 'Owner'),
        'role2': PlutoCell(value: 'Owner'),
        'joined': PlutoCell(value: '2021-03-01'),
        'working_time': PlutoCell(value: '11:00'),
        'salary': PlutoCell(value: 700),
      },
    ),
  ];

  /// columnGroups that can group columns can be omitted.
  final List<PlutoColumnGroup> columnGroups = [
    PlutoColumnGroup(title: 'Id', fields: ['id'], expandedColumn: true),
    PlutoColumnGroup(
      title: 'User information',
      fields: ['name', 'age', 'age2'],
    ),
    PlutoColumnGroup(
      title: 'Status',
      children: [
        PlutoColumnGroup(title: 'A', fields: ['role'], expandedColumn: true),
        PlutoColumnGroup(
          title: 'Etc.',
          fields: ['joined', 'working_time', 'role2'],
        ),
      ],
    ),
  ];

  /// [PlutoGridStateManager] has many methods and properties to dynamically manipulate the grid.
  /// You can manipulate the grid dynamically at runtime by passing this through the [onLoaded] callback.
  PlutoGridStateManager? stateManager;
  int indexKey = 0;

  PlutoGridOnSortedEvent? onSorted;

  static const List<_AgeRange> _ageRanges = <_AgeRange>[
    _AgeRange(label: 'Малышки', start: '0', end: '5'),
    _AgeRange(label: 'Дети', start: '5', end: '10'),
    _AgeRange(label: 'Подростки', start: '10', end: '16'),
    _AgeRange(label: 'Старшее поколение', start: '16', end: ''),
  ];

  @override
  void initState() {
    super.initState();

    final ageColumn = PlutoColumn(
      title: 'Age',
      field: 'age',
      defaultFilter: const PlutoFilterTypeBetween(),
      type: PlutoColumnType.double(defaultValue: 11.1, format: '#.##'),
    );

    final age2Column = PlutoColumn(
      title: 'Age 2',
      field: 'age2',
      defaultFilter: const PlutoFilterTypeBetween(),
      type: PlutoColumnType.number(defaultValue: 0, format: '#.##'),
    );

    age2Column.filterWidgetBuilder = _ageRangeFilterBuilder(age2Column);

    columns = <PlutoColumn>[
      PlutoColumn(
        title: 'Id',
        field: 'id',
        type: PlutoColumnType.text(),
        enableRowChecked: true,
      ),
      PlutoColumn(
        title: 'Name test long name in header',
        field: 'name',
        type: PlutoColumnType.text(),
        defaultFilter: const PlutoFilterTypeNotContains(),
      ),
      ageColumn,
      age2Column,
      PlutoColumn(
        title: 'set',
        field: 'set',
        defaultFilter: const PlutoFilterTypeContainsSet(),
        type: PlutoColumnType.text(),
      ),
      PlutoColumn(
        title: 'Age double',
        field: 'age_double',
        defaultFilter: const PlutoFilterTypeGreaterThan(),
        type: PlutoColumnType.double(defaultValue: 12.23),
        formatter: (value) => value.toString(),
        footerRenderer: (context) {
          return PlutoAggregateColumnFooter(
            rendererContext: context,
            type: PlutoAggregateColumnType.average,
            format: '#.##',
            alignment: Alignment.center,
            titleSpanBuilder: (text) {
              return [
                const TextSpan(
                  text: 'Avg',
                  style: TextStyle(color: Colors.blue),
                ),
                const TextSpan(text: ' : '),
                TextSpan(text: text),
              ];
            },
          );
        },
      ),
      PlutoColumn(title: 'Buy', field: 'buy', type: PlutoColumnType.bool()),
      PlutoColumn(
        title: 'Role',
        field: 'role',
        type: PlutoColumnType.select(<String>[
          'Programmer',
          'Designer',
          'Owner',
        ]),
      ),
      PlutoColumn(
        title: 'Role 2',
        field: 'role2',
        type: PlutoColumnType.select(
          <String>['Programmer', 'Designer', 'Owner'],
          builder: (item) {
            return Row(
              children: [
                Icon(item == 'Programmer' ? Icons.code : Icons.design_services),
                const SizedBox(width: 8),
                Text(item),
              ],
            );
          },
        ),
      ),
      PlutoColumn(
        title: 'Joined',
        field: 'joined',
        type: PlutoColumnType.date(),
      ),
      PlutoColumn(
        title: 'Working time',
        field: 'working_time',
        type: PlutoColumnType.time(),
      ),
      PlutoColumn(
        title: 'salary',
        field: 'salary',
        type: PlutoColumnType.currency(),
        footerRenderer: (rendererContext) {
          return PlutoAggregateColumnFooter(
            rendererContext: rendererContext,
            formatAsCurrency: true,
            type: PlutoAggregateColumnType.sum,
            format: '#,###',
            alignment: Alignment.center,
            titleSpanBuilder: (text) {
              return [
                const TextSpan(
                  text: 'Sum',
                  style: TextStyle(color: Colors.red),
                ),
                const TextSpan(text: ' : '),
                TextSpan(text: text),
              ];
            },
          );
        },
      ),
    ];
  }

  Widget Function(
    FocusNode,
    TextEditingController,
    bool,
    void Function(String),
    PlutoGridStateManager,
  )
  _ageRangeFilterBuilder(PlutoColumn column) {
    return (
      FocusNode focusNode,
      TextEditingController controller,
      bool enabled,
      void Function(String) handleOnChanged,
      PlutoGridStateManager stateManager,
    ) {
      final style = stateManager.configuration.style;

      return DropdownButtonFormField<String>(
        focusNode: focusNode,
        value: controller.text.isEmpty ? null : controller.text,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: enabled
              ? style.cellColorInEditState
              : style.cellColorInReadOnlyState,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: style.borderColor, width: 0),
            borderRadius: BorderRadius.zero,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: style.borderColor, width: 0),
            borderRadius: BorderRadius.zero,
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: style.inactivatedBorderColor,
              width: 0,
            ),
            borderRadius: BorderRadius.zero,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: style.activatedBorderColor, width: 0),
            borderRadius: BorderRadius.zero,
          ),
          contentPadding: const EdgeInsets.all(5),
          hintText: 'Возраст',
          hintStyle: style.filterHintTextStyle,
        ),
        items: _ageRanges
            .map(
              (range) => DropdownMenuItem<String>(
                value: range.label,
                child: Text(range.label, style: style.filterTextStyle),
              ),
            )
            .toList(growable: false),
        onChanged: !enabled
            ? null
            : (value) {
                if (value == null || value.isEmpty) {
                  controller.text = '';
                  stateManager.eventManager!.addEvent(
                    PlutoGridChangeColumnFilterEvent(
                      column: column,
                      filterType: const PlutoFilterTypeBetween(),
                      filterValue: '',
                      filterValueObject: null,
                      debounceMilliseconds: stateManager
                          .configuration
                          .columnFilter
                          .debounceMilliseconds,
                    ),
                  );
                  return;
                }

                final range = _ageRanges.firstWhere(
                  (item) => item.label == value,
                );

                controller.text = value;
                stateManager.eventManager!.addEvent(
                  PlutoGridChangeColumnFilterEvent(
                    column: column,
                    filterType: const PlutoFilterTypeBetween(),
                    filterValue: value,
                    filterValueObject: <String>[range.start, range.end],
                    debounceMilliseconds: stateManager
                        .configuration
                        .columnFilter
                        .debounceMilliseconds,
                  ),
                );
              },
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    // stateManager.filter
    // stateManager.setFilter();
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  indexKey++;
                });
              },
              child: Text('refresh'),
            ),
            Flexible(
              child: PlutoGrid(
                key: ValueKey(indexKey),
                columns: columns,
                rows: rows,
                columnGroups: columnGroups,
                onSorted: (event) {
                  print(event);
                  onSorted = event;
                },
                onLoaded: (PlutoGridOnLoadedEvent event) {
                  if (stateManager == null) {
                    stateManager = event.stateManager;
                    stateManager?.setShowColumnFilter(true);
                  } else {
                    final filters = stateManager!.savedFilter;
                    final filterRows = stateManager!.filterRows;
                    stateManager = event.stateManager;
                    stateManager?.setShowColumnFilter(true);
                    stateManager!.setFilter(
                      filters,
                      filterRowsApply: filterRows,
                    );
                    if (onSorted != null) {
                      if (onSorted!.column.sort == PlutoColumnSort.ascending) {
                        stateManager!.sortAscending(onSorted!.column);
                      }
                      if (onSorted!.column.sort == PlutoColumnSort.descending) {
                        stateManager!.sortDescending(onSorted!.column);
                      }
                    }
                  }
                },
                onChanged: (PlutoGridOnChangedEvent event) {
                  print(event);
                },
                configuration: PlutoGridConfiguration(
                  style: PlutoGridStyleConfig(
                    columnHeaderTextStyle: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(color: Colors.blue),
                    filterHintTextStyle: Theme.of(
                      context,
                    ).textTheme.bodySmall!.copyWith(color: Colors.red),
                    filterTextStyle: Theme.of(
                      context,
                    ).textTheme.bodySmall!.copyWith(color: Colors.green),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeRange {
  final String label;
  final String start;
  final String end;

  const _AgeRange({
    required this.label,
    required this.start,
    required this.end,
  });
}
