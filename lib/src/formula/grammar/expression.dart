// Copyright (c) 2024, Scott Horn.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:petitparser/petitparser.dart';

/// This is the ViciCalc cell language expressed as a grammar
///
/// [Evaluator], [ValidateExpression], [FormatExpression], [FileFormat] all use
/// this as their based and layer in features
///
class Expression extends GrammarDefinition {
  @override
  Parser start() => ref0(labelOrExpression).end();

  // Either a label or epxression
  Parser labelOrExpression() => <Parser>[
        ref0(label),
        ref0(expressionWithList),
      ].toChoiceParser();

  // Starting with "charactor or A-Z we consider a label
  Parser label() => seq2(ref0(_labelChars), any().plus().flatten());
  Parser<String> _labelChars() => [char('"'), pattern('A-Z')].toChoiceParser();

  // either a list of expressions, or a single expression
  Parser expressionWithList() => <Parser>[
        ref0(list),
        ref0(expression),
      ].toChoiceParser();

  // expression [, expression]+
  Parser list() =>
      seq2(ref0(expression), seq2(char(','), ref0(expression)).plus());

  // expresssion starting with left associative eg. 1+2, 2-3, 1/2, 10*3
  Parser expression() => ref0(additive);
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

  // @func(expre)
  Parser function() => seq3(
        functionLeft(),
        ref0(expressionWithList).optional(),
        char(')').optional(),
      );

  // @func(
  Parser functionLeft() =>
      seq3(char('@'), word().plus(), char('(')).flatten('function expected');

  // @pi
  Parser bareFunction() =>
      seq2(char('@'), word().plus()).flatten('function expected');

  // (expression)
  Parser brackets() => seq3(char('('), ref0(expressionWithList), char(')'));

  // primitiave options range, a1, decimal or number
  Parser primitives() => <Parser>[
        ref0(range),
        ref0(a1),
        ref0(decimal),
        ref0(number),
      ].toChoiceParser();

  // ... or : eg. A1...B2, A2:A5
  Parser range() => seq3(ref0(a1), _rangeSeperator, ref0(a1));

  final Parser _rangeSeperator =
      [string('...'), char(':')].toChoiceParser().flatten();

  // A1 cell format
  Parser a1() =>
      seq2(letter().plus(), digit().plus()).flatten('a1 notation expected');

  // 123.123e12
  // .123.e-2
  Parser number() => (ref0(integerPart) &
          ref0(decimalPart).optional() &
          ref0(exponentialPart).optional())
      .flatten('number expected');

  // .123e123
  Parser decimal() => (ref0(decimalPart) & ref0(exponentialPart).optional())
      .flatten('decimal expected');

  // 123
  Parser integerPart() => digit().plus();

  // .1234
  Parser decimalPart() => (char('.') & digit().plus());

  // e-12
  Parser exponentialPart() =>
      (anyOf('eE') & anyOf('+-').optional() & digit().plus());
}
