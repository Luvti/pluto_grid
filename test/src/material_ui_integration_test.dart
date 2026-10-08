import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  testWidgets('localized grid opens a standalone Material column menu', (
    WidgetTester tester,
  ) async {
    final PlutoColumn column = PlutoColumn(
      title: 'Name',
      field: 'name',
      type: PlutoColumnType.text(),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru', 'RU'),
        supportedLocales: const <Locale>[Locale('ru', 'RU')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PlutoGrid(
            columns: <PlutoColumn>[column],
            rows: <PlutoRow<dynamic>>[
              PlutoRow<dynamic>(
                cells: <String, PlutoCell>{'name': PlutoCell(value: 'A')},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(PlutoGrid));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      MaterialLocalizations.of(context).cancelButtonLabel,
      isNot(const DefaultMaterialLocalizations().cancelButtonLabel),
    );

    final Future<int?> selection = showColumnMenu<int>(
      context: context,
      position: const Offset(100, 100),
      items: const <PopupMenuEntry<int>>[
        PopupMenuItem<int>(value: 1, child: Text('Custom action')),
      ],
    )!;
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<int>), findsOneWidget);
    await tester.tap(find.text('Custom action'));
    await tester.pumpAndSettle();
    expect(await selection, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
