import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  testWidgets(
    'linked peer activity can change while another position is scrolling',
    (WidgetTester tester) async {
      final LinkedScrollControllerGroup group = LinkedScrollControllerGroup();
      addTearDown(group.dispose);

      final ScrollController firstController = group.addAndGet();
      final ScrollController secondController = group.addAndGet();
      bool peerWentIdle = false;

      secondController.addListener(() {
        if (peerWentIdle || !secondController.hasClients) {
          return;
        }

        peerWentIdle = true;
        (secondController.position as ScrollPositionWithSingleContext).goIdle();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  key: const ValueKey<String>('first'),
                  controller: firstController,
                  itemExtent: 20,
                  itemCount: 20,
                  itemBuilder: (BuildContext context, int index) {
                    return Text('First $index');
                  },
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  key: const ValueKey<String>('second'),
                  controller: secondController,
                  itemExtent: 20,
                  itemCount: 20,
                  itemBuilder: (BuildContext context, int index) {
                    return Text('Second $index');
                  },
                ),
              ),
            ],
          ),
        ),
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('first')),
        const Offset(0, -40),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(peerWentIdle, isTrue);
    },
  );

  testWidgets(
    'driver activity can change while linked peers are updated',
    (WidgetTester tester) async {
      final LinkedScrollControllerGroup group = LinkedScrollControllerGroup();
      addTearDown(group.dispose);

      final ScrollController firstController = group.addAndGet();
      final ScrollController secondController = group.addAndGet();
      bool driverWentIdle = false;

      secondController.addListener(() {
        if (driverWentIdle ||
            !firstController.hasClients ||
            !secondController.hasClients) {
          return;
        }

        driverWentIdle = true;
        (firstController.position as ScrollPositionWithSingleContext).goIdle();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: <Widget>[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  key: const ValueKey<String>('first'),
                  controller: firstController,
                  itemExtent: 20,
                  itemCount: 20,
                  itemBuilder: (BuildContext context, int index) {
                    return Text('First $index');
                  },
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  key: const ValueKey<String>('second'),
                  controller: secondController,
                  itemExtent: 20,
                  itemCount: 20,
                  itemBuilder: (BuildContext context, int index) {
                    return Text('Second $index');
                  },
                ),
              ),
            ],
          ),
        ),
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('first')),
        const Offset(0, -40),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(driverWentIdle, isTrue);
    },
  );
}
