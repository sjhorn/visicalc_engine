import 'dart:collection';
import 'dart:math';

import 'package:a1/a1.dart';
import 'package:petitparser/petitparser.dart';
import 'package:visicalc_engine/src/formula/grammar/format_expression.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

enum CellChangeType {
  add,
  update,
  delete,
  referenceAdd,
  referenceUpdate,
  referenceDelete,
}

typedef CellChangedCallback = void Function(
    Set<A1> a1Set, CellChangeType changeType);

class Engine with Iterable<A1> {
  static final formatExpression = FormatExpression().build();
  // static final evaluator = Evaluator().build();
  // static final validator = ValidateExpression().build();

  final HashSet<CellChangedCallback> _listeners =
      HashSet<CellChangedCallback>();
  late final Map<A1, Cell> _cellMap;
  late final ResultTypeCache _resultTypeCache;
  final CellReferenceTracker _referencesToCell = CellReferenceTracker();
  final bool parseErrorThrows;

  // Constructing / parsing cells from strings
  //
  Engine(Map<A1, String> sheet, {this.parseErrorThrows = false}) {
    _cellMap = _parseSheet(sheet);
    _resultTypeCache = ResultTypeCache(_cellMap);
  }

  Map<A1, Cell> _parseSheet(Map<A1, String> sheet) {
    final Map<A1, Cell> varMap = <A1, Cell>{};
    for (final MapEntry(:key, :value) in sheet.entries) {
      final cell = _parse(value);
      varMap[key] = cell;
      _addReferences(key, cell);
    }
    return varMap;
  }

  Cell _parse(String cell) {
    final ast = formatExpression.parse(cell);
    if (ast is Success) {
      final cell = ast.value as Cell;
      cell.resultTypeCacheFunc = () => _resultTypeCache;
      return cell;
    } else {
      if (parseErrorThrows) {
        throw FormatException('Error parsing [$cell]] - ${ast.message}');
      }
      return Cell(
        content: ExpressionContent(ErrorType(ast.message)),
        resultTypeCacheFunc: () => _resultTypeCache,
      );
    }
  }

  // Iterable
  @override
  Iterator<A1> get iterator => keys.iterator;

  // Listeners
  void addListener(CellChangedCallback listener) => _listeners.add(listener);
  void removeListener(CellChangedCallback listener) =>
      _listeners.remove(listener);

  void _notifyListeners(Set<A1> a1Set, CellChangeType changeType) {
    for (final listener in _listeners) {
      listener(a1Set, changeType);
    }
  }

  //
  // Map/list like Methods
  //

  /// Lazily eval and cache
  Cell? operator [](A1 a1) {
    if (_cellMap.containsKey(a1)) {
      return _cellMap[a1];
    }
    return null;
  }

  /// Attempt to parse cell
  void operator []=(A1 key, String? cell) {
    if (_cellMap.containsKey(key)) {
      _resultTypeCache.removeAll({key});
      _removeReferences(key);
      _notifyListeners({key}, CellChangeType.delete);
    }

    if (cell != null && cell.isNotEmpty) {
      final formulaType = _parse(cell);

      // Clear the cache for cells that depend on this cell
      _resultTypeCache.removeAll(_referencesToCell[key]);

      _cellMap[key] = formulaType;
      _notifyListeners({key}, CellChangeType.add);
      _addReferences(key, formulaType);
    } else {
      remove(key);
    }
  }

  void clear() {
    final a1set = keys.toSet();
    final a1Deps = keys.fold(<A1>{},
        (set, a1) => set..addAll(this[a1]?.formulaType?.references ?? {}));
    _cellMap.clear();
    _resultTypeCache.clear();
    _referencesToCell.clear();

    _notifyListeners(a1set, CellChangeType.delete);
    _notifyListeners(a1Deps, CellChangeType.referenceDelete);
  }

  Iterable<A1> get keys => _cellMap.keys;

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

