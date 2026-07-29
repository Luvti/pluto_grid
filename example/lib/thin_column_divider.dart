import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  runApp(const ThinColumnDividerExampleApp());
}

class ThinColumnDividerExampleApp extends StatelessWidget {
  const ThinColumnDividerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Thin grid dividers',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const ThinColumnDividerExamplePage(),
    );
  }
}

class ThinColumnDividerExamplePage extends StatefulWidget {
  const ThinColumnDividerExamplePage({super.key});

  @override
  State<ThinColumnDividerExamplePage> createState() =>
      _ThinColumnDividerExamplePageState();
}

class _ThinColumnDividerExamplePageState
    extends State<ThinColumnDividerExamplePage> {
  OverlayEntry? _filterOverlay;

  late final List<PlutoColumn> columns = <PlutoColumn>[
    PlutoColumn(
      title: 'Keyword',
      field: 'keyword',
      type: PlutoColumnType.text(),
      width: 220,
      filterIconRenderer: (PlutoColumnFilterIconContext context) =>
          const Icon(Icons.filter_alt_outlined, size: 16, color: Colors.blue),
      onFilterIconTap: _showKeywordFilterOverlay,
    ),
    PlutoColumn(
      title: 'Position',
      field: 'position',
      type: PlutoColumnType.number(),
      width: 150,
    ),
    PlutoColumn(
      title: 'Volume',
      field: 'volume',
      type: PlutoColumnType.number(),
      width: 150,
    ),
    PlutoColumn(
      title: 'Updated',
      field: 'updated',
      type: PlutoColumnType.text(),
      width: 180,
    ),
  ];

  late final List<PlutoRow> rows = <PlutoRow>[
    _row('keyword research', 4, 12500, 'Today'),
    _row('app store optimization', 8, 8300, 'Today'),
    _row('competitor analysis', 12, 6100, 'Yesterday'),
    _row('aso tools', 17, 4900, 'Yesterday'),
    _row('keyword tracking', 21, 3700, '2 days ago'),
  ];

  PlutoRow _row(String keyword, int position, int volume, String updated) {
    return PlutoRow(
      cells: <String, PlutoCell>{
        'keyword': PlutoCell(value: keyword),
        'position': PlutoCell(value: position),
        'volume': PlutoCell(value: volume),
        'updated': PlutoCell(value: updated),
      },
    );
  }

  void _showKeywordFilterOverlay(PlutoColumnFilterIconContext context) {
    _removeFilterOverlay();

    // The callback receives the icon's exact BuildContext, so custom filter
    // surfaces can be positioned relative to the action instead of the header.
    final RenderBox iconBox =
        context.buildContext.findRenderObject()! as RenderBox;
    final Offset iconPosition = iconBox.localToGlobal(Offset.zero);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (BuildContext overlayContext) => Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeFilterOverlay,
            ),
          ),
          Positioned(
            left: iconPosition.dx,
            top: iconPosition.dy + iconBox.size.height + 8,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Custom filter overlay'),
              ),
            ),
          ),
        ],
      ),
    );

    _filterOverlay = entry;
    Overlay.of(context.buildContext).insert(entry);
  }

  void _removeFilterOverlay() {
    _filterOverlay?.remove();
    _filterOverlay = null;
  }

  @override
  void dispose() {
    _removeFilterOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('0.5 px grid dividers')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Hover over a column boundary in the header or cells and drag '
              'it to resize. Tap the blue filter icon for a custom overlay.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PlutoGrid(
                columns: columns,
                columnGroups: <PlutoColumnGroup>[
                  PlutoColumnGroup(
                    title: 'Discovery',
                    fields: <String>['keyword', 'position'],
                  ),
                  PlutoColumnGroup(
                    title: 'Performance',
                    fields: <String>['volume', 'updated'],
                  ),
                ],
                rows: rows,
                configuration: const PlutoGridConfiguration(
                  style: PlutoGridStyleConfig(
                    // Painted dividers can remain subtle because resizing uses
                    // a separate 12 px hit target centered on each boundary.
                    columnBorderWidth: 0.5,
                    rowBorderWidth: 0.5,
                    showColumnHeaderIcon: false,
                    columnResizeIndicatorMode:
                        PlutoColumnResizeIndicatorMode.fullHeight,
                    gridBorderWidth: 0.5,
                    borderColor: Color(0xFF94A3B8),
                    gridBorderColor: Color(0xFF94A3B8),
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
