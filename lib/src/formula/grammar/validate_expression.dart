import 'package:petitparser/petitparser.dart';

import 'expression.dart';

enum A1CursorKind { none, end, offset }

class A1Cursor {
  final A1CursorKind kind;
  final int? offset;
  final bool inFunction;

  A1Cursor._(this.kind, [this.offset, this.inFunction = false]);

  factory A1Cursor.none() => A1Cursor._(A1CursorKind.none);
  factory A1Cursor.end([bool inFunction = false]) =>
      A1Cursor._(A1CursorKind.end, null, inFunction);
  factory A1Cursor.offset(int offset, [bool inFunction = false]) => offset == 0
      ? A1Cursor.end(inFunction)
      : A1Cursor._(A1CursorKind.offset, offset, inFunction);

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

class ValidateExpression extends Expression {
  @override
  Parser<A1Cursor> start() => super.start().map((value) => value);

  @override
  Parser<A1Cursor> expressionWithList() =>
      super.expressionWithList().map((value) => value);

  @override
  Parser<A1Cursor> expression() {
    return super.expression().map((value) {
      //print('Expression -> $value');
      return value;
    });
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
        super.list().map((value) {
          final (_, rest) = value;
          final last = (rest as Iterable).flattened.last.$2;

          return switch (last) {
            A1Cursor() => last,
            null => A1Cursor.none(),
            _ => A1Cursor.end(),
          };
        }),
      ].toChoiceParser();

  @override
  Parser<A1Cursor> additive() => seq2(
        super.additive().map((value) {
          final last = (value.elements as Iterable).flattened.last;
          return last ?? A1Cursor.none();
        }),
        anyOf('+-').end().optional(),
      ).map2((value, String? op) => op == null ? value : A1Cursor.end());

  @override
  Parser<A1Cursor> multiplicative() => seq2(
        super.multiplicative().map((value) {
          final last = (value.elements as Iterable).flattened.last;
          return last ?? A1Cursor.none();
        }),
        anyOf('*/').end().optional(),
      ).map2((value, String? op) => op == null ? value : A1Cursor.end());

  @override
  Parser<A1Cursor> power() => seq2(
        super.power().map((value) {
          final last = (value.elements as Iterable).flattened.last;
          return last ?? A1Cursor.none();
        }),
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
