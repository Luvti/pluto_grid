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
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru', 'RU'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('ru', 'RU')],
      title: 'PlutoGrid Big Data Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PlutoGridBigDataPage(),
    );
  }
}

class PlutoGridBigDataPage extends StatefulWidget {
  const PlutoGridBigDataPage({super.key});

  @override
  State<PlutoGridBigDataPage> createState() => _PlutoGridBigDataPageState();
}

class _PlutoGridBigDataPageState extends State<PlutoGridBigDataPage> {
  late List<PlutoColumn> columns;
  late List<PlutoRow> rows;
  late PlutoGridStateManager stateManager;

  @override
  void initState() {
    super.initState();

    columns = [
      PlutoColumn(title: 'Text', field: 'text', type: PlutoColumnType.text()),
      PlutoColumn(
        title: 'Number',
        field: 'number',
        type: PlutoColumnType.number(),
      ),
      PlutoColumn(
        title: 'Double',
        field: 'double',
        type: PlutoColumnType.double(),
      ),
      PlutoColumn(
        title: 'Currency',
        field: 'currency',
        type: PlutoColumnType.currency(),
      ),
      PlutoColumn(
        title: 'Select',
        field: 'select',
        type: PlutoColumnType.select(['Option 1', 'Option 2', 'Option 3']),
      ),
      PlutoColumn(title: 'Bool', field: 'bool', type: PlutoColumnType.bool()),
      PlutoColumn(title: 'Date', field: 'date', type: PlutoColumnType.date()),
      PlutoColumn(title: 'Time', field: 'time', type: PlutoColumnType.time()),
    ];

    rows = List.generate(50000, (index) {
      return PlutoRow(
        cells: {
          'text': PlutoCell(value: 'Text value $index'),
          'number': PlutoCell(value: index),
          'double': PlutoCell(value: index * 0.5),
          'currency': PlutoCell(value: index * 10.0),
          'select': PlutoCell(value: 'Option ${(index % 3) + 1}'),
          'bool': PlutoCell(value: index % 2 == 0),
          'date': PlutoCell(value: '2023-01-01'),
          'time': PlutoCell(value: '12:00'),
        },
      );
    });
  }

  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlutoGrid 50k Rows'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                index++;
              });
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(15),
        child: PlutoGrid(
          key: ValueKey<int>(index),
          columns: columns,
          rows: rows,
          onLoaded: (PlutoGridOnLoadedEvent event) {
            stateManager = event.stateManager;
            stateManager.setShowColumnFilter(true);
          },
          configuration: const PlutoGridConfiguration(),
        ),
      ),
    );
  }
}
