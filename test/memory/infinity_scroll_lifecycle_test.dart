import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  for (final bool fails in <bool>[false, true]) {
    testWidgets(
      'ignores a late ${fails ? 'failure' : 'response'} after disposal',
      (WidgetTester tester) async {
        final _Fetch fetch = _Fetch();
        final PlutoGridStateManager manager = await _mountGrid(
          tester,
          fetch.call,
        );
        expect(fetch.pending, hasLength(1));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(manager.streamNotifier.isClosed, isTrue);

        if (fails) {
          fetch.pending.single.completeError(Exception('late fetch failure'));
        } else {
          fetch.pending.single.complete(_response('late'));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(manager.refRows.originalList, isEmpty);
      },
    );
  }

  for (final bool staleFirst in <bool>[false, true]) {
    testWidgets('sort refresh ignores the stale response arriving '
        '${staleFirst ? 'before' : 'after'} the current response', (
      WidgetTester tester,
    ) async {
      final _Fetch fetch = _Fetch();
      final PlutoGridStateManager manager = await _mountGrid(
        tester,
        fetch.call,
      );
      manager.toggleSortColumn(manager.refColumns.first);
      await tester.pump();
      expect(fetch.pending, hasLength(2));
      final PlutoInfinityScrollRowsResponse current = _response(
        'current',
        isLast: false,
      );

      if (staleFirst) {
        fetch.pending.first.complete(_response('stale'));
        await tester.pump();
        expect(manager.refRows, isEmpty);
        expect(manager.showLoading, isTrue);
      }
      fetch.pending[1].complete(current);
      await tester.pumpAndSettle();
      if (!staleFirst) {
        fetch.pending.first.complete(_response('stale'));
        await tester.pumpAndSettle();
      }
      expect(manager.refRows.originalList, current.rows);
      expect(manager.showLoading, isFalse);

      // A stale isLast=true must not prevent the next page from loading.
      _requestNextPage(manager);
      await tester.pump();
      expect(fetch.pending, hasLength(3));
      expect(fetch.requests.last.lastRow, same(current.rows.last));
      fetch.pending.last.complete(_response('next'));
      await tester.pumpAndSettle();
      expect(manager.refRows.length, 60);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('a stale failure leaves the filter refresh loading', (
    WidgetTester tester,
  ) async {
    final _Fetch fetch = _Fetch();
    final PlutoGridStateManager manager = await _mountGrid(tester, fetch.call);
    manager.setFilterWithFilterRows(<PlutoRow<dynamic>>[
      FilterHelper.createFilterRow(
        columnField: 'value',
        filterValue: 'current',
      ),
    ]);
    await tester.pump();
    expect(fetch.pending, hasLength(2));
    expect(fetch.requests.last.filterRows, isNotEmpty);
    fetch.pending.first.completeError(Exception('stale fetch failure'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(manager.showLoading, isTrue);
    final PlutoInfinityScrollRowsResponse current = _response('current');
    fetch.pending.last.complete(current);
    await tester.pumpAndSettle();
    expect(manager.refRows.originalList, current.rows);
    expect(manager.showLoading, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final bool synchronous in <bool>[false, true]) {
    testWidgets('${synchronous ? 'synchronous' : 'asynchronous'} fetch failure '
        'clears loading and permits retry from an empty grid', (
      WidgetTester tester,
    ) async {
      int calls = 0;
      final Exception failure = Exception('fetch failure');
      final PlutoInfinityScrollRowsResponse recovered = _response('recovered');
      final PlutoGridStateManager manager = await _mountGrid(tester, (
        PlutoInfinityScrollRowsRequest request,
      ) {
        calls++;
        if (calls == 1) {
          if (synchronous) {
            throw failure;
          }
          return Future<PlutoInfinityScrollRowsResponse>.error(failure);
        }
        return Future<PlutoInfinityScrollRowsResponse>.value(recovered);
      });
      expect(tester.takeException(), same(failure));
      expect(manager.showLoading, isFalse);
      expect(manager.refRows, isEmpty);

      _requestNextPage(manager);
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(manager.refRows.originalList, recovered.rows);
      expect(manager.showLoading, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Future<PlutoGridStateManager> _mountGrid(
  WidgetTester tester,
  PlutoInfinityScrollRowsFetch fetch,
) async {
  late PlutoGridStateManager manager;
  await tester.pumpWidget(
    MaterialApp(
      home: Material(
        child: PlutoGrid(
          columns: <PlutoColumn>[
            PlutoColumn(
              title: 'value',
              field: 'value',
              type: PlutoColumnType.text(),
            ),
          ],
          rows: const <PlutoRow<dynamic>>[],
          onLoaded: (PlutoGridOnLoadedEvent event) =>
              manager = event.stateManager,
          createFooter: (PlutoGridStateManager stateManager) =>
              PlutoInfinityScrollRows(fetch: fetch, stateManager: stateManager),
        ),
      ),
    ),
  );
  // Build the footer and flush the first request without waiting on its future.
  await tester.pump();
  await tester.pump();
  return manager;
}

void _requestNextPage(PlutoGridStateManager manager) {
  manager.eventManager!.addEvent(
    PlutoGridCannotMoveCurrentCellEvent(
      cellPosition: const PlutoGridCellPosition(columnIdx: 0, rowIdx: 0),
      direction: PlutoMoveDirection.down,
    ),
  );
}

PlutoInfinityScrollRowsResponse _response(
  String prefix, {
  bool isLast = true,
}) => PlutoInfinityScrollRowsResponse(
  isLast: isLast,
  rows: List<PlutoRow<dynamic>>.generate(
    30,
    (int index) => PlutoRow<dynamic>(
      cells: <String, PlutoCell>{
        'value': PlutoCell(value: '$prefix $index'),
      },
    ),
  ),
);

class _Fetch {
  final List<PlutoInfinityScrollRowsRequest> requests =
      <PlutoInfinityScrollRowsRequest>[];
  final List<Completer<PlutoInfinityScrollRowsResponse>> pending =
      <Completer<PlutoInfinityScrollRowsResponse>>[];

  Future<PlutoInfinityScrollRowsResponse> call(
    PlutoInfinityScrollRowsRequest request,
  ) {
    requests.add(request);
    final Completer<PlutoInfinityScrollRowsResponse> completer =
        Completer<PlutoInfinityScrollRowsResponse>();
    pending.add(completer);
    return completer.future;
  }
}
