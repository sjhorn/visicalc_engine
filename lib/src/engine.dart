// Copyright (c) 2024, Scott Horn.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math';

import 'package:a1/a1.dart';
import 'package:petitparser/petitparser.dart';
import 'package:visicalc_engine/src/model/sheet.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

/// CellChangeCallback is a listener function
/// that receives a [Set] of [A1] that are affected
/// by changes in a sheet of type [CellChangeType]
typedef CellChangedCallback = void Function(
    Set<A1> a1Set, CellChangeType changeType);

class Engine extends Sheet {
  static final _formatExpression = FormatExpression().build();
  static final _fileFormat = FileFormat().build();
  static final _validator = ValidateExpression().build<A1Cursor>();
  final bool parseErrorThrows;
  final List<GlobalDirectiveContent> globalDirectives = [];

  /// Construct an empty Visicalc Engine
  ///
  /// parseErrorThrows - determins if
  Engine({this.parseErrorThrows = false});

  /// Constructing / parsing cells from a sheet of [Map] of [A1] keys and
  /// [String] values.
  ///
  /// The string of each cell supports the same formatting used in a .vc file
  ///
  /// parseErrorThrows [bool] determines if the engine will throw a
  /// [FormatException] if any cells in the sheet [Map] cannot be parsed
  ///
  /// Example:
  /// ```dart
  ///  final sheet = {
  ///    'A1'.a1: '/FR-12.2',
  ///    'A2'.a1: '(a5+45)',
  ///    'A3'.a1: '/F*13',
  ///    'A4'.a1: '+A2+A5-A6',
  ///    'A5'.a1: '-A3/2+2',
  ///    'A6'.a1: '/F\$.23*2',
  ///    'B1'.a1: 'A1+A3*3',
  ///    'B2'.a1: '(A1+A3)*3',
  ///    'B3'.a1: '12.23e-12',
  ///    'B4'.a1: '.23e12',
  ///    'B5'.a1: '/FRb4',
  ///    'B6'.a1: 'b2',
  ///    'B7'.a1: '@sum(a1...b6)',
  ///    'D13'.a1: 'b2',
  ///  };
  ///  final engine = Engine.fromMap(sheet, parseErrorThrows: true);
  ///  print(engine);
  ///  ```
  factory Engine.fromMap(Map<A1, String> map, {bool parseErrorThrows = false}) {
    final engine = Engine(parseErrorThrows: parseErrorThrows);
    for (final MapEntry(:key, :value) in map.entries) {
      final cell = engine._parse(value);
      engine.setCell(key, cell);
      engine.addReferences(key, cell);
    }
    return engine;
  }

  /// Create the engine/spreadsheet from file contents
  ///
  /// 'parseErrorThrows' is a boolean parameter that will cause parsing
  /// to throw a [FormatException] if there is an error parsing the file
  ///
  /// Example:
  /// ```dart
  /// final fileContents = File.readTextSync();
  /// final engine = Engine.fromFileContents(fileContents);
  /// ```
  factory Engine.fromFileContents(String fileContents,
      {bool parseErrorThrows = false}) {
    const lineSeparator = '\r\n';
    final engine = Engine();
    for (final line in fileContents.split(lineSeparator)) {
      if (line.isNotEmpty && line.codeUnits.first == 0) break;
      final result = _fileFormat.parse(line);
      if (result is! Success) {
        if (parseErrorThrows) {
          throw FormatException('Error parsing [$line]] - ${result.message}');
        } else {
          continue;
        }
      }

      switch (result.value) {
        case MapEntry<A1, Cell>(:var key, :var value):
          value.resultTypeCacheFunc = () => engine.resultTypeCache;
          engine.setCell(key, value);
        case GlobalDirectiveContent():
          engine.globalDirectives.add(result.value);
      }
    }
    return engine;
  }

  /// Save the engine/sheet contents to the .vc file format
  /// as a string
  String toFileContents() {
    const lineSeparator = '\r\n';

    final stringBuffer = StringBuffer();
    final keyList = keys.toList()..sort((a, b) => a.compareTo(b));
    for (final a1 in keyList.reversed) {
      final cell = getCell(a1)!;
      switch (cell.content) {
        case RepeatingContent(:var pattern):
          stringBuffer.write('>$a1:/-$pattern$lineSeparator');
        case ExpressionContent(:var formulaType):
          stringBuffer.write(
              '>$a1:${cell.format.fileFormat}${formulaType.asFormula}$lineSeparator');
      }
    }
    // stringBuffer.write('/W1$lineSeparator/GOC$lineSeparator/GRA$lineSeparator'
    //     '/GC10$lineSeparator/X>A1:>C14:$lineSeparator');
    stringBuffer.write(List.filled(104, String.fromCharCode(0)).join(''));
    return stringBuffer.toString();
  }

