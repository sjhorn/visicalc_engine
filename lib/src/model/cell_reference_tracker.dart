import 'dart:collection';
import 'package:a1/a1.dart';

class CellReferencesChanged {
  Map<A1, A1> moved = {};
  Map<A1, Set<A1>> deleted = {};
}

class CellReferenceTracker {
  final Map<A1, Set<A1>> _referenceToCellMap = {}; // A1=A2+23 A2>A1, A3>A1

  Set<A1>? operator [](A1 a1) => _referenceToCellMap[a1];
  clear() => _referenceToCellMap.clear();
  int get length => _referenceToCellMap.length;
  Iterable<A1> get keys => _referenceToCellMap.keys;

  void addReferenceToCell(A1 reference, A1 cell) {
    Set<A1> cellSet = _referenceToCellMap[reference] ?? HashSet<A1>();
    cellSet.add(cell);
    _referenceToCellMap[reference] = cellSet;
  }

  void removeReferenceToCell(A1 reference, A1 cell) {
    Set<A1> cellSet = _referenceToCellMap[reference] ?? HashSet<A1>();
    cellSet.remove(cell);
    if (cellSet.isEmpty) {
      _referenceToCellMap.remove(reference);
    }
  }

  void moveReferencesForCell(A1 from, A1 to) {
    Set<A1>? fromReferenceSet = _referenceToCellMap[from];

    if (fromReferenceSet?.isNotEmpty ?? false) {
      _referenceToCellMap[to] = fromReferenceSet!;
    } else {
      _referenceToCellMap.remove(to);
    }
    _referenceToCellMap.remove(from);
  }
}
