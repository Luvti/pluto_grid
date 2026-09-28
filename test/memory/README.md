# Memory regression tests

Run the tests on the Flutter VM:

```sh
fvm flutter test test/memory
```

The local `flutter_test_config.dart` enables
[leak_tracker](https://github.com/dart-lang/leak_tracker/blob/main/doc/leak_tracking/OVERVIEW.md)
for this folder. These tests are also discovered by the normal `flutter test`
command. The tracker reports missing disposal, and checks garbage collection of
grid managers, focus nodes, editing controllers, animations and scroll resources.
Flutter test-binding fixtures are excluded; helpers inside `test/memory` remain
tracked. One permanent Flutter `_NullElement` placeholder is allowed per test
phase. No grid resource classes are excluded from disposal checks.

The tests cover:

- Repeated mounting, editing, filtering, pagination, scrolling and unmounting,
  including frozen columns and closed event/key streams.
- Resize-notifier disposal and cancellation of delayed grid events.
- Repeated dual-grid disposal, including its resize notifier.
- Column-map updates after insertion and removal, and collection of removed
  columns and captured renderer data while the manager remains alive.
- Infinite-scroll responses arriving after disposal or out of order, plus
  loading-state recovery and retry after synchronous or asynchronous failures.
- Collection of columns, groups, rows, filters, captured filter data and grouping
  delegates while the disposed manager itself remains reachable. Weak references
  and explicit GC cover these model objects, which lack allocation events.
- Clearing collapsed descendants without removing caller-owned row data.
- Creating only mounted elements during horizontal virtualization.
- Lazy key and sorting allocations across 100,000 cells, including sorting-cache
  reuse and invalidation after an edit.

## Heap benchmarks

These run separately from the normal suite and require VM Service:

```sh
fvm flutter test --enable-vmservice benchmark/grid_disposal_memory_test.dart
fvm flutter test --enable-vmservice benchmark/cell_memory_test.dart
```

The disposal benchmark creates 200,000 cells per cycle, retains the disposed
manager, and checks that live cell, row and column counts return to their baseline
after GC in all three cycles. It prints `GRID_DISPOSAL_MEMORY` with heap deltas
and retained-object counts. Set `PLUTO_GRID_DISPOSAL_MEMORY_REPORT` to a JSON file
path to save the report.

The cell benchmark compares one million cells with eager key/sorting allocations
against the existing lazy implementation. It prints `CELL_MEMORY`; set
`PLUTO_CELL_MEMORY_REPORT` to save its JSON report.

Heap deltas are diagnostic measurements: warmup, JIT and profiling allocations
can remain after disposal. The disposal regression assertions use live model
counts rather than an absolute RSS threshold. These VM tests do not measure
native, GPU or browser memory, or production application retention paths.

The Coverage workflow runs the normal suite, including memory regression tests,
on pull requests and pushes to `master` or `feature/aso.dev`. Its separate
`memory-benchmarks` job runs both heap benchmarks and uploads their JSON reports
as a `memory-benchmarks` artifact for 14 days.
