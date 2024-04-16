import 'dart:collection';
import 'dart:math';

import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

class Sheet with Iterable<A1> {
  final Map<A1, Cell> _cellMap = <A1, Cell>{};
  late final ResultTypeCache resultTypeCache = ResultTypeCache(_cellMap);
  final CellReferenceTracker referencesToCell = CellReferenceTracker();
  final HashSet<CellChangedCallback> _listeners =
      HashSet<CellChangedCallback>();

  /// Set the cell and notify listeners
  void setCell(A1 key, Cell cell) {
    // Clear the cache for cells that depend on this cell
    resultTypeCache.removeAll(referencesToCell[key]);

    _cellMap[key] = cell;
    notifyListeners({key}, CellChangeType.add);
    addReferences(key, cell);
  }

  /// Get the cell at [A1] or null
  Cell? getCell(A1 a1) => _cellMap[a1];

  /// Remove cell
  Cell? removeCell(A1 a1) => _cellMap.remove(a1);

  /// Clear all cells
  void clearCells() => _cellMap.clear();

  /// Check if sheet has this cell
  bool containsCellKey(A1 key) => _cellMap.containsKey(key);

  /// Return the [A1] keys for all cells in this engine
  ///
  /// Example:
  /// ```dart
  /// print(engine.keys); // A2,A3,A4...
  /// ```
  Iterable<A1> get keys => _cellMap.keys;

  /// Iterator that can be used to iterator over cells in the engine
  /// in a simple for statement
  ///
  /// Example:
  /// ```dart
  /// for (final cell in engine.iterator) {
  ///   print(engine[cell]);
  /// }
  /// ```
  @override
  Iterator<A1> get iterator => keys.iterator;

  /// columnsAndRows is a convenience functions that will return the
  /// [int] indexes of the columns and rows in a separated record.
  /// This can be useful to operations on rectangular areas of the sheet,
  /// including empty cells and is used internally by the [move], [copy]
  /// functions.
  ///
  /// The function also takes a call back criteria [Function] that accepts
  /// an [A1] cell and returns a [bool] to decide whether to filter from the
  /// list. The default [Iterable] is all [A1] in the engine, but this can
  /// also be supplied in the a1Iterable method field.
  ///
  /// Example:
  /// ```dart
  /// (colummns,row) = engine.columnsAndRows();
  /// for (final column in colums) {
  ///   for (final row in rows) {
  ///     A1 a1 = A1.fromVector(column, row);
  ///   }
  /// }
  /// ```
  (List<int>, List<int>) columnsAndRows({
    bool Function(A1 cell)? criteria,
    Iterable<A1>? a1Iterable,
  }) {
    final cellsInRange = (a1Iterable ?? keys).where(criteria ?? (_) => true);

    if (cellsInRange.isEmpty) {
      return ([], []);
    }

    // Determine the bounds in the sheet
    var (minCol, minRow) = (cellsInRange.first.column, cellsInRange.first.row);
    var (maxCol, maxRow) = (cellsInRange.first.column, cellsInRange.first.row);
    for (final cell in cellsInRange) {
      if (cell.column > maxCol) maxCol = cell.column;
      if (cell.row > maxRow) maxRow = cell.row;
      if (cell.column < minCol) minCol = cell.column;
      if (cell.row < minRow) minRow = cell.row;
    }
    final columns =
        List.generate(maxCol - minCol + 1, (index) => minCol + index);
    final rows = List.generate(maxRow - minRow + 1, (index) => minRow + index);

    return (columns, rows);
  }

  /// Add a [CellChangedCallback] listener for all changes to the engines cells
  /// The types of changes include all the types in [CellChangeType]
  void addListener(CellChangedCallback listener) => _listeners.add(listener);

  /// Remove a [CellChangeCallback] listener
  void removeListener(CellChangedCallback listener) =>
      _listeners.remove(listener);

  void notifyListeners(Set<A1> a1Set, CellChangeType changeType) {
    for (final listener in _listeners) {
      listener(a1Set, changeType);
    }
  }

  /// Add all the reference from the cell
  void addReferences(A1 location, Cell cellContent) {
    if (cellContent.content is CellContent && cellContent.formulaType != null) {
      FormulaType formulaType = cellContent.formulaType!;
      final referenceSet = formulaType.references;
      for (A1 reference in referenceSet) {
        referencesToCell.addReferenceToCell(reference, location);
      }
      if (referenceSet.isNotEmpty) {
        notifyListeners(referenceSet, CellChangeType.referenceAdd);
      }
    }
  }

  /// Remove all references from the cell location
  void removeReferences(A1 cell) {
    final cellContent = _cellMap[cell];
    if (cellContent != null &&
        cellContent.content is CellContent &&
        cellContent.formulaType != null) {
      final referenceSet = cellContent.formulaType!.references;
      for (final a1 in referenceSet) {
        referencesToCell.removeReferenceToCell(a1, cell);
      }
      if (referenceSet.isNotEmpty) {
        notifyListeners(referenceSet, CellChangeType.referenceDelete);
      }
    }
  }

  /// referencesToString utility method can be helpful for understanding
  /// how cells reference each other.
  ///
  String referencesToString() {
    final (columns, rows) = columnsAndRows(a1Iterable: referencesToCell.keys);
    StringBuffer buffer = StringBuffer();
    for (final row in rows) {
      for (final column in columns) {
        final a1 = A1.fromVector(column, row);
        final cell = "$a1: ${referencesToCell[a1] ?? ''}";
        buffer.write(cell.substring(0, min(cell.length, 20)).padRight(20));
      }
      buffer.write('\n');
    }
    return buffer.toString();
  }

  /// For the reference - move from origin to destination
  /// including rewriting the expression forumula
  void rewriteAndRefreshReference(A1 reference, A1 origin, A1 destination) {
    final cell = getCell(reference);
    if (cell != null && cell.content is ExpressionContent) {
      final formula = cell.formulaType;
      if (formula == null) return;

      // Remove references
      removeReferences(reference);

      // Rewrite formula
      formula.visit((instance) {
        if (instance is ReferenceType && instance.a1 == origin) {
          //print('Moving reference from $origin to $destination');
          instance.moveTo(destination);
        }

        // If we are moving a range sum and the to is expanding, uptdate to
        if (instance is SumFunction && instance.value is ListRangeType) {
          final range = instance.value as ListRangeType;
          if (range.to == origin) {
            range.moveTo(destination);
          } else if (range.from == origin) {
            range.moveFrom(destination);
          }
        }
      });

      resultTypeCache.removeAll({reference});

      // Add Reference back
      addReferences(reference, cell);
    }
  }
}
