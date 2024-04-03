import 'package:a1/a1.dart';
import 'package:test/test.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  group('Cell Dependency Tracker - base operations', () {
    CellDependencyTracker tracker = CellDependencyTracker();
    final testSet = {'ZZ1'.a1, 'XY23'.a1};
    setUp(() {
      tracker = CellDependencyTracker();
      tracker.addDependants('Z26'.a1, testSet);
    });
    test(' add dependants', () async {
      tracker.addDependants('A1'.a1, testSet);
      expect(tracker['A1'.a1], containsAll(testSet));
    });
    test(' remove dependants', () async {
      tracker.removeDependants('Z26'.a1, {'XY23'.a1});
      expect(tracker['Z26'.a1], containsAll({'ZZ1'.a1}));

      tracker.removeDependants('Z26'.a1, {'ZZ1'.a1});
      expect(tracker.length, isZero);
    });
    test(' move dependants', () async {
      tracker.moveDependants('Z26'.a1, 'TT10'.a1);
      expect(tracker['TT10'.a1], containsAll(testSet));
      expect(tracker['Z26'.a1], isNull);
    });
    test(' clear dependants', () async {
      tracker.clear();
      expect(tracker.length, isZero);
    });
  });
  group('Cell Dependency Tracker - move', () {
    CellDependencyTracker tracker = CellDependencyTracker();

    //    Sheet
    //      A      B      C
    // 1   +B1+C2 +A2     +C2*A2
    // 2          +B3-B1
    // 3   +B3             +A2/C2
    //
    // eg. A2 has B1,C1 as dependants
    final sheetDependants = {
      // A
      'A1'.a1: <A1>{},
      'A2'.a1: {'B1', 'C1'}.a1,
      'A3'.a1: <A1>{},
      // B
      'B1'.a1: {'A1', 'B2'}.a1,
      'B2'.a1: <A1>{},
      'B3'.a1: {'A3', 'B2'}.a1,
      // C
      'C1'.a1: <A1>{},
      'C2'.a1: {'A1', 'C1', 'C3'}.a1,
      'C3'.a1: <A1>{},
    };
    setUp(() {
      tracker = CellDependencyTracker();
      for (final MapEntry(:key, :value) in sheetDependants.entries) {
        if (value.isNotEmpty) {
          tracker.addDependants(key, value);
        }
      }
    });
    test(' move column A to D', () async {
      final changed = tracker.moveColumns('A1'.a1.column, 'D1'.a1.column);
      expect(changed.moved, containsPair('a2'.a1, 'd2'.a1));
      expect(changed.deleted.isEmpty, isTrue);
      expect(tracker['A2'.a1], isNull);
      expect(tracker['D2'.a1], containsAll({'B1', 'C1'}.a1));
    });
    test(' move column C to B', () async {
      final changed = tracker.moveColumns('C1'.a1.column, 'B1'.a1.column);
      expect(changed.moved, containsPair('c2'.a1, 'b2'.a1));
      expect(changed.deleted, containsPair('b1'.a1, {'A1', 'B2'}.a1));
      expect(changed.deleted, containsPair('b3'.a1, {'A3', 'B2'}.a1));
      expect(tracker['C2'.a1], isNull);
      expect(tracker['B2'.a1], containsAll({'A1', 'C1', 'C3'}.a1));
    });

    test(' move column A,B to D', () async {
      final changed = tracker.moveColumns('A1'.a1.column, 'D1'.a1.column, 2);
      expect(changed.moved, containsPair('a2'.a1, 'd2'.a1));
      expect(changed.moved, containsPair('b1'.a1, 'e1'.a1));
      expect(changed.moved, containsPair('b3'.a1, 'e3'.a1));
      expect(changed.deleted.isEmpty, isTrue);
      expect(tracker['A2'.a1], isNull);
      expect(tracker['B1'.a1], isNull);
      expect(tracker['B3'.a1], isNull);
      expect(tracker['D2'.a1], containsAll({'B1', 'C1'}.a1));
      expect(tracker['E1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(tracker['E3'.a1], containsAll({'A3', 'B2'}.a1));
    });

    test(' move column A,B to B', () async {
      final changed = tracker.moveColumns('A1'.a1.column, 'B1'.a1.column, 2);
      expect(changed.moved, containsPair('a2'.a1, 'b2'.a1));
      expect(changed.moved, containsPair('b1'.a1, 'c1'.a1));
      expect(changed.moved, containsPair('b3'.a1, 'c3'.a1));
      expect(changed.deleted, containsPair('c2'.a1, {'A1', 'C1', 'C3'}.a1));
      expect(tracker['A1'.a1], isNull);
      expect(tracker['A2'.a1], isNull);
      expect(tracker['A3'.a1], isNull);
      expect(tracker['B1'.a1], isNull);
      expect(tracker['B2'.a1], containsAll({'B1', 'C1'}.a1));
      expect(tracker['B3'.a1], isNull);
      expect(tracker['C1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(tracker['C2'.a1], isNull);
      expect(tracker['C3'.a1], containsAll({'A3', 'B2'}.a1));
    });
    test(' move column B,C to A', () async {
      final changed = tracker.moveColumns('B1'.a1.column, 'A1'.a1.column, 2);
      expect(changed.moved, containsPair('b1'.a1, 'a1'.a1));
      expect(changed.moved, containsPair('b3'.a1, 'a3'.a1));
      expect(changed.moved, containsPair('c2'.a1, 'b2'.a1));
      expect(changed.deleted, containsPair('a2'.a1, {'B1', 'C1'}.a1));
      expect(tracker['C1'.a1], isNull);
      expect(tracker['C2'.a1], isNull);
      expect(tracker['C3'.a1], isNull);
      expect(tracker['A1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(tracker['A2'.a1], isNull);
      expect(tracker['A3'.a1], containsAll({'A3', 'B2'}.a1));
      expect(tracker['B1'.a1], isNull);
      expect(tracker['B2'.a1], containsAll({'A1', 'C1', 'C3'}.a1));
      expect(tracker['B3'.a1], isNull);
    });

    test(' move row 1 to 3', () async {
      final changed = tracker.moveRows('A1'.a1.row, 'A3'.a1.row);
      expect(changed.moved, containsPair('b1'.a1, 'b3'.a1));
      expect(changed.deleted, containsPair('b3'.a1, {'a3', 'b2'}.a1));
      expect(tracker['A1'.a1], isNull);
      expect(tracker['B1'.a1], isNull);
      expect(tracker['C1'.a1], isNull);
      expect(tracker['A3'.a1], isNull);
      expect(tracker['B3'.a1], containsAll({'A1', 'B2'}.a1));
      expect(tracker['C3'.a1], isNull);
    });
    test(' move row 3 to 4', () async {
      final changed = tracker.moveRows('A3'.a1.row, 'A4'.a1.row);
      expect(changed.moved, containsPair('b3'.a1, 'b4'.a1));
      expect(changed.deleted.isEmpty, isTrue);
      expect(tracker['B3'.a1], isNull);
      expect(tracker['B4'.a1], containsAll({'A3', 'B2'}.a1));
    });

    test(' move row 1,2 to 4', () async {
      final changed = tracker.moveRows('A1'.a1.row, 'D4'.a1.row, 2);
      expect(changed.moved, containsPair('b1'.a1, 'b4'.a1));
      expect(changed.moved, containsPair('a2'.a1, 'a5'.a1));
      expect(changed.moved, containsPair('c2'.a1, 'c5'.a1));
      expect(changed.deleted.isEmpty, isTrue);
      expect(tracker['B1'.a1], isNull);
      expect(tracker['A2'.a1], isNull);
      expect(tracker['C2'.a1], isNull);
      expect(tracker['B4'.a1], containsAll({'A1', 'B2'}.a1));
      expect(tracker['A5'.a1], containsAll({'B1', 'C1'}.a1));
      expect(tracker['C5'.a1], containsAll({'A1', 'C1', 'C3'}.a1));
    });

    test(' move row 1,2 to 2', () async {
      final changed = tracker.moveRows('A1'.a1.row, 'A2'.a1.row, 2);
      expect(changed.moved, containsPair('b1'.a1, 'b2'.a1));
      expect(changed.moved, containsPair('a2'.a1, 'a3'.a1));
      expect(changed.moved, containsPair('c2'.a1, 'c3'.a1));
      expect(tracker['B1'.a1], isNull);
      expect(tracker['A2'.a1], isNull);
      expect(tracker['C2'.a1], isNull);

      expect(tracker['A2'.a1], isNull);
      expect(tracker['B2'.a1], containsAll({'A1', 'B2'}.a1));
      expect(tracker['C2'.a1], isNull);
      expect(tracker['A3'.a1], containsAll({'B1', 'C1'}.a1));
      expect(tracker['B3'.a1], isNull);
      expect(tracker['C3'.a1], containsAll({'A1', 'C1', 'C3'}.a1));
    });

    test(' move row 2,3 to 1', () async {
      final changed = tracker.moveRows('A2'.a1.row, 'A1'.a1.row, 2);
      expect(changed.moved, containsPair('a2'.a1, 'a1'.a1));
      expect(changed.moved, containsPair('c2'.a1, 'c1'.a1));
      expect(changed.moved, containsPair('b3'.a1, 'b2'.a1));
      expect(tracker['A3'.a1], isNull);
      expect(tracker['B3'.a1], isNull);
      expect(tracker['C3'.a1], isNull);
      expect(tracker['A1'.a1], containsAll({'B1', 'C1'}.a1));
      expect(tracker['B1'.a1], isNull);
      expect(tracker['C1'.a1], containsAll({'A1', 'C1', 'C3'}.a1));
      expect(tracker['A2'.a1], isNull);
      expect(tracker['B2'.a1], containsAll({'A3', 'B2'}.a1));
      expect(tracker['C2'.a1], isNull);
    });
  });
  group('Cell Dependency Tracker - Clear rows/columns', () {
    CellDependencyTracker tracker = CellDependencyTracker();

    //    Sheet
    //      A      B      C
    // 1   +B1+C2 +A2     +C2*A2
    // 2          +B3-B1
    // 3   +B3             +A2/C2
    //
    // eg. A2 has B1,C1 as dependants
    final sheetDependants = {
      // A
      'A1'.a1: <A1>{},
      'A2'.a1: {'B1', 'C1'}.a1,
      'A3'.a1: <A1>{},
      // B
      'B1'.a1: {'A1', 'B2'}.a1,
      'B2'.a1: <A1>{},
      'B3'.a1: {'A3', 'B2'}.a1,
      // C
      'C1'.a1: <A1>{},
      'C2'.a1: {'A1', 'C1', 'C3'}.a1,
      'C3'.a1: <A1>{},
    };
    setUp(() {
      tracker = CellDependencyTracker();
      for (final MapEntry(:key, :value) in sheetDependants.entries) {
        if (value.isNotEmpty) {
          tracker.addDependants(key, value);
        }
      }
    });
    test(' clear column A', () async {
      final cleared = tracker.clearColumns('A1'.a1.column);
      expect(cleared.deleted['a2'.a1], containsAll({'B1', 'C1'}.a1));
      expect(tracker['A1'.a1], isNull);
      expect(tracker['A2'.a1], isNull);
      expect(tracker['A3'.a1], isNull);
    });
    test(' clear column A,B', () async {
      final cleared = tracker.clearColumns('A1'.a1.column, 2);
      expect(cleared.deleted['a2'.a1], containsAll({'B1', 'C1'}.a1));
      expect(cleared.deleted['b1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(cleared.deleted['b3'.a1], containsAll({'A3', 'B2'}.a1));
      expect(tracker['A1'.a1], isNull);
      expect(tracker['A2'.a1], isNull);
      expect(tracker['A3'.a1], isNull);
      expect(tracker['B1'.a1], isNull);
      expect(tracker['B2'.a1], isNull);
      expect(tracker['B3'.a1], isNull);
    });
    test(' clear row 2', () async {
      final cleared = tracker.clearRows('A1'.a1.row);
      expect(cleared.deleted['b1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(tracker['A1'.a1], isNull);
      expect(tracker['B1'.a1], isNull);
      expect(tracker['C1'.a1], isNull);
    });
    test(' clear row 2,3', () async {
      final cleared = tracker.clearRows('A2'.a1.row, 2);
      expect(cleared.deleted['a2'.a1], containsAll({'B1', 'C1'}.a1));
      expect(cleared.deleted['b3'.a1], containsAll({'A3', 'B2'}.a1));
      expect(cleared.deleted['c2'.a1], containsAll({'A1', 'C1', 'C3'}.a1));
      expect(tracker['A2'.a1], isNull);
      expect(tracker['B2'.a1], isNull);
      expect(tracker['C2'.a1], isNull);
      expect(tracker['A3'.a1], isNull);
      expect(tracker['B3'.a1], isNull);
      expect(tracker['C3'.a1], isNull);
    });
  });

  group('Cell Dependency Tracker - Delete rows/columns', () {
    CellDependencyTracker tracker = CellDependencyTracker();

    //    Sheet
    //      A      B      C
    // 1   +B1+C2 +A2     +C2*A2
    // 2          +B3-B1
    // 3   +B3             +A2/C2
    //
    // eg. A2 has B1,C1 as dependants
    final sheetDependants = {
      // A
      'A1'.a1: <A1>{},
      'A2'.a1: {'B1', 'C1'}.a1,
      'A3'.a1: <A1>{},
      // B
      'B1'.a1: {'A1', 'B2'}.a1,
      'B2'.a1: <A1>{},
      'B3'.a1: {'A3', 'B2'}.a1,
      // C
      'C1'.a1: <A1>{},
      'C2'.a1: {'A1', 'C1', 'C3'}.a1,
      'C3'.a1: <A1>{},
    };
    setUp(() {
      tracker = CellDependencyTracker();
      for (final MapEntry(:key, :value) in sheetDependants.entries) {
        if (value.isNotEmpty) {
          tracker.addDependants(key, value);
        }
      }
    });
    test(' delete column A', () async {
      final cleared = tracker.deleteColumns('A1'.a1.column);
      expect(cleared.deleted['a2'.a1], containsAll({'B1', 'C1'}.a1));
      expect(tracker['A1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(tracker['A2'.a1], isNull);
      expect(tracker['A3'.a1], containsAll({'A3', 'B2'}.a1));
      expect(tracker['B1'.a1], isNull);
      expect(tracker['B2'.a1], containsAll({'A1', 'C1', 'C3'}.a1));
      expect(tracker['B3'.a1], isNull);
    });
    test(' delete column A,B', () async {
      final cleared = tracker.deleteColumns('A1'.a1.column, 2);
      expect(cleared.deleted['a2'.a1], containsAll({'B1', 'C1'}.a1));
      expect(cleared.deleted['b1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(cleared.deleted['b3'.a1], containsAll({'A3', 'B2'}.a1));

      expect(tracker['A1'.a1], isNull);
      expect(tracker['A2'.a1], containsAll({'A1', 'C1', 'C3'}.a1));
      expect(tracker['A3'.a1], isNull);

      expect(tracker['B1'.a1], isNull);
      expect(tracker['B2'.a1], isNull);
      expect(tracker['B3'.a1], isNull);

      expect(tracker['C1'.a1], isNull);
      expect(tracker['C2'.a1], isNull);
      expect(tracker['C3'.a1], isNull);
    });
    test(' delete column A,B,C', () async {
      final cleared = tracker.deleteColumns('A1'.a1.column, 3);
      expect(cleared.deleted['a2'.a1], containsAll({'B1', 'C1'}.a1));
      expect(cleared.deleted['b1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(cleared.deleted['b3'.a1], containsAll({'A3', 'B2'}.a1));
      expect(cleared.deleted['c2'.a1], containsAll({'A1', 'C1', 'C3'}.a1));

      expect(tracker['A1'.a1], isNull);
      expect(tracker['A2'.a1], isNull);
      expect(tracker['A3'.a1], isNull);

      expect(tracker['B1'.a1], isNull);
      expect(tracker['B2'.a1], isNull);
      expect(tracker['B3'.a1], isNull);

      expect(tracker['C1'.a1], isNull);
      expect(tracker['C2'.a1], isNull);
      expect(tracker['C3'.a1], isNull);
    });
    test(' delete column B,C', () async {
      final cleared = tracker.deleteColumns('B1'.a1.column, 3);
      expect(cleared.deleted['b1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(cleared.deleted['b3'.a1], containsAll({'A3', 'B2'}.a1));
      expect(cleared.deleted['c2'.a1], containsAll({'A1', 'C1', 'C3'}.a1));

      expect(tracker['A1'.a1], isNull);
      expect(tracker['A2'.a1], {'B1', 'C1'}.a1);
      expect(tracker['A3'.a1], isNull);

      expect(tracker['B1'.a1], isNull);
      expect(tracker['B2'.a1], isNull);
      expect(tracker['B3'.a1], isNull);

      expect(tracker['C1'.a1], isNull);
      expect(tracker['C2'.a1], isNull);
      expect(tracker['C3'.a1], isNull);
    });
    test(' delete row 1', () async {
      final cleared = tracker.deleteRows('A1'.a1.row);
      expect(cleared.deleted['b1'.a1], containsAll({'A1', 'B2'}.a1));

      expect(tracker['A1'.a1], containsAll({'B1', 'C1'}.a1));
      expect(tracker['B1'.a1], isNull);
      expect(tracker['C1'.a1], containsAll({'A1', 'C1', 'C3'}.a1));

      expect(tracker['A2'.a1], isNull);
      expect(tracker['B2'.a1], containsAll({'A3', 'B2'}.a1));
      expect(tracker['C2'.a1], isNull);

      expect(tracker['A3'.a1], isNull);
      expect(tracker['B3'.a1], isNull);
      expect(tracker['C3'.a1], isNull);
    });
    test(' delete row 1,2', () async {
      final cleared = tracker.deleteRows('A1'.a1.row, 2);
      expect(cleared.deleted['b1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(cleared.deleted['a2'.a1], containsAll({'B1', 'C1'}.a1));
      expect(cleared.deleted['c2'.a1], containsAll({'A1', 'C1', 'C3'}.a1));

      expect(tracker['A1'.a1], isNull);
      expect(tracker['A2'.a1], isNull);
      expect(tracker['A3'.a1], isNull);

      expect(tracker['B1'.a1], containsAll({'A3', 'B2'}.a1));
      expect(tracker['B2'.a1], isNull);
      expect(tracker['B3'.a1], isNull);

      expect(tracker['C1'.a1], isNull);
      expect(tracker['C2'.a1], isNull);
      expect(tracker['C3'.a1], isNull);
    });
    test(' delete column A,B,C', () async {
      final cleared = tracker.deleteRows('A1'.a1.row, 3);
      expect(cleared.deleted['b1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(cleared.deleted['a2'.a1], containsAll({'B1', 'C1'}.a1));
      expect(cleared.deleted['c2'.a1], containsAll({'A1', 'C1', 'C3'}.a1));
      expect(cleared.deleted['b3'.a1], containsAll({'A3', 'B2'}.a1));

      expect(tracker['A1'.a1], isNull);
      expect(tracker['A2'.a1], isNull);
      expect(tracker['A3'.a1], isNull);

      expect(tracker['B1'.a1], isNull);
      expect(tracker['B2'.a1], isNull);
      expect(tracker['B3'.a1], isNull);

      expect(tracker['C1'.a1], isNull);
      expect(tracker['C2'.a1], isNull);
      expect(tracker['C3'.a1], isNull);
    });
    test(' delete column B,C', () async {
      final cleared = tracker.deleteRows('A2'.a1.row, 3);
      expect(cleared.deleted['a2'.a1], containsAll({'B1', 'C1'}.a1));
      expect(cleared.deleted['c2'.a1], containsAll({'A1', 'C1', 'C3'}.a1));
      expect(cleared.deleted['b3'.a1], containsAll({'A3', 'B2'}.a1));

      expect(tracker['A1'.a1], isNull);
      expect(tracker['A2'.a1], isNull);
      expect(tracker['A3'.a1], isNull);

      expect(tracker['B1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(tracker['B2'.a1], isNull);
      expect(tracker['B3'.a1], isNull);

      expect(tracker['C1'.a1], isNull);
      expect(tracker['C2'.a1], isNull);
      expect(tracker['C3'.a1], isNull);
    });
  });

  group('Cell Dependency Tracker - Insert rows/columns', () {
    CellDependencyTracker tracker = CellDependencyTracker();

    //    Sheet
    //      A      B      C
    // 1   +B1+C2 +A2     +C2*A2
    // 2          +B3-B1
    // 3   +B3             +A2/C2
    //
    // eg. A2 has B1,C1 as dependants
    final sheetDependants = {
      // A
      'A1'.a1: <A1>{},
      'A2'.a1: {'B1', 'C1'}.a1,
      'A3'.a1: <A1>{},
      // B
      'B1'.a1: {'A1', 'B2'}.a1,
      'B2'.a1: <A1>{},
      'B3'.a1: {'A3', 'B2'}.a1,
      // C
      'C1'.a1: <A1>{},
      'C2'.a1: {'A1', 'C1', 'C3'}.a1,
      'C3'.a1: <A1>{},
    };
    setUp(() {
      tracker = CellDependencyTracker();
      for (final MapEntry(:key, :value) in sheetDependants.entries) {
        if (value.isNotEmpty) {
          tracker.addDependants(key, value);
        }
      }
    });
    test(' insert column at A', () async {
      final shifted = tracker.insertColumns('A1'.a1.column, 1);
      expect(shifted.deleted.isEmpty, isTrue);
      expect(shifted.moved, containsPair('a2'.a1, 'b2'.a1));
      expect(shifted.moved, containsPair('b1'.a1, 'c1'.a1));
      expect(shifted.moved, containsPair('b3'.a1, 'c3'.a1));
      expect(shifted.moved, containsPair('c2'.a1, 'd2'.a1));

      expect(tracker['A1'.a1], isNull);
      expect(tracker['A2'.a1], isNull);
      expect(tracker['A3'.a1], isNull);
    });
    test(' insert 2 columns at B', () async {
      final shifted = tracker.insertColumns('B1'.a1.column, 2);
      expect(shifted.deleted.isEmpty, isTrue);
      expect(shifted.moved, containsPair('b1'.a1, 'd1'.a1));
      expect(shifted.moved, containsPair('b3'.a1, 'd3'.a1));
      expect(shifted.moved, containsPair('c2'.a1, 'e2'.a1));

      expect(tracker['A1'.a1], isNull);
      expect(tracker['A2'.a1], containsAll({'B1', 'C1'}.a1));
      expect(tracker['A3'.a1], isNull);
      expect(tracker['B1'.a1], isNull);
      expect(tracker['B2'.a1], isNull);
      expect(tracker['B3'.a1], isNull);
      expect(tracker['D1'.a1], containsAll({'A1', 'B2'}.a1));
    });
    test(' insert row at 1', () async {
      final shifted = tracker.insertRows('A1'.a1.row, 1);
      expect(shifted.deleted.isEmpty, isTrue);
      expect(shifted.moved, containsPair('b1'.a1, 'b2'.a1));
      expect(shifted.moved, containsPair('a2'.a1, 'a3'.a1));
      expect(shifted.moved, containsPair('c2'.a1, 'c3'.a1));
      expect(shifted.moved, containsPair('b3'.a1, 'b4'.a1));

      expect(tracker['A1'.a1], isNull);
      expect(tracker['B1'.a1], isNull);
      expect(tracker['C1'.a1], isNull);
    });
    test(' insert 2 rows at 2', () async {
      final shifted = tracker.insertRows('A2'.a1.row, 2);
      expect(shifted.deleted.isEmpty, isTrue);

      expect(shifted.moved, containsPair('c2'.a1, 'c4'.a1));
      expect(shifted.moved, containsPair('b3'.a1, 'b5'.a1));

      expect(tracker['A1'.a1], isNull);
      expect(tracker['B1'.a1], containsAll({'A1', 'B2'}.a1));
      expect(tracker['C1'.a1], isNull);

      expect(tracker['A2'.a1], isNull);
      expect(tracker['B2'.a1], isNull);
      expect(tracker['C2'.a1], isNull);

      expect(tracker['A3'.a1], isNull);
      expect(tracker['B3'.a1], isNull);
      expect(tracker['C3'.a1], isNull);

      expect(tracker['A4'.a1], containsAll({'B1', 'C1'}.a1));
      expect(tracker['B4'.a1], isNull);
      expect(tracker['C4'.a1], containsAll({'A1', 'C1', 'C3'}.a1));

      expect(tracker['A5'.a1], isNull);
      expect(tracker['B5'.a1], containsAll({'A3', 'B2'}.a1));
      expect(tracker['C5'.a1], isNull);
    });
  });
}
