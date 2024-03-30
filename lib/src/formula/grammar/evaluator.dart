import 'dart:math';

import 'package:petitparser/petitparser.dart';
import '../types/brackets_type.dart';
import '../types/positive_op.dart';
import '../types/not_available_type.dart';
import '../types/error_type.dart';
import '../types/average_function.dart';

import '../types/binary_num_op.dart';
import '../types/count_function.dart';
import '../types/formula_type.dart';
import '../types/list_range_type.dart';
import '../types/list_type.dart';
import '../types/lookup_function.dart';
import '../types/maths_function.dart';
import '../types/max_function.dart';
import '../types/min_function.dart';
import '../types/negative_op.dart';
import '../types/npv_function.dart';
import '../types/num_type.dart';
import '../types/pi_type.dart';
import '../types/reference_type.dart';
import '../types/sum_function.dart';
import 'expression.dart';

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
  Parser<FormulaType> left() =>
      super.left().map((value) => value as FormulaType);

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
}
