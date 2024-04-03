import 'dart:collection';
import 'dart:core';
import 'dart:math';

import 'package:a1/a1.dart';

class CellsChanged {
  Map<A1, A1> moved = {};
  Map<A1, Set<A1>> deleted = {};
}

class CellDependencyTracker {
  final Map<A1, Set<A1>> _dependencyMap = {}; // A1 <- dependants{A1}

  Set<A1>? operator [](A1 a1) => _dependencyMap[a1];
  clear() => _dependencyMap.clear();
  int get length => _dependencyMap.length;

  int get _maxRow =>
      _dependencyMap.keys.fold(0, (acc, a1) => a1.row > acc ? a1.row : acc);

  int get _maxColumn => _dependencyMap.keys
      .fold(0, (acc, a1) => a1.column > acc ? a1.column : acc);

  void addDependants(A1 to, Set<A1> dependants) {
    Set<A1> set = _dependencyMap[to] ?? HashSet<A1>();
    set.addAll(dependants);
    _dependencyMap[to] = set;
  }

  void removeDependants(A1 to, Set<A1> dependants) {
    Set<A1> set = _dependencyMap[to] ?? HashSet<A1>();
    set.removeAll(dependants);
    if (set.isEmpty) {
      _dependencyMap.remove(to);
    }
  }

  void moveDependants(A1 from, A1 to) {
    Set<A1>? dependants = _dependencyMap[from];
    if (dependants?.isNotEmpty ?? false) {
      _dependencyMap[to] = dependants!;
    } else {
      _dependencyMap.remove(to);
    }
    _dependencyMap.remove(from);
  }

  CellsChanged moveColumns(int from, int to, [int columns = 1]) {
    CellsChanged changed = CellsChanged();
    if (columns < 1) return changed;
    var dx = to - from;

    // Columns to move, starting from right if moving to the right
    // or left if moving to the left to avoid copying over
    List<int> moveColumns = List.generate(columns, (index) => from + index);

    for (final column in dx.isNegative ? moveColumns : moveColumns.reversed) {
      for (int row = 0; row <= _maxRow; row++) {
        var a1 = A1.fromVector(column, row);
        var newA1 = A1.fromVector(a1.column + dx, a1.row);
        print('Moving $a1 to $newA1');
        if (_dependencyMap.containsKey(newA1)) {
          changed.deleted[newA1] = _dependencyMap[newA1]!;
        }
        if (_dependencyMap.containsKey(a1)) {
          changed.moved[a1] = newA1;
        }
        moveDependants(a1, newA1);
      }
    }
    return changed;
  }

  CellsChanged moveRows(int from, int to, [int rows = 1]) {
    CellsChanged changed = CellsChanged();
    if (rows < 1) return changed;
    var dy = to - from;

    // Rows to move, starting from bottom if moving down
    // or top if up to avoid copying over
    List<int> moveRows = List.generate(rows, (index) => from + index);

    for (final row in dy.isNegative ? moveRows : moveRows.reversed) {
      for (int column = 0; column <= _maxColumn; column++) {
        var a1 = A1.fromVector(column, row);
        var newA1 = A1.fromVector(a1.column, a1.row + dy);
        print('Moving $a1 to $newA1');
        if (_dependencyMap.containsKey(newA1)) {
          changed.deleted[newA1] = _dependencyMap[newA1]!;
        }
        if (_dependencyMap.containsKey(a1)) {
          changed.moved[a1] = newA1;
        }
        moveDependants(a1, newA1);
      }
    }
    return changed;
  }

  CellsChanged clearColumns(int from, [int columns = 1]) {
    final keys = _dependencyMap.keys
        .where((d) => d.column >= from && d.column < (from + columns))
        .toSet();
    return _clearFunc(from, columns, keys);
  }

  CellsChanged clearRows(int from, [int rows = 1]) {
    final keys = _dependencyMap.keys
        .where((d) => d.row >= from && d.row < (from + rows))
        .toSet();
    return _clearFunc(from, rows, keys);
  }

  CellsChanged _clearFunc(int from, int count, Set<A1> keys) {
    final cleared = CellsChanged();
    for (final key in keys) {
      cleared.deleted[key] = _dependencyMap[key]!;
      _dependencyMap.remove(key);
    }
    return cleared;
  }

  CellsChanged deleteColumns(int column, [int columns = 1]) {
    if (columns < 1) return CellsChanged();

    // delete columns by moving all columns to the right over the top.
    // taking at least the column count if there is less cells available
    final count = max(1 + _maxColumn - (column + columns), columns);
    // print('from:${column + columns} to:$column maxColumns:$count');
    return moveColumns(
      column + columns,
      column,
      count,
    );
  }

  CellsChanged deleteRows(int row, [int rows = 1]) {
    if (rows < 1) return CellsChanged();

    // delete columns by moving all columns to the right over the top.
    // taking at least the column count if there is less cells available
    return moveRows(
      row + rows,
      row,
      max(1 + _maxRow - (row + rows), rows),
    );
  }

  CellsChanged insertColumns(int column, [int columns = 1]) {
    if (columns < 1) return CellsChanged();

    // move columns from column to the right by columns
    return moveColumns(
        column, column + columns, max(1, 1 + _maxColumn - column));
  }

  CellsChanged insertRows(int row, [int rows = 1]) {
    if (rows < 1) return CellsChanged();

    // move rows from row down by rows
    return moveRows(row, row + rows, max(1, 1 + _maxRow - row));
  }
}