  /// validateExpression aims to validate a text expression
  ///
  /// Returns a record:
  /// [String] of validated text
  /// [int] Position of the start of an A1 or the end of string
  /// [bool] on whether the cursor is inside a function
  ///
  static (String, int, bool) validateExpression(String text) {
    final result = _validator.parse(text);
    String newString = text;
    int insertPosition = 0;
    bool inFunction = false;
    if (result is Failure) {
      newString = text.substring(0, max(0, result.position));
      insertPosition = result.position;
      inFunction = false;
    } else {
      inFunction = result.value.inFunction;
      A1Cursor cursor = result.value;
      int length = text.length;
      if (cursor.kind == A1CursorKind.offset) {
        insertPosition = length - cursor.offset!;
      } else {
        insertPosition = length;
      }
    }
    return (newString, insertPosition, inFunction);
  }

  Cell _parse(String cell) {
    final ast = _formatExpression.parse(cell);
    if (ast is Success) {
      final cell = ast.value as Cell;
      cell.resultTypeCacheFunc = () => resultTypeCache;
      return cell;
    } else {
      if (parseErrorThrows) {
        throw FormatException('Error parsing [$cell]] - ${ast.message}');
      }
      return Cell(
        content: ExpressionContent(ErrorType(ast.message)),
        resultTypeCacheFunc: () => resultTypeCache,
      );
    }
  }

  /// To access the cells in the engine, this exposes a map like interfaces
  /// the keys of an [A1] key for each cell. The result returned is a [Cell]
  /// that includes the [CellContent] as well as [CellFormat]
  ///
  /// Example:
  /// ```dart
  /// final cell = engine['a1'.a1]; // returns a Cell
  /// ```
  Cell? operator [](A1 a1) {
    if (containsCellKey(a1)) {
      return getCell(a1);
    }
    return null;
  }

  /// To set cells in the engine, a map like setting method using the [A1] key
  /// to set the cell. The contents for the cell are parsed from the supplied
  /// cell [String?]. A cell can also be deleted by setting it to null. Better
  /// methods for deleting are [remove] and [clear]
  ///
  /// Examples:
  /// ```dart
  /// engine['a1'.a1] = '/FR"a cool label right aligned'; // right aligned label
  /// engine['a2'.a1] = '1+4'; // 5
  /// ```
  ///
  void operator []=(A1 key, String? contents) {
    if (containsCellKey(key)) {
      resultTypeCache.removeAll({key});
      removeReferences(key);
      notifyListeners({key}, CellChangeType.delete);
    }

    if (contents != null && contents.isNotEmpty) {
      setCell(key, _parse(contents));
    } else {
      remove(key);
    }
  }

  /// This function clears all the cells in the engine
  ///
  /// Example:
  /// ```dart
  /// engine.clear(); // clear all cells in the engines sheet
  /// ```
  void clear() {
    final a1set = keys.toSet();
    final a1Deps = keys.fold(<A1>{},
        (set, a1) => set..addAll(this[a1]?.formulaType?.references ?? {}));
    clearCells();
    resultTypeCache.clear();
    referencesToCell.clear();

    notifyListeners(a1set, CellChangeType.delete);
    notifyListeners(a1Deps, CellChangeType.referenceDelete);
  }

  /// move allows a cell based on [A1] origin to move to a [A1] destiation.
  /// The move will overwrite the destination with the origin cell contents
  ///
  /// If the origin or destination have references to other cells, these
  /// will be re-written
  ///
  /// Example:
  /// ```dart
  /// engine.move('A1'.a1, 'B1'.a1); // move the cell from A1 to B1
  /// ```
  void move(A1 origin, A1 destination) {
    // Remove destination and mark deleted cells and notify
    remove(destination, markDeleted: true);

    // Rewrite cells references origin to destination
    // and refresh _references/cache
    final cell = getCell(origin);
    final originFormula =
        cell?.content is ExpressionContent ? cell?.formulaType : null;
    final references = referencesToCell[origin] ?? {};

    for (final reference in {...references}) {
      rewriteAndRefreshReference(reference, origin, destination);
    }

    // Remove the origin and notify
    Cell? originCell = remove(origin);

    // Add the destination and notify
    if (originFormula != null) {
      this[destination] = originFormula.asFormula; // let the map notify
    } else if (originCell != null) {
      setCell(destination, originCell);
      notifyListeners({destination}, CellChangeType.add);
    }
  }

  /// moveRange allows a cell based on [A1Range] range to move to a [A1] destiation.
  /// The move will overwrite the destination with the origin cell contents
  ///
  /// If the origin or destination have references to other cells, these
  /// will be re-written
  ///
  /// Example:
  /// ```dart
  /// engine.moveRange('A1:A2'.a1, 'B1'.a1); // move cells from A1,A2 to B1,B2
  /// ```
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

