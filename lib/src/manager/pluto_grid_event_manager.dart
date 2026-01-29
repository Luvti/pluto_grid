import 'dart:async';

import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:rxdart/rxdart.dart';

class PlutoGridEventManager {
  final PlutoGridStateManager stateManager;

  PlutoGridEventManager({
    required this.stateManager,
  });

  final PublishSubject<PlutoGridEvent> _subject =
      PublishSubject<PlutoGridEvent>();

  PublishSubject<PlutoGridEvent> get subject => _subject;

  late final StreamSubscription _subscription;

  StreamSubscription get subscription => _subscription;

  void dispose() {
    unawaited(_subscription.cancel());

    unawaited(_subject.close());
  }

  void init() {
    final Stream<PlutoGridEvent> normalStream = _subject.stream.where(
      (PlutoGridEvent event) => event.type.isNormal,
    );

    final Stream<PlutoGridEvent> throttleLeadingStream = _subject.stream
        .where((PlutoGridEvent event) => event.type.isThrottleLeading)
        .transform(
          ThrottleStreamTransformer(
            (PlutoGridEvent s) =>
                TimerStream<PlutoGridEvent>(s, s.duration as Duration),
            trailing: false,
            leading: true,
          ),
        );

    final Stream<PlutoGridEvent> throttleTrailingStream = _subject.stream
        .where((PlutoGridEvent event) => event.type.isThrottleTrailing)
        .transform(
          ThrottleStreamTransformer(
            (PlutoGridEvent s) =>
                TimerStream<PlutoGridEvent>(s, s.duration as Duration),
            trailing: true,
            leading: false,
          ),
        );

    final Stream<PlutoGridEvent> debounceStream = _subject.stream
        .where((PlutoGridEvent event) => event.type.isDebounce)
        .transform(
          DebounceStreamTransformer(
            (PlutoGridEvent s) =>
                TimerStream<PlutoGridEvent>(s, s.duration as Duration),
          ),
        );

    _subscription = MergeStream(<Stream<PlutoGridEvent>>[
      normalStream,
      throttleLeadingStream,
      throttleTrailingStream,
      debounceStream,
    ]).listen(_handler);
  }

  void addEvent(PlutoGridEvent event) {
    _subject.add(event);
  }

  StreamSubscription<PlutoGridEvent> listener(
    void Function(PlutoGridEvent event) onData,
  ) {
    return _subject.stream.listen(onData);
  }

  void _handler(PlutoGridEvent event) {
    event.handler(stateManager);
  }
}
