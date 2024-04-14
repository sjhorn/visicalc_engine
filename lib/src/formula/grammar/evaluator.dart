// Copyright (c) 2024, Scott Horn.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'package:petitparser/petitparser.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

class Evaluator extends Expression {
  @override
  Parser<FormulaType> start() => super.start().map((value) => value);

  @override
  Parser<FormulaType> expressionWithList() =>
      super.expressionWithList().map((value) => value);

  @override
  Parser<FormulaType> list() => super.list().map((value) {
        final (first, List list) = value;
        List<FormulaType> listItems = [
          first,
          ...list.map(
            (e) => e.$2,
          )
        ];
        return ListType(listItems);
      });

  @override
  Parser<FormulaType> range() => super.range().map((value) {
        var (ReferenceType from, _, ReferenceType to) = value;
        return ListRangeType.fromRefTypes(from, to);
      });

  @override
  Parser<FormulaType> right() => super.right().map((value) {
        SeparatedList list = value;
        return list.foldRight((left, seperator, right) => BinaryNumOp(
            seperator, left, right, (left, right) => pow(left, right)));
      });

  @override
  Parser<FormulaType> prefixes() => super.prefixes().map((value) {
        return switch (value.$1) {
          '-' => NegativeOp(value.$2),
          '+' => PositiveOp(value.$2),
          _ => value.$2,
        };
      });

  @override
  Parser<FormulaType> function() => super.function().map((value) {
        var (String name, FormulaType? params, String? _) = value;
        params ??= NumType(0);
        return switch (name.toLowerCase()) {
          '@sum(' => SumFunction(params),
          '@min(' => MinFunction(params),
          '@max(' => MaxFunction(params),
          '@count(' => CountFunction(params),
          '@average(' => AverageFunction(params),
          '@npv(' => NpvFunction(params),
          '@lookup(' => LookupFunction(params),
          '@abs(' ||
          '@int(' ||
          '@exp(' ||
          '@sqrt(' ||
          '@ln(' ||
          '@log10(' ||
          '@sin(' ||
          '@asin(' ||
          '@cos(' ||
          '@acos(' ||
          '@tan(' ||
          '@atan(' =>
            MathsFunction(name.toLowerCase(), params),
          _ => ErrorType(),
        };
      });

  @override
  Parser<FormulaType> bareFunction() => super.bareFunction().map((value) {
        var (String name) = value;
        return switch (name.toLowerCase()) {
          '@na' => NotAvailableType(),
          '@error' => ErrorType(),
          '@pi' => PiType(),
          _ => ErrorType(),
        };
      });

  @override
  Parser<FormulaType> brackets() =>
      super.brackets().map((value) => BracketsType(value.$2));

  @override
  Parser<FormulaType> expression() =>
      super.expression().map((value) => value as FormulaType);

  @override
  Parser<FormulaType> additive() => super.additive().map((value) {
        SeparatedList list = value;
        return list.foldLeft(
          (left, seperator, right) => BinaryNumOp(
            seperator,
            left,
            right,
            (left, right) => switch (seperator) {
              '-' => left - right,
              _ => left + right,
            },
          ),
        );
      });

  @override
  Parser<FormulaType> multiplicative() => super.multiplicative().map((value) {
        SeparatedList list = value;

        return list.foldLeft(
          (left, seperator, right) => BinaryNumOp(
            seperator,
            left,
            right,
            (left, right) => switch (seperator) {
              '/' => left / right,
              _ => left * right,
            },
          ),
        );
      });

  @override
  Parser<FormulaType> a1() =>
      super.a1().map((value) => ReferenceType.fromA1String(value));

  @override
  Parser<FormulaType> number() =>
      super.number().map((value) => NumType(num.parse(value)));

  @override
  Parser<FormulaType> decimal() =>
      super.decimal().map((value) => NumType(num.parse(value)));

  @override
  Parser<FormulaType> label() => super.label().map((value) => value.$1 == '"'
      ? LabelType(value.$2)
      : LabelType('${value.$1}${value.$2}'));
}