  void _rewriteAndRefreshReference(A1 reference, A1 origin, A1 destination) {
    final cell = _cellMap[reference];
    if (cell != null && cell.content is ExpressionContent) {
      final formula = cell.formulaType;
      if (formula == null) return;

      // Remove references
      _removeReferences(reference);

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

      _resultTypeCache.removeAll({reference});

      // Add Reference back
      _addReferences(reference, cell);
    }
  }

  void move(A1 origin, A1 destination) {
    // Remove destination and mark deleted cells and notify
    remove(destination, markDeleted: true);

    // Rewrite cells references origin to destination
    // and refresh _references/cache
    final cell = _cellMap[origin];
    final originFormula =
        cell?.content is ExpressionContent ? cell?.formulaType : null;
    final references = _referencesToCell[origin] ?? {};

    for (final reference in {...references}) {
      _rewriteAndRefreshReference(reference, origin, destination);
    }

    // Remove the origin and notify
    remove(origin);

    // Add the destination and notify
    this[destination] = originFormula?.asFormula ?? '';
  }

  void moveRange(A1Range range, A1 destination) {
    final origin = A1.fromVector(range.from.column ?? 0, range.from.row ?? 0);

    // Move vector (dx,dy)
    final dx = destination.column - origin.column;
    final dy = destination.row - origin.row;
    final (columns, rows) =
        columnsAndRows(criteria: (a1) => range.contains(a1));

    // Depending on the vector of change, always start from where we
    // wont copy over.

    for (final column in dx.isNegative ? columns : columns.reversed) {
      for (final row in dy.isNegative ? rows : rows.reversed) {
        move(A1.fromVector(column, row), A1.fromVector(column + dx, row + dy));
      }
    }
  }

  void moveColumns(int from, int to, [int columns = 1]) {
    if (columns < 1) return;
    A1Range range = A1Range.fromPartials(
      A1Partial.fromVector(from, null),
      A1Partial.fromVector(from + columns - 1, null),
    );
    moveRange(range, A1.fromVector(to, 0));
  }

  void moveRows(int from, int to, [int rows = 1]) {
    if (rows < 1) return;
    A1Range range = A1Range.fromPartials(
      A1Partial.fromVector(null, from),
      A1Partial.fromVector(null, from + rows - 1),
    );
    moveRange(range, A1.fromVector(0, to));
  }

  void clearRange(A1Range range) {
    final (columns, rows) =
        columnsAndRows(criteria: (a1) => range.contains(a1));
    for (final column in columns) {
      for (final row in rows) {
        remove(A1.fromVector(column, row));
      }
    }
  }

  void clearColumns(int from, [int columns = 1]) => columns < 1
      ? null
      : clearRange(A1Range.fromPartials(
          A1Partial.fromVector(from, null),
          A1Partial.fromVector(from + columns - 1, null),
        ));

  void clearRows(int from, [int rows = 1]) => rows < 1
      ? null
      : clearRange(A1Range.fromPartials(
          A1Partial.fromVector(null, from),
          A1Partial.fromVector(null, from + rows - 1),
        ));

  void deleteColumns(int from, [int columns = 1]) {
    if (columns < 1) return;
    clearColumns(from, columns);
    final (colList, _) = columnsAndRows(criteria: (a1) => a1.column >= from);
    if (colList.isEmpty) return;
    moveColumns(from + columns, from, colList.last - from + 1);
  }

  void insertColumns(int from, [int columns = 1]) {
    final (colList, _) = columnsAndRows(criteria: (a1) => a1.column >= from);
    if (colList.isEmpty) return;
    moveColumns(from, from + columns, colList.last - from + 1);
  }

  void deleteRows(int from, [int rows = 1]) {
    if (rows < 1) return;
    clearRows(from, rows);

    final (_, rowList) = columnsAndRows(criteria: (a1) => a1.row >= from);
    if (rowList.isEmpty) return;
    moveRows(from + rows, from, rowList.last - from + 1);
  }

  void insertRows(int from, [int rows = 1]) {
    final (_, rowList) = columnsAndRows(criteria: (a1) => a1.row >= from);
    if (rowList.isEmpty) return;
    moveRows(from, from + rows, rowList.last - from + 1);
  }

