// Copyright (c) 2024, Scott Horn.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:a1/a1.dart';

/// Class to store how references cell change
class CellReferencesChanged {
  Map<A1, A1> moved = {};
  Map<A1, Set<A1>> deleted = {};
}

/// Track references to Cells from others Cells as they
/// are added, moved, removed
class CellReferenceTracker {
  final Map<A1, Set<A1>> _referenceToCellMap = {}; // A1=A2+23 A2>A1, A3>A1

  Set<A1>? operator [](A1 a1) => _referenceToCellMap[a1];

  /// clear all references
  clear() => _referenceToCellMap.clear();

  /// total number of cells with references
  int get length => _referenceToCellMap.length;

  /// keys for the [A1] cells with references
  Iterable<A1> get keys => _referenceToCellMap.keys;

  /// Add an [A1] reference from the [A1] cell
  void addReferenceToCell(A1 reference, A1 cell) {
    Set<A1> cellSet = _referenceToCellMap[reference] ?? HashSet<A1>();
    cellSet.add(cell);
    _referenceToCellMap[reference] = cellSet;
  }

  /// Remove the reference from [A1] cell to [A1] reference
  void removeReferenceToCell(A1 reference, A1 cell) {
    Set<A1> cellSet = _referenceToCellMap[reference] ?? HashSet<A1>();
    cellSet.remove(cell);
    if (cellSet.isEmpty) {
      _referenceToCellMap.remove(reference);
    }
  }

  /// Move an [A1] reference from the [A1] origin
  /// to the [A1] destination
  void moveReferencesForCell(A1 origin, A1 destination) {
    Set<A1>? fromReferenceSet = _referenceToCellMap[origin];

    if (fromReferenceSet?.isNotEmpty ?? false) {
      _referenceToCellMap[destination] = fromReferenceSet!;
    } else {
      _referenceToCellMap.remove(destination);
    }
    _referenceToCellMap.remove(origin);
  }
}
