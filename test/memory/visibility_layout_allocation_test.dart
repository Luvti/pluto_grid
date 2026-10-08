import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/src/ui/miscellaneous/pluto_visibility_layout.dart';

void main() {
  testWidgets('scrolling creates only the elements that are mounted', (
    WidgetTester tester,
  ) async {
    final ScrollController scroll = ScrollController();
    final List<_CountingLayoutId> children = List<_CountingLayoutId>.generate(
      3,
      _CountingLayoutId.new,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 100,
            height: 50,
            child: SingleChildScrollView(
              controller: scroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 360,
                height: 50,
                child: PlutoVisibilityLayout(
                  delegate: _LayoutDelegate(children),
                  scrollController: scroll,
                  initialViewportDimension: 100,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(children.map((_CountingLayoutId child) => child.created), <int>[
      1,
      0,
      0,
    ]);

    scroll.jumpTo(121);
    await tester.pumpAndSettle();
    expect(find.text('Child 1'), findsOneWidget);
    expect(find.text('Child 0'), findsNothing);
    expect(children.map((_CountingLayoutId child) => child.created), <int>[
      1,
      1,
      0,
    ]);

    scroll.jumpTo(250);
    await tester.pumpAndSettle();
    expect(find.text('Child 2'), findsOneWidget);
    expect(children.map((_CountingLayoutId child) => child.created), <int>[
      1,
      1,
      1,
    ]);

    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Child 0'), findsOneWidget);
    expect(children.map((_CountingLayoutId child) => child.created), <int>[
      2,
      1,
      1,
    ]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    scroll.dispose();
  });
}

class _CountingLayoutId extends PlutoVisibilityLayoutId {
  _CountingLayoutId(int index) : super(id: index, child: _LayoutChild(index));
  final _CreationCounter _counter = _CreationCounter();

  int get created => _counter.value;

  @override
  ParentDataElement<MultiChildLayoutParentData> createElement() {
    _counter.value++;
    return super.createElement();
  }
}

class _CreationCounter {
  int value = 0;
}

class _LayoutChild extends StatelessWidget
    implements PlutoVisibilityLayoutChild {
  const _LayoutChild(this.index);
  final int index;

  @override
  double get width => 120;

  @override
  double get startPosition => index * width;

  @override
  bool get keepAlive => false;

  @override
  Widget build(BuildContext context) => Text('Child $index');
}

class _LayoutDelegate extends MultiChildLayoutDelegate {
  _LayoutDelegate(this.children);
  final List<_CountingLayoutId> children;

  @override
  void performLayout(Size size) {
    for (final _CountingLayoutId child in children) {
      if (hasChild(child.id)) {
        layoutChild(child.id, BoxConstraints.tight(const Size(120, 50)));
        positionChild(child.id, Offset(child.layoutChild.startPosition, 0));
      }
    }
  }

  @override
  bool shouldRelayout(_LayoutDelegate oldDelegate) => true;
}
