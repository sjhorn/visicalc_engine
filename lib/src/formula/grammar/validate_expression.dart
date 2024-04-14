// Copyright (c) 2024, Scott Horn.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:petitparser/petitparser.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

/// A1CursorKind determines if we end in an [A1Partial] then
/// where does it start in the string.
///
/// none - end is not an A1Partial
/// end - the end is the starting position for an A1Partial
/// offset - the A1Partial begins at offset in the string
enum A1CursorKind { none, end, offset }

/// A1Cursor is a utility for helping stor information about the
/// current VisiCalc [Expression]
class A1Cursor {
  /// [A1CursorKind] either none, offset or end
  final A1CursorKind kind;

  /// If [A1CursorKind] is offset this is the offset, otherwise null
  final int? offset;

  /// A bool to indicate if we are current inside a function
  final bool inFunction;

  // Private Constructor
  A1Cursor._(this.kind, [this.offset, this.inFunction = false]);

  /// An A1Cursor that is not in an A1Partial
  factory A1Cursor.none() => A1Cursor._(A1CursorKind.none);

  /// An A1Cursor which has the A1Partial beginngin at the end
  factory A1Cursor.end([bool inFunction = false]) =>
      A1Cursor._(A1CursorKind.end, null, inFunction);

  /// An A1Cursor then begisn at offset
  factory A1Cursor.offset(int offset, [bool inFunction = false]) => offset == 0
      ? A1Cursor.end(inFunction)
      : A1Cursor._(A1CursorKind.offset, offset, inFunction);

  /// Help debugging this A1Cursor
  @override
  String toString() => switch (kind) {
        A1CursorKind.offset => '${kind.name}(offset: $offset)',
        _ => kind.name,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is A1Cursor && other.kind == kind && other.offset == offset;
  }

  @override
  int get hashCode => kind.hashCode ^ offset.hashCode ^ inFunction.hashCode;

  /// Utility for copying some of the features to a new A1Cursor
  A1Cursor copyWith({
    A1CursorKind? kind,
    int? offset,
    bool? inFunction,
  }) {
    return A1Cursor._(
      kind ?? this.kind,
      offset ?? this.offset,
      inFunction ?? this.inFunction,
    );
  }
}

/// This Grammar helps validate partial VisiCalc [Expression] to assist
/// an input UI in validation and position the cursor if moving around
/// in a spreadsheet and need to swap the [A1] value
class ValidateExpression extends Expression {
  @override
  Parser<A1Cursor> start() => super.start().map((value) => value);

  @override
  Parser<A1Cursor> expressionWithList() =>
      super.expressionWithList().map((value) => value);

  @override
  Parser<A1Cursor> expression() {
    return super.expression().map((value) => value);
  }

  @override
  Parser<A1Cursor> function() => super.function().map((value) {
        var (A1Cursor functionLeft, A1Cursor? params, String? endBracket) =
            value;
        if (endBracket != null) {
          return A1Cursor.none();
        } else if (params is A1Cursor) {
          return params.copyWith(inFunction: true);
        } else {
          return functionLeft.copyWith(inFunction: true);
        }
      });

  @override
  Parser<A1Cursor> functionLeft() =>
      super.functionLeft().map((value) => A1Cursor.end());

  @override
  Parser<A1Cursor> bareFunction() => [
        char('@').end().map((value) => A1Cursor.none()),
        super.bareFunction().map((value) => A1Cursor.none()),
      ].toChoiceParser();

  @override
  Parser<A1Cursor> list() => <Parser<A1Cursor>>[
        (ref0(expression) & (char(',') & ref0(expression)).star() & char(','))
            .end()
            .map((value) => A1Cursor.end()),
        super.list().map((value) => (value.$2 as Iterable).flattened.last.$2),
      ].toChoiceParser();

  @override
  Parser<A1Cursor> additive() => seq2(
        super
            .additive()
            .map((value) => (value.elements as Iterable).flattened.last),
        anyOf('+-').end().optional(),
      ).map2((value, String? op) => op == null ? value : A1Cursor.end());

  @override
  Parser<A1Cursor> multiplicative() => seq2(
        super
            .multiplicative()
            .map((value) => (value.elements as Iterable).flattened.last),
        anyOf('*/').end().optional(),
      ).map2((value, String? op) => op == null ? value : A1Cursor.end());

  @override
  Parser<A1Cursor> power() => seq2(
        super
            .power()
            .map((value) => (value.elements as Iterable).flattened.last),
        anyOf('^').end().optional(),
      ).map2((value, String? op) => op == null ? value : A1Cursor.end());

  @override
  Parser<A1Cursor> prefixes() => [
        seq2(anyOf('+-'), ref0(wrappers).optional())
            .end()
            .map((value) => (value.$1, value.$2 ?? A1Cursor.end())),
        super.prefixes(),
      ].toChoiceParser().map((value) => value.$2);

  @override
  Parser<A1Cursor> brackets() => [
        char('(').end().map((value) => A1Cursor.end()),
        seq2(char('('), ref0(expressionWithList))
            .end()
            .map((value) => A1Cursor.none()),
        super.brackets().map((value) => A1Cursor.none()),
      ].toChoiceParser();

  @override
  Parser<A1Cursor> range() => <Parser<A1Cursor>>[
        (ref0(a1) & string('...')).end().map((value) => A1Cursor.end()),
        super.range().map((value) => value.$3 as A1Cursor),
      ].toChoiceParser();

  @override
  Parser<A1Cursor> a1() => [
        (letter().plus() & digit().star())
            .end()
            .flatten('a1 notation expected'),
        super.a1(),
      ].toChoiceParser().map((value) => A1Cursor.offset(value.length));

  @override
  Parser<A1Cursor> number() => super.number().map((value) => A1Cursor.none());

  @override
  Parser<A1Cursor> decimal() => super.decimal().map((value) => A1Cursor.none());

  @override
  Parser decimalPart() => [
        (char('.') & digit().star()).end(),
        super.decimalPart(),
      ].toChoiceParser();

  @override
  Parser exponentialPart() => [
        (anyOf('eE') & anyOf('+-').optional() & digit().star()).end(),
        super.exponentialPart(),
      ].toChoiceParser();
}

extension on Iterable {
  Iterable get flattened => _flatten(this);

  Iterable _flatten(Iterable iterable) =>
      iterable.expand((e) => e is List ? _flatten(e) : [e]);
}
