import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

/// A cancellable calculation that yields after each bounded unit of work.
///
/// All calculations share a frame budget. The steps must yield frequently and
/// create fresh local accumulators each time the factory is called. Notify the
/// grid when changing its data so consumers can replace outdated calculations.
class PlutoGridAsyncCalculation {
  PlutoGridAsyncCalculation({
    required Iterable<void> Function() steps,
    required VoidCallback onCompleted,
  }) : _steps = steps,
       _onCompleted = onCompleted {
    _pending.add(this);
    _scheduleFrame();
  }

  static final ListQueue<PlutoGridAsyncCalculation> _pending =
      ListQueue<PlutoGridAsyncCalculation>();
  static int? _frameCallback;

  Iterable<void> Function()? _steps;
  VoidCallback? _onCompleted;
  Iterator<void>? _iterator;
  bool _retriedConcurrentModification = false;

  bool get isRunning => _steps != null;

  void cancel() {
    _steps = null;
    _iterator = null;
    _onCompleted = null;
    _pending.remove(this);
    if (_pending.isEmpty && _frameCallback != null) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallback!);
      _frameCallback = null;
    }
  }

  static void _scheduleFrame() {
    if (_pending.isNotEmpty && _frameCallback == null) {
      _frameCallback = SchedulerBinding.instance.scheduleFrameCallback(
        _runFrame,
      );
    }
  }

  static void _runFrame(Duration timestamp) {
    _frameCallback = null;
    final Stopwatch timer = Stopwatch()..start();
    final int budget = PlutoGridSettings.calculationFrameBudget.inMicroseconds;
    int steps = 0;
    while (_pending.isNotEmpty &&
        steps < PlutoGridSettings.calculationMaxStepsPerFrame &&
        timer.elapsedMicroseconds < budget) {
      final PlutoGridAsyncCalculation calculation = _pending.removeFirst();
      for (
        int batch = 0;
        calculation.isRunning &&
            batch < PlutoGridSettings.calculationBatchSize &&
            steps < PlutoGridSettings.calculationMaxStepsPerFrame &&
            timer.elapsedMicroseconds < budget;
        batch += 1
      ) {
        calculation._advance();
        steps += 1;
      }
      if (calculation.isRunning) {
        _pending.add(calculation);
      }
    }
    _scheduleFrame();
  }

  void _advance() {
    try {
      _iterator ??= _steps!().iterator;
      if (!_iterator!.moveNext()) {
        final VoidCallback? onCompleted = _onCompleted;
        cancel();
        onCompleted?.call();
      }
      // The iterator's fail-fast signal requests a fresh pass over current data.
      // ignore: avoid_catching_errors
    } on ConcurrentModificationError catch (error, stack) {
      if (!_retriedConcurrentModification) {
        // A row list may change before its notification is delivered. Discard
        // the partial calculation and restart with fresh iterators/accumulators.
        _retriedConcurrentModification = true;
        _iterator = null;
      } else {
        _reportError(error, stack);
      }
    } on Object catch (error, stack) {
      _reportError(error, stack);
    }
  }

  void _reportError(Object error, StackTrace stack) {
    cancel();
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'pluto_grid_plus',
        context: ErrorDescription('while calculating a grid footer'),
      ),
    );
  }
}
