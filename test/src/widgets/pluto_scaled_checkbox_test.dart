import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  for (final Brightness brightness in Brightness.values) {
    testWidgets('preserves checkbox theme in $brightness', (
      WidgetTester tester,
    ) async {
      const RoundedRectangleBorder shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
      );
      const BorderSide side = BorderSide(color: Colors.purple, width: 2);
      final CheckboxThemeData checkboxTheme = CheckboxThemeData(
        shape: shape,
        side: side,
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? Colors.purple
              : Colors.yellow,
        ),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.orange;
          }
          if (states.contains(WidgetState.focused)) {
            return Colors.green;
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.red;
          }
          return Colors.transparent;
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: brightness,
            checkboxTheme: checkboxTheme,
          ),
          home: Material(
            child: PlutoScaledCheckbox(
              value: false,
              activeColor: null,
              unselectedColor: Colors.cyan,
              handleOnChanged: (bool? changed) {},
            ),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(Checkbox));
      final ThemeData inheritedTheme = Theme.of(context);
      final CheckboxThemeData inheritedCheckboxTheme = CheckboxTheme.of(
        context,
      );
      expect(inheritedTheme.brightness, brightness);
      expect(inheritedTheme.unselectedWidgetColor, Colors.cyan);
      expect(inheritedCheckboxTheme.shape, shape);
      expect(inheritedCheckboxTheme.side, side);
      expect(
        inheritedCheckboxTheme.fillColor?.resolve(<WidgetState>{
          WidgetState.selected,
        }),
        Colors.purple,
      );
      for (final MapEntry<WidgetState, Color> entry in <WidgetState, Color>{
        WidgetState.hovered: Colors.red,
        WidgetState.focused: Colors.green,
        WidgetState.pressed: Colors.orange,
      }.entries) {
        expect(
          inheritedCheckboxTheme.overlayColor?.resolve(<WidgetState>{
            entry.key,
          }),
          entry.value,
        );
      }
    });
  }

  testWidgets('indeterminate checkbox keeps the configured active color', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoScaledCheckbox(
            value: null,
            tristate: true,
            activeColor: Colors.purple,
            unselectedColor: Colors.grey,
            checkColor: Colors.white,
            handleOnChanged: (bool? changed) {},
          ),
        ),
      ),
    );

    final Checkbox checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isNull);
    expect(checkbox.activeColor, Colors.purple);
    expect(checkbox.checkColor, Colors.white);
  });

  testWidgets('partial row selection preserves the themed header checkbox', (
    WidgetTester tester,
  ) async {
    late PlutoGridStateManager stateManager;
    const RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(7)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          checkboxTheme: const CheckboxThemeData(shape: shape),
        ),
        home: Scaffold(
          body: PlutoGrid(
            columns: <PlutoColumn>[
              PlutoColumn(
                title: 'Name',
                field: 'name',
                type: PlutoColumnType.text(),
                enableRowChecked: true,
              ),
            ],
            rows: <PlutoRow<dynamic>>[
              PlutoRow<dynamic>(
                checked: true,
                cells: <String, PlutoCell>{'name': PlutoCell(value: 'A')},
              ),
              PlutoRow<dynamic>(
                cells: <String, PlutoCell>{'name': PlutoCell(value: 'B')},
              ),
            ],
            configuration: const PlutoGridConfiguration(
              style: PlutoGridStyleConfig(
                columnActiveColor: Colors.purple,
                columnUnselectedColor: Colors.grey,
              ),
            ),
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder headerCheckbox = find.byWidgetPredicate(
      (Widget widget) => widget is Checkbox && widget.value == null,
    );
    expect(headerCheckbox, findsOneWidget);
    expect(
      CheckboxTheme.of(tester.element(headerCheckbox)).shape,
      shape,
    );
    expect(tester.widget<Checkbox>(headerCheckbox).activeColor, Colors.purple);

    stateManager.toggleAllRowChecked(true);
    await tester.pumpAndSettle();
    expect(stateManager.tristateCheckedRow, isTrue);
    expect(
      stateManager.rows.every((PlutoRow<dynamic> row) => row.checked ?? false),
      isTrue,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'checkbox 가 렌더링 되어야 한다.',
    (WidgetTester tester) async {
      // given
      const bool value = false;

      handleOnChanged(bool? changed) {}

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoScaledCheckbox(
              value: value,
              handleOnChanged: handleOnChanged,
            ),
          ),
        ),
      );

      // then
      expect(find.byType(Checkbox), findsOneWidget);
    },
  );

  testWidgets(
    'checkbox 를 탭하면 handleOnChanged 가 호출 되어야 한다.',
    (WidgetTester tester) async {
      // given
      bool? value = false;

      handleOnChanged(bool? changed) {
        value = changed;
      }

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoScaledCheckbox(
              value: value,
              handleOnChanged: handleOnChanged,
            ),
          ),
        ),
      );

      expect(value, isFalse);

      // then
      await tester.tap(find.byType(Checkbox));

      expect(value, isTrue);
    },
  );
}