  /// moveColumns allows a column to be moved from origin column to the
  /// destination column. The numbers of columns default to 1, but can be
  /// specified as the third parameter.
  /// The move will overwrite the destination with the origin cell contents
  ///
  /// If the origin or destination have references to other cells, these
  /// will be re-written
  ///
  /// Example:
  /// ```dart
  /// engine.moveColumns('A1'.col, 'B1'.col); // move col A over the top of B
  /// ```
  void moveColumns(int originColumn, int destinationColumn, [int columns = 1]) {
    if (columns < 1) return;
    A1Range range = A1Range.fromPartials(
      A1Partial.fromVector(originColumn, null),
      A1Partial.fromVector(originColumn + columns - 1, null),
    );
    moveRange(range, A1.fromVector(destinationColumn, 0));
  }

  /// moveRows allows a row to be moved from origin row to the
  /// destination row. The numbers of rows default to 1, but can be
  /// specified as the third parameter.
  /// The move will overwrite the destination with the origin cell contents
  ///
  /// If the origin or destination have references to other cells, these
  /// will be re-written
  ///
  /// Example:
  /// ```dart
  /// engine.moveRows('A1'.row, 'C2'.row, 2); // move row 1,2 over row 3,4
  /// ```
  void moveRows(int originRow, int destiniationRow, [int rows = 1]) {
    if (rows < 1) return;
    A1Range range = A1Range.fromPartials(
      A1Partial.fromVector(null, originRow),
      A1Partial.fromVector(null, originRow + rows - 1),
    );
    moveRange(range, A1.fromVector(0, destiniationRow));
  }

  /// clearRange allows a whole [A1Range] like A1:B5 to be cleared
  ///
  /// Example:
  /// ```dart
  /// engine.clearRange('A1...B5'.a1Range); // clears cells in A1:B5 ranges
  /// ```
  void clearRange(A1Range range) {
    final (columns, rows) =
        columnsAndRows(criteria: (a1) => range.contains(a1));
    for (final column in columns) {
      for (final row in rows) {
        remove(A1.fromVector(column, row));
      }
    }
  }

  /// clearColumns will clear the contents of 'columns' count of columns
  /// starting at the column [int] index specificed in 'from'.
  ///
  /// Example:
  /// ```dart
  /// engine.clearColuns('C1'.a1, 3); // clears columsn C,D,E
  /// ```
  void clearColumns(int from, [int columns = 1]) => columns < 1
      ? null
      : clearRange(A1Range.fromPartials(
          A1Partial.fromVector(from, null),
          A1Partial.fromVector(from + columns - 1, null),
        ));

  /// clearRows will clear the contents of 'rows' count of rows starting
  /// at the row [int] index specificed in 'from'.
  ///
  /// Example:
  /// ```dart
  /// engine.clearRows('C3'.a1, 3); // clears columns 3,4,5
  /// ```
  void clearRows(int from, [int rows = 1]) => rows < 1
      ? null
      : clearRange(A1Range.fromPartials(
          A1Partial.fromVector(null, from),
          A1Partial.fromVector(null, from + rows - 1),
        ));

  /// deleteColumns will delete the contents of 'columns' count of columns
  /// starting at the column [int] index specificed in 'from' and collapse
  /// columns into their space.
  ///
  /// Example:
  /// ```dart
  /// engine.deleteColumns('C1'.a1, 3); // deletes columns C,D,E
  /// ```
  void deleteColumns(int from, [int columns = 1]) {
    if (columns < 1) return;
    clearColumns(from, columns);
    final (colList, _) = columnsAndRows(criteria: (a1) => a1.column >= from);
    if (colList.isEmpty) return;
    moveColumns(from + columns, from, colList.last - from + 1);
  }

  /// insertColumns will add an empty 'columns' count of columns
  /// starting at the column [int] index specificed in 'from' and move
  /// columns to the right.
  ///
  /// Example:
  /// ```dart
  /// engine.insertColumns('C1'.a1, 3); // inserts columns C,D,E
  /// ```
  void insertColumns(int from, [int columns = 1]) {
    final (colList, _) = columnsAndRows(criteria: (a1) => a1.column >= from);
    if (colList.isEmpty) return;
    moveColumns(from, from + columns, colList.last - from + 1);
  }

  /// deleteRows will delete the contents of 'rows' count of rows
  /// starting at the row [int] index specificed in 'from' and collapse
  /// rows into their space.
  ///
  /// Example:
  /// ```dart
  /// engine.deleteRows('A1'.a1, 3); // deletes rows 1,2,3
  /// ```
  void deleteRows(int from, [int rows = 1]) {
    if (rows < 1) return;
    clearRows(from, rows);

    final (_, rowList) = columnsAndRows(criteria: (a1) => a1.row >= from);
    if (rowList.isEmpty) return;
    moveRows(from + rows, from, rowList.last - from + 1);
  }

