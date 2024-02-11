import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
  final List<PlutoColumn> columns = <PlutoColumn>[
    PlutoColumn(
      title: 'Id',
      field: 'id',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Name test long name in header',
      field: 'name',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Age',
      field: 'age',
      defaultFilter: const PlutoFilterTypeGreaterThan(),
      type: PlutoColumnType.number(defaultValue: 11.1, format: '#.##'),
    ),
    PlutoColumn(
      title: 'Age double',
      field: 'age_double',
      defaultFilter: const PlutoFilterTypeGreaterThan(),
      type: PlutoColumnType.double(
        defaultValue: 12.23,
      ),
      formatter: (value) => value.toString(),
    ),
    PlutoColumn(
      title: 'Buy',
      field: 'buy',
      type: PlutoColumnType.bool(),
    ),
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
        <String>[
          'Programmer',
          'Designer',
          'Owner',
        ],
        builder: (item) {
          return Row(children: [
            Icon(item == 'Programmer' ? Icons.code : Icons.design_services),
            const SizedBox(width: 8),
            Text(item),
          ]);
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

  final List<PlutoRow> rows = [
    PlutoRow(
      cells: {
        'id': PlutoCell(value: 'user1'),
        'name': PlutoCell(value: 'Mike'),
        'age': PlutoCell(value: 0.20),
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
        'age': PlutoCell(value: 2.0),
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
        'age': PlutoCell(value: 2.1),
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
    PlutoColumnGroup(title: 'User information', fields: ['name', 'age']),
    PlutoColumnGroup(title: 'Status', children: [
      PlutoColumnGroup(title: 'A', fields: ['role'], expandedColumn: true),
      PlutoColumnGroup(
          title: 'Etc.', fields: ['joined', 'working_time', 'role2']),
    ]),
  ];

  /// [PlutoGridStateManager] has many methods and properties to dynamically manipulate the grid.
  /// You can manipulate the grid dynamically at runtime by passing this through the [onLoaded] callback.
  PlutoGridStateManager? stateManager;
  int indexKey = 0;

  PlutoGridOnSortedEvent? onSorted;

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
                    stateManager!
                        .setFilter(filters, filterRowsApply: filterRows);
                    if (onSorted != null) {
                      if (onSorted!.column.sort == PlutoColumnSort.ascending) {
                        stateManager!.sortAscending(
                          onSorted!.column,
                        );
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
                configuration: const PlutoGridConfiguration(
                  columnFilter: PlutoGridColumnFilterConfig(
                    filters: [
                      PlutoFilterTypeContains(),
                      PlutoFilterTypeGreaterThanOrEqualTo(),
                      PlutoFilterTypeLessThanOrEqualTo(),
                    ],
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
