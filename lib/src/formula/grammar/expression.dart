import 'package:petitparser/petitparser.dart';

class Expression extends GrammarDefinition {
  @override
  Parser start() => ref0(expressionWithList).end();

  Parser expressionWithList() => <Parser>[
        ref0(list),
        ref0(expression),
      ].toChoiceParser();

  Parser list() =>
      seq2(ref0(expression), seq2(char(','), ref0(expression)).plus());

  Parser expression() => <Parser>[
        ref0(left),
      ].toChoiceParser();

  // Left associative
  Parser left() => ref0(additive);
  Parser additive() => ref0(multiplicative).plusSeparated(anyOf('+-'));
  Parser multiplicative() => ref0(right).plusSeparated(anyOf('*/'));

  // Right associative
  Parser right() => ref0(power);
  Parser power() => ref0(prefixes).plusSeparated(anyOf('^'));

  // Prefix
  Parser prefixes() => seq2(anyOf('+-').optional(), ref0(wrappers));

  // Wrappers
  Parser wrappers() => [
        ref0(function),
        ref0(bareFunction),
        ref0(brackets),
        ref0(primitives),
      ].toChoiceParser();

  Parser function() => seq3(
        functionLeft(),
        ref0(expressionWithList).optional(),
        char(')').optional(),
      );
  Parser functionLeft() =>
      seq3(char('@'), word().plus(), char('(')).flatten('function expected');

  Parser bareFunction() =>
      seq2(char('@'), word().plus()).flatten('function expected');

  Parser brackets() => seq3(char('('), ref0(expressionWithList), char(')'));

  Parser primitives() => <Parser>[
        ref0(range),
        ref0(a1),
        ref0(decimal),
        ref0(number),
      ].toChoiceParser();

  // primitives
  Parser range() => seq3(ref0(a1), string('...'), ref0(a1));

  Parser a1() =>
      seq2(letter().plus(), digit().plus()).flatten('a1 notation expected');

  Parser number() => (ref0(integerPart) &
          ref0(decimalPart).optional() &
          ref0(exponentialPart).optional())
      .flatten('number expected');

  Parser decimal() => (ref0(decimalPart) & ref0(exponentialPart).optional())
      .flatten('decimal expected');

  Parser integerPart() => digit().plus();

  Parser decimalPart() => (char('.') & digit().plus());

  Parser exponentialPart() =>
      (anyOf('eE') & anyOf('+-').optional() & digit().plus());
}
