import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

void main() {
  test('read-only views avoid snapshots and ignore the page range', () {
    final FilteredList<int> list = FilteredList<int>(
      initialList: <int>[1, 2, 3, 4],
    )..setFilterRange(FilteredListRange(0, 1));
    final List<int> original = list.originalListView;
    expect(original, <int>[1, 2, 3, 4]);
    expect(list.filterOrOriginalListView, original);
    expect(() => original.add(5), throwsUnsupportedError);
    list.add(5);
    expect(original, <int>[1, 2, 3, 4, 5]);
    list.setFilter((int value) => value.isEven);
    expect(list.filterOrOriginalListView, <int>[2, 4]);
    expect(list.toList(), <int>[2]);
    expect(() => list.filterOrOriginalListView.clear(), throwsUnsupportedError);
  });

  group('refresh filtering after mutations', () {
    final Map<String, (void Function(FilteredList<int>), List<int>)> cases =
        <String, (void Function(FilteredList<int>), List<int>)>{
          'sort': (
            (FilteredList<int> list) =>
                list.sort((int a, int b) => b.compareTo(a)),
            <int>[6, 5, 4, 3, 2, 1],
          ),
          'removeFromOriginal': (
            (FilteredList<int> list) => list.removeFromOriginal(1),
            <int>[2, 3, 4, 5, 6],
          ),
          'removeWhere': (
            (FilteredList<int> list) =>
                list.removeWhere((int value) => value == 2),
            <int>[1, 3, 4, 5, 6],
          ),
          'removeWhereFromOriginal': (
            (FilteredList<int> list) =>
                list.removeWhereFromOriginal((int value) => value.isOdd),
            <int>[2, 4, 6],
          ),
          'retainWhere': (
            (FilteredList<int> list) =>
                list.retainWhere((int value) => value == 2),
            <int>[1, 2, 3, 5, 6],
          ),
          'retainWhereFromOriginal': (
            (FilteredList<int> list) =>
                list.retainWhereFromOriginal((int value) => value.isEven),
            <int>[2, 4, 6],
          ),
          'clear': (
            (FilteredList<int> list) => list.clear(),
            <int>[1, 3, 5, 6],
          ),
          'removeLast': (
            (FilteredList<int> list) => list.removeLast(),
            <int>[1, 2, 3, 5, 6],
          ),
          'removeLastFromOriginal': (
            (FilteredList<int> list) => list.removeLastFromOriginal(),
            <int>[1, 2, 3, 4, 5],
          ),
          'insert': (
            (FilteredList<int> list) => list.insert(1, 8),
            <int>[1, 2, 3, 8, 4, 5, 6],
          ),
          'removeAt': (
            (FilteredList<int> list) => list.removeAt(1),
            <int>[1, 2, 3, 5, 6],
          ),
          'insertAll': (
            (FilteredList<int> list) => list.insertAll(1, <int>[8, 10]),
            <int>[1, 2, 3, 8, 10, 4, 5, 6],
          ),
        };

    for (final String name in cases.keys) {
      test('$name refreshes once and preserves the filtered page', () {
        int filterCalls = 0;
        final FilteredList<int> list =
            FilteredList<int>(
                initialList: <int>[1, 2, 3, 4, 5, 6],
              )
              ..setFilter((int value) {
                filterCalls += 1;
                return value.isEven;
              })
              ..setFilterRange(FilteredListRange(0, 2));
        filterCalls = 0;
        final (void Function(FilteredList<int>) mutate, List<int> expected) =
            cases[name]!;

        mutate(list);

        expect(list.originalList, expected);
        expect(
          list.toList(),
          expected.where((int value) => value.isEven).take(2).toList(),
        );
        expect(filterCalls, expected.length);
      });
    }

    test('a failed mutation restores the filter and page', () {
      int filterCalls = 0;
      final FilteredList<int> list =
          FilteredList<int>(
              initialList: <int>[1, 2, 3, 4, 5, 6],
            )
            ..setFilter((int value) {
              filterCalls += 1;
              return value.isEven;
            })
            ..setFilterRange(FilteredListRange(1, 2));
      filterCalls = 0;

      expect(
        () => list.removeWhereFromOriginal(
          (int value) => throw StateError('Failed predicate'),
        ),
        throwsStateError,
      );

      expect(list.hasFilter, isTrue);
      expect(list.hasRange, isTrue);
      expect(list.toList(), <int>[4]);
      expect(filterCalls, list.originalLength);
    });
  });

  group('Int List 를 짝수로 필터링.', () {
    List<int> originalList;

    late FilteredList<int> list;

    setUp(() {
      originalList = [1, 2, 3, 4, 5, 6, 7, 8, 9];

      list = FilteredList(initialList: originalList);

      list.setFilter((element) => element % 2 == 0);
    });

    test(
      'originalList 가 필터 적용 되지 않은 값이 리턴 되어야 한다.',
      () {
        expect(list.originalList.length, 9);

        list.setFilter(null);

        expect(list.originalList.length, 9);
      },
    );

    test(
      'filteredList 가 필터 적용 된 값이 리턴 되어야 한다.',
      () {
        expect(list.filteredList.length, 4);

        list.setFilter(null);

        expect(list.filteredList.length, 0);
      },
    );

    test(
      'length 가 적용 되어야 한다.',
      () {
        expect(list.length, 4);

        list.setFilter(null);

        expect(list.length, 9);
      },
    );

    test(
      '특정 index 의 값을 리턴 해야 한다.',
      () {
        expect(list[0], 2);
        expect(list.first, 2);

        expect(list[3], 8);
        expect(list.last, 8);

        list.setFilter(null);

        expect(list[0], 1);
        expect(list.first, 1);

        expect(list[8], 9);
        expect(list.last, 9);
      },
    );

    test(
      'Destructuring 리턴 값이 반영 되어야 한다.',
      () {
        expect([...list], [2, 4, 6, 8]);

        list.setFilter(null);

        expect([...list], [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      },
    );

    group('요소를 수정.', () {
      setUp(() {
        list[1] = 40;
      });

      test(
        '수정 한 요소가 반영 되어야 한다.',
        () {
          expect(list, [2, 40, 6, 8]);

          list.setFilter(null);

          expect(list, [1, 2, 3, 40, 5, 6, 7, 8, 9]);
        },
      );

      test(
        'sort 시 수정 한 요소가 반영 되어야 한다.',
        () {
          list.sort();

          expect(list, [2, 6, 8, 40]);

          reverse(int a, int b) => a < b ? 1 : (a > b ? -1 : 0);

          list.sort(reverse);

          expect(list, [40, 8, 6, 2]);

          list.setFilter(null);

          list.sort();

          expect(list, [1, 2, 3, 5, 6, 7, 8, 9, 40]);
        },
      );
    });

    group('요소를 추가.', () {
      setUp(() {
        list.add(10);
      });

      test(
        '추가 한 요소가 반영 되어야 한다.',
        () {
          expect(list, [2, 4, 6, 8, 10]);

          list.setFilter(null);

          expect(list, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
        },
      );

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 5);

          list.setFilter(null);

          expect(list.length, 10);
        },
      );
    });

    group('remove 로 요소를 삭제.', () {
      setUp(() {
        // filtering 된 상태에서 필터링 범위 밖의 리스트는 삭제 되지 않는다.
        var removeOne = list.remove(1);
        expect(removeOne, isFalse);

        var removeTwo = list.remove(2);
        expect(removeTwo, isTrue);
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 3);

          expect(list, [4, 6, 8]);

          list.setFilter(null);

          expect(list.length, 8);

          expect(list, [1, 3, 4, 5, 6, 7, 8, 9]);
        },
      );
    });

    group('removeFromOriginal 로 요소를 삭제.', () {
      setUp(() {
        var removeOne = list.removeFromOriginal(1);
        expect(removeOne, isTrue);

        var removeTwo = list.removeFromOriginal(2);
        expect(removeTwo, isTrue);
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 3);

          expect(list, [4, 6, 8]);

          list.setFilter(null);

          expect(list.length, 7);

          expect(list, [3, 4, 5, 6, 7, 8, 9]);
        },
      );
    });

    group('removeWhere 로 요소를 삭제.', () {
      setUp(() {
        // filtering 된 상태에서 필터링 범위 밖의 리스트는 삭제 되지 않는다.
        list.removeWhere((element) => element == 1);
        list.removeWhere((element) => element == 2);
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 3);

          expect(list, [4, 6, 8]);

          list.setFilter(null);

          expect(list.length, 8);

          expect(list, [1, 3, 4, 5, 6, 7, 8, 9]);
        },
      );
    });

    group('removeWhereFromOriginal 로 요소를 삭제.', () {
      setUp(() {
        list.removeWhereFromOriginal((element) => element == 1);
        list.removeWhereFromOriginal((element) => element == 2);
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 3);

          expect(list, [4, 6, 8]);

          list.setFilter(null);

          expect(list.length, 7);

          expect(list, [3, 4, 5, 6, 7, 8, 9]);
        },
      );
    });

    group('retainWhere 로 요소를 삭제.', () {
      setUp(() {
        // filtering 된 상태에서 필터링 범위 밖의 리스트는 삭제 되지 않는다.
        list.retainWhere((element) => element > 2);
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 3);

          expect(list, [4, 6, 8]);

          list.setFilter(null);

          expect(list.length, 8);

          expect(list, [1, 3, 4, 5, 6, 7, 8, 9]);
        },
      );
    });

    group('retainWhereFromOriginal 로 요소를 삭제.', () {
      setUp(() {
        list.retainWhereFromOriginal((element) => element > 2);
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 3);

          expect(list, [4, 6, 8]);

          list.setFilter(null);

          expect(list.length, 7);

          expect(list, [3, 4, 5, 6, 7, 8, 9]);
        },
      );
    });

    group('clear 로 요소를 삭제.', () {
      setUp(() {
        // filtering 된 상태에서 필터링 범위 밖의 리스트는 삭제 되지 않는다.
        list.clear();
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 0);

          expect(list, <int>[]);

          list.setFilter(null);

          expect(list.length, 5);

          expect(list, [1, 3, 5, 7, 9]);
        },
      );
    });

    group('clearFromOriginal 로 요소를 삭제.', () {
      setUp(() {
        list.clearFromOriginal();
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 0);

          expect(list, <int>[]);

          list.setFilter(null);

          expect(list.length, 0);

          expect(list, <int>[]);
        },
      );
    });

    group('removeLast 로 요소를 삭제.', () {
      setUp(() {
        list.removeLast();
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 3);

          expect(list, [2, 4, 6]);

          list.setFilter(null);

          expect(list.length, 8);

          expect(list, [1, 2, 3, 4, 5, 6, 7, 9]);
        },
      );
    });

    group('removeLastFromOriginal 로 요소를 삭제.', () {
      setUp(() {
        list.removeLastFromOriginal();
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 4);

          expect(list, [2, 4, 6, 8]);

          list.setFilter(null);

          expect(list.length, 8);

          expect(list, [1, 2, 3, 4, 5, 6, 7, 8]);
        },
      );
    });

    group('shuffle 로 요소를 변경.', () {
      setUp(() {
        list.shuffle();
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 4);

          expect(list.contains(2), isTrue);
          expect(list.contains(4), isTrue);
          expect(list.contains(6), isTrue);
          expect(list.contains(8), isTrue);

          list.setFilter(null);

          expect(list.length, 9);

          expect(list.contains(1), isTrue);
          expect(list.contains(2), isTrue);
          expect(list.contains(3), isTrue);
          expect(list.contains(4), isTrue);
          expect(list.contains(5), isTrue);
          expect(list.contains(6), isTrue);
          expect(list.contains(7), isTrue);
          expect(list.contains(8), isTrue);
          expect(list.contains(9), isTrue);
        },
      );
    });

    test(
      'asMap.',
      () {
        final filteredMap = list.asMap();

        expect(filteredMap, {0: 2, 1: 4, 2: 6, 3: 8});

        list.setFilter(null);

        final map = list.asMap();

        expect(map, {0: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 7, 7: 8, 8: 9});
      },
    );

    group('insert 로 2 앞에  -2 요소를 추가.', () {
      setUp(() {
        list.insert(0, -2);
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 5);

          expect(list, [-2, 2, 4, 6, 8]);

          list.setFilter(null);

          expect(list.length, 10);

          expect(list, [1, -2, 2, 3, 4, 5, 6, 7, 8, 9]);
        },
      );
    });

    group('insert 로 8 뒤에  10 요소를 추가.', () {
      setUp(() {
        list.insert(4, 10);
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 5);

          expect(list, [2, 4, 6, 8, 10]);

          list.setFilter(null);

          expect(list.length, 10);

          expect(list, [1, 2, 3, 4, 5, 6, 7, 8, 10, 9]);
        },
      );
    });

    group('removeAt 으로 4 요소를 삭제.', () {
      setUp(() {
        list.removeAt(1);
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 3);

          expect(list, [2, 6, 8]);

          list.setFilter(null);

          expect(list.length, 8);

          expect(list, [1, 2, 3, 5, 6, 7, 8, 9]);
        },
      );

      test(
        '필터링 된 범위 밖의 index 접근 시 오류를 발생 시켜야 한다.',
        () {
          expect(list.length, 3);

          expect(
            () => list.removeAt(3),
            throwsA(const TypeMatcher<RangeError>()),
          );

          list.setFilter(null);

          expect(list.length, 8);

          expect(
            () => list.removeAt(8),
            throwsA(const TypeMatcher<RangeError>()),
          );
        },
      );
    });

    group('insertAll 로 2 앞에  [-3, -2] 요소를 추가.', () {
      setUp(() {
        list.insertAll(0, [-3, -2]);
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 5);

          expect(list, [-2, 2, 4, 6, 8]);

          list.setFilter(null);

          expect(list.length, 11);

          expect(list, [1, -3, -2, 2, 3, 4, 5, 6, 7, 8, 9]);
        },
      );
    });

    group('insertAll 로 9 앞에  [-9, -10] 요소를 추가.', () {
      setUp(() {
        list.setFilter(null);

        list.insertAll(8, [-9, -10]);
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 11);

          expect(list, [1, 2, 3, 4, 5, 6, 7, 8, -9, -10, 9]);
        },
      );
    });

    group('insertAll 로 9 뒤에  [10, 11] 요소를 추가.', () {
      setUp(() {
        list.setFilter(null);

        list.insertAll(9, [10, 11]);
      });

      test(
        'length 가 반영 되어야 한다.',
        () {
          expect(list.length, 11);

          expect(list, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
        },
      );
    });
  });

  group('pagination', () {
    late List<int> originalList;

    late FilteredList<int> list;

    setUp(() {
      originalList = [1, 2, 3, 4, 5, 6, 7, 8, 9];

      list = FilteredList(initialList: originalList);
    });

    test('indexed reads stay within the filtered page', () {
      list
        ..setFilter((int value) => value.isEven)
        ..setFilterRange(FilteredListRange(1, 3));

      expect(list.length, 2);
      expect(list.toList(), <int>[4, 6]);
      expect(list.first, 4);
      expect(list.last, 6);
      expect(() => list[-1], throwsRangeError);
      expect(() => list[2], throwsRangeError);
    });

    test('page reads follow range changes and clamp to available rows', () {
      final FilteredListRange range = FilteredListRange(7, 20);
      list.setFilterRange(range);
      expect(list.length, 2);
      expect(list.toList(), <int>[8, 9]);

      range.setRange(-2, 2);
      expect(list.toList(), <int>[1, 2]);
      range.setRange(20, 30);
      expect(list.length, 0);
      expect(list.toList(), isEmpty);
      expect(() => list[0], throwsRangeError);

      list.clearFromOriginal();
      expect(list.length, 0);
      expect(() => list[0], throwsRangeError);
    });

    test('a reversed page range still throws', () {
      list.setFilterRange(FilteredListRange(5, 2));
      expect(() => list.length, throwsRangeError);
      expect(() => list[0], throwsRangeError);
    });

    test('iteration still detects changes to page length', () {
      list.setFilterRange(FilteredListRange(1, 10));
      final Iterator<int> iterator = list.iterator;
      expect(iterator.moveNext(), isTrue);
      list.add(10);
      expect(iterator.moveNext, throwsConcurrentModificationError);
    });

    test(
      '최초 0, 3 을 설정하면 [1, 2, 3] 이 리턴 되어야 한다.',
      () {
        list.setFilterRange(FilteredListRange(0, 3));

        expect(list, [1, 2, 3]);
        expect(list.length, 3);
      },
    );

    test(
      '3, 6 을 설정하면 [4, 5, 6] 이 리턴 되어야 한다.',
      () {
        list.setFilterRange(FilteredListRange(3, 6));

        expect(list, [4, 5, 6]);
        expect(list.length, 3);
      },
    );

    test(
      'filterRange 를 null 로 설정하면 originalList 가 리턴 되어야 한다.',
      () {
        list.setFilterRange(null);

        expect(list, originalList);
        expect(list.length, originalList.length);
      },
    );

    test(
      '다시 3, 6 을 설정하면 [4, 5, 6] 이 리턴 되어야 한다.',
      () {
        list.setFilterRange(FilteredListRange(3, 6));

        expect(list, [4, 5, 6]);
        expect(list.length, 3);
      },
    );
  });

  group('pagination and insertAll', () {
    late List<int> originalList;

    late FilteredList<int> list;

    setUp(() {
      originalList = [1, 2, 3, 4, 5, 6, 7, 8, 9];

      list = FilteredList(initialList: originalList);
    });

    test('0, 3 으로 필터링 한 후 3 다음에 [31, 32] 가 insertAll 되어야 한다.', () {
      list.setFilterRange(FilteredListRange(0, 3));

      expect(list, [1, 2, 3]);

      list.insertAll(3, [31, 32]);

      expect(list.originalList, [1, 2, 3, 31, 32, 4, 5, 6, 7, 8, 9]);
    });

    test('0, 3 으로 필터링 한 후 1 앞에 [31, 32] 가 insertAll 되어야 한다.', () {
      list.setFilterRange(FilteredListRange(0, 3));

      expect(list, [1, 2, 3]);

      list.insertAll(0, [31, 32]);

      expect(list.originalList, [31, 32, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('7, 9 으로 필터링 한 후 9 다음에 [91, 92] 가 insertAll 되어야 한다.', () {
      list.setFilterRange(FilteredListRange(7, 9));

      expect(list, [8, 9]);

      list.insertAll(2, [91, 92]);

      expect(list.originalList, [1, 2, 3, 4, 5, 6, 7, 8, 9, 91, 92]);
    });

    test('7, 9 으로 필터링 한 후 8 다음에 [91, 92] 가 insertAll 되어야 한다.', () {
      list.setFilterRange(FilteredListRange(7, 9));

      expect(list, [8, 9]);

      list.insertAll(1, [91, 92]);

      expect(list.originalList, [1, 2, 3, 4, 5, 6, 7, 8, 91, 92, 9]);
    });

    test('8, 10 으로 필터링 한 후 8 앞에 [91, 92] 가 insertAll 되어야 한다.', () {
      list.setFilterRange(FilteredListRange(7, 9));

      expect(list, [8, 9]);

      list.insertAll(0, [91, 92]);

      expect(list.originalList, [1, 2, 3, 4, 5, 6, 7, 91, 92, 8, 9]);
    });
  });
}