  Cell? remove(A1 key, {bool markDeleted = false}) {
    // 1. remove references to and nofity (move only)
    if (markDeleted) {
      Set<A1>? references = _referencesToCell[key];
      if (references != null) {
        final refSetCopy = {...references};
        final refsDeleted = <A1>{};
        for (final reference in refSetCopy) {
          final cell = _cellMap[reference];
          if (cell != null && cell.content is ExpressionContent) {
            final formulaType = cell.formulaType;
            formulaType?.markDeletedCell(key);

            // If the reference is delete then remove, for some cases like sum
            // it will remain
            bool stillContainsRef = (formulaType?.hasReference(key)) ?? false;
            if (stillContainsRef == false) {
              _referencesToCell.removeReferenceToCell(key, reference);
              refsDeleted.add(reference);
            }
          }
        }
        _resultTypeCache.removeAll(refSetCopy);
        _notifyListeners(refsDeleted, CellChangeType.referenceDelete);
      }
    }

    if (_cellMap.containsKey(key)) {
      // 2. remove and notify references deleted
      _removeReferences(key);

      // 3. Remove Cell and notify
      final removedCell = _cellMap.remove(key);
      _resultTypeCache.removeAll({key});

      _notifyListeners({key}, CellChangeType.delete);
      return removedCell;
    }
    return null;
  }

  // References
  void _addReferences(A1 location, Cell cellContent) {
    if (cellContent.content is CellContent && cellContent.formulaType != null) {
      FormulaType formulaType = cellContent.formulaType!;
      final referenceSet = formulaType.references;
      for (A1 reference in referenceSet) {
        _referencesToCell.addReferenceToCell(reference, location);
      }
      if (referenceSet.isNotEmpty) {
        _notifyListeners(referenceSet, CellChangeType.referenceAdd);
      }
    }
  }

  void _removeReferences(A1 cell) {
    final cellContent = _cellMap[cell];
    if (cellContent != null &&
        cellContent.content is CellContent &&
        cellContent.formulaType != null) {
      final referenceSet = cellContent.formulaType!.references;
      for (final a1 in referenceSet) {
        _referencesToCell.removeReferenceToCell(a1, cell);
      }
      if (referenceSet.isNotEmpty) {
        _notifyListeners(referenceSet, CellChangeType.referenceDelete);
      }
    }
  }

  Set<A1>? referencesTo(A1 cell) => _referencesToCell[cell];

  @override
  String toString() {
    final (columns, rows) = columnsAndRows();
    StringBuffer buffer = StringBuffer();
    for (final (index, row) in rows.indexed) {
      if (index == 0) {
        buffer.write(''.padRight(4));
        for (final column in columns) {
          final letters = A1.fromVector(column, row).letters;
          final fx = '$letters fx';

          buffer.write(fx.padLeft(10).padRight(20));
          buffer.write(' | ');
          buffer.write(letters.padLeft(10).padRight(20));
          buffer.write(' | ');
        }
        buffer.write('\n');
        buffer.write(''.padRight(47 * columns.length + 1, '-'));
        buffer.write('\n');
      }
      buffer.write('${row + 1}'.padLeft(2).padRight(4));

      for (final column in columns) {
        final a1 = A1.fromVector(column, row);
        final cell = _cellMap[a1];
        buffer.write(cell?.contentString.padRight(20) ?? ''.padRight(20));
        buffer.write(' | ${cell?.formattedString(20) ?? "".padRight(20)} | ');
      }
      buffer.write('\n');
    }
    return buffer.toString();
  }

  String referencesToString() {
    final (columns, rows) = columnsAndRows(a1Iterable: _referencesToCell.keys);
    StringBuffer buffer = StringBuffer();
    for (final row in rows) {
      for (final column in columns) {
        final a1 = A1.fromVector(column, row);
        final cell = "$a1: ${_referencesToCell[a1] ?? ''}";
        buffer.write(cell.substring(0, min(cell.length, 20)).padRight(20));
      }
      buffer.write('\n');
    }
    return buffer.toString();
  }
}