  /// insertRows will add an empty 'rows' count of rows
  /// starting at the row [int] index specificed in 'from' and move
  /// rows down.
  ///
  /// Example:
  /// ```dart
  /// engine.insertRows('C1'.a1, 3); // inserts rows 1,2,3
  /// ```
  void insertRows(int from, [int rows = 1]) {
    final (_, rowList) = columnsAndRows(criteria: (a1) => a1.row >= from);
    if (rowList.isEmpty) return;
    moveRows(from, from + rows, rowList.last - from + 1);
  }

  /// remove clears a cell from engine/sheet and if requested with the
  /// 'markDeleted' field, will mark references as deleted.
  /// If the sheet had an existing [Cell] this will be returned others null.
  ///
  /// Example:
  /// ```dart
  /// engine.remove('A1'.a1, markDeleted: true); // simulate cutting A1
  /// ```
  Cell? remove(A1 key, {bool markDeleted = false}) {
    // 1. remove references to and nofity (move only)
    if (markDeleted) {
      Set<A1>? references = referencesToCell[key];
      if (references != null) {
        final refSetCopy = {...references};
        final refsDeleted = <A1>{};
        for (final reference in refSetCopy) {
          final cell = getCell(reference);
          if (cell != null && cell.content is ExpressionContent) {
            final formulaType = cell.formulaType;
            formulaType?.markDeletedCell(key);

            // If the reference is delete then remove, for some cases like sum
            // it will remain
            bool stillContainsRef = (formulaType?.hasReference(key)) ?? false;
            if (stillContainsRef == false) {
              referencesToCell.removeReferenceToCell(key, reference);
              refsDeleted.add(reference);
            }
          }
        }
        resultTypeCache.removeAll(refSetCopy);
        notifyListeners(refsDeleted, CellChangeType.referenceDelete);
      }
    }

    if (containsCellKey(key)) {
      // 2. remove and notify references deleted
      removeReferences(key);

      // 3. Remove Cell and notify
      final removedCell = removeCell(key);
      resultTypeCache.removeAll({key});

      notifyListeners({key}, CellChangeType.delete);
      return removedCell;
    }
    return null;
  }

  /// This is a utility function that returns a [Set] of [A1] the are
  /// all the other cells that references the specific cell
  ///
  /// Example:
  /// ```dart
  /// final engine = Engine({'A2'.a1: '+A1'});
  /// print(engine.referencesTo('A1'.a1)); // A2,
  /// ```
  Set<A1>? referencesTo(A1 cell) => referencesToCell[cell];

  /// To allow nice printing of the engine/sheet, the toString method
  /// provides a simple table view of the cell formulas and values
  /// with a width of 20 characters. The example in [example/example.dart]
  /// also demonstrates this in action.
  ///
  /// Example:
  /// ```dart
  /// final sheet = {
  ///   'A1'.a1: '/FR-12.2',
  ///   'A2'.a1: '(a5+45)',
  ///   'A3'.a1: '/F*13',
  ///   'A4'.a1: '+A2+A5-A6',
  ///   'A5'.a1: '-A3/2+2',
  ///   'A6'.a1: '/F\$.23*2',
  ///   'B1'.a1: 'A1+A3*3',
  ///   'B2'.a1: '(A1+A3)*3',
  ///   'B3'.a1: '12.23e-12',
  ///   'B4'.a1: '.23e12',
  ///   'B5'.a1: '/FRb4',
  ///   'B6'.a1: 'b2',
  /// };
  /// final worksheet = Engine(sheet, parseErrorThrows: true);
  /// print(worksheet);
  /// ```
  /// The result looks a bit like the following:
  ///
  /// ```
  ///           A fx           |          A           |       B fx           |          B           |
  /// -----------------------------------------------------------------------------------------------
  ///  1  -12.2                |                -12.2 | A1+A3*3              | 26.8                 |
  ///  2  (A5+45)              | 40.5                 | (A1+A3)*3            | 2.4                  |
  ///  3  13                   | ********             | 1.223e-11            | 1.223e-11            |
  ///  4  +A2+A5-A6            | 35.54                | 230000000000         | 230000000000         |
  ///  5  -A3/2+2              | -4.5                 | B4                   |         230000000000 |
  ///  6  0.23*2               | 0.46                 | B2                   | 2.4                  |
  /// ```
  ///
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
        final cell = getCell(a1);
        buffer.write(cell?.contentString.padRight(20) ?? ''.padRight(20));
        buffer.write(' | ${cell?.formattedString(20) ?? "".padRight(20)} | ');
      }
      buffer.write('\n');
    }
    return buffer.toString();
  }
}
