import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings
      // Flutter keeps one permanent updateChildren placeholder per isolate.
      .withIgnored(
        notDisposed: <String, int?>{'_NullElement': 1},
        // Ignore binding fixtures, while still tracking fixtures in this suite.
        createdByTestHelpers: true,
        testHelperExceptions: <RegExp>[RegExp('test/memory/')],
      )
      .withTracked(
        experimentalNotGCed: <String>[
          'PlutoGridStateManager',
          'PlutoDualGridResizeNotifier',
          'ChangeNotifier',
          'FocusNode',
          'TextEditingController',
          'AnimationController',
          'CurvedAnimation',
          'ScrollController',
          '_LinkedScrollPosition',
          '_LinkedScrollController',
          '_LinkedScrollControllerGroupOffsetNotifier',
        ],
      );
  await testMain();
}
