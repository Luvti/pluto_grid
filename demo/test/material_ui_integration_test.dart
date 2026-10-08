import 'package:demo/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  testWidgets(
    'demo renders and opens its legacy menu under standalone Material',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.byType(PlutoGrid), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Add & Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Column'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
