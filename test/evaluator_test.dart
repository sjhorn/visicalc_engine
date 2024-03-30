import 'package:test/test.dart';
import 'package:petitparser/petitparser.dart';
import 'package:a1/a1.dart';
import 'package:visicalc_engine/src/formula/types/count_function.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  final evaluator = Evaluator();

  (FormulaType formula, ResultType result) parseAndEval(
      Parser<FormulaType> parser, String expression) {
    Map<A1, FormulaType> variables = {
      'A1'.a1: NumType(12.12e12),
      'Z3'.a1: ReferenceType('A1'.a1),
      'C2'.a1: NumType(2),
      'DD3'.a1: ErrorType(),
    };
    FormulaType formula = parser.parse(expression).value;
    ResultType result = formula.eval(ResultCacheMap(variables));
    return (formula, result);
  }

  void expectEval(
    Parser<FormulaType> parser,
    String expression,
    TypeMatcher formulaType,
    TypeMatcher resultType,
    Object? expected,
  ) {
    var (formula, result) = parseAndEval(parser, expression);
    expect(formula, formulaType);
    expect(result, resultType);
    switch (result) {
      case NumberResult():
        expect(result.value, equals(expected));
      default:
    }
  }

  group('number', () {
    test('integer', () async {
      final p = evaluator.buildFrom(evaluator.number()).end();

      expectEval(p, '12', isA<NumType>(), isA<NumberResult>(), 12);
    });

    test('float', () async {
      final p = evaluator.buildFrom(evaluator.number()).end();

      expectEval(p, '12.12', isA<NumType>(), isA<NumberResult>(), 12.12);
    });

    test('bare decimal', () async {
      final p = evaluator.buildFrom(evaluator.decimal()).end();
      expectEval(p, '.12', isA<NumType>(), isA<NumberResult>(), 0.12);
    });

    test('exponent', () async {
      final p = evaluator.buildFrom(evaluator.number()).end();

      expectEval(p, '12e1', isA<NumType>(), isA<NumberResult>(), 12e1);
      expectEval(
          p, '12.234e-1', isA<NumType>(), isA<NumberResult>(), 12.234e-1);
    });
  });

  group('a1 notation', () {
    test('value reference', () async {
      final p = evaluator.buildFrom(evaluator.a1()).end();
      expectEval(p, 'A1', isA<ReferenceType>(), isA<NumberResult>(), 12.12e12);
    });
    test('cell reference', () async {
      final p = evaluator.buildFrom(evaluator.a1()).end();
      expectEval(p, 'Z3', isA<ReferenceType>(), isA<NumberResult>(), 12.12e12);
    });
  });

  group('prefixes', () {
    test('plus', () async {
      final p = evaluator.buildFrom(evaluator.prefixes()).end();
      expectEval(p, '+12', isA<PositiveOp>(), isA<NumberResult>(), 12);
      expectEval(p, '+12.12', isA<PositiveOp>(), isA<NumberResult>(), 12.12);
      expectEval(
          p, '+12.12e12', isA<PositiveOp>(), isA<NumberResult>(), 12.12e12);
      expectEval(
          p, '+12.12e-12', isA<PositiveOp>(), isA<NumberResult>(), 12.12e-12);
    });
    test('minus', () async {
      final p = evaluator.buildFrom(evaluator.prefixes()).end();
      expectEval(p, '-12', isA<NegativeOp>(), isA<NumberResult>(), -12);
      expectEval(p, '-12.12', isA<NegativeOp>(), isA<NumberResult>(), -12.12);
      expectEval(
          p, '-12.12e12', isA<NegativeOp>(), isA<NumberResult>(), -12.12e12);
      expectEval(
          p, '-12.12e-12', isA<NegativeOp>(), isA<NumberResult>(), -12.12e-12);
    });
  });

  group('right', () {
    test('power', () async {
      final p = evaluator.buildFrom(evaluator.right()).end();

      expectEval(p, '2^2', isA<BinaryNumOp>(), isA<NumberResult>(), 4);
      expectEval(p, '2^3^2', isA<BinaryNumOp>(), isA<NumberResult>(), 512);
      expectEval(p, '(2^3)^2', isA<BinaryNumOp>(), isA<NumberResult>(), 64);

      expectEval(p, '2^c2', isA<BinaryNumOp>(), isA<NumberResult>(), 4);
    });
  });
  group('left', () {
    test('additive', () async {
      final p = evaluator.buildFrom(evaluator.left()).end();
      expectEval(p, '12+12', isA<BinaryNumOp>(), isA<NumberResult>(), 24);
      expectEval(p, '12+12+12', isA<BinaryNumOp>(), isA<NumberResult>(), 36);
      expectEval(p, '12+12-12', isA<BinaryNumOp>(), isA<NumberResult>(), 12);
      expectEval(p, '12-12-12', isA<BinaryNumOp>(), isA<NumberResult>(), -12);
      expectEval(p, '12.12-12.12', isA<BinaryNumOp>(), isA<NumberResult>(), 0);
      expectEval(p, '12.12-12.12-12.12', isA<BinaryNumOp>(),
          isA<NumberResult>(), -12.12);
      expectEval(p, '12.12e12-12.12e12+12.12e12', isA<BinaryNumOp>(),
          isA<NumberResult>(), 12.12e12);
      expectEval(p, '+12.12-12.12', isA<BinaryNumOp>(), isA<NumberResult>(), 0);
      expectEval(
          p, '-12.12-12.12', isA<BinaryNumOp>(), isA<NumberResult>(), -24.24);
    });
    test('multiplicative', () async {
      final p = evaluator.buildFrom(evaluator.left()).end();
      expectEval(p, '12*12', isA<BinaryNumOp>(), isA<NumberResult>(), 144);
      expectEval(p, '12/12', isA<BinaryNumOp>(), isA<NumberResult>(), 1);
      expectEval(p, '12/c2', isA<BinaryNumOp>(), isA<NumberResult>(), 6);
      expectEval(p, '-12/12', isA<BinaryNumOp>(), isA<NumberResult>(), -1);
      expectEval(p, '-12*12/c2', isA<BinaryNumOp>(), isA<NumberResult>(), -72);
      expectEval(p, '1+2*3', isA<BinaryNumOp>(), isA<NumberResult>(), 7);
    });
  });

  group('wrappers', () {
    test('functions', () async {
      final p = evaluator.buildFrom(evaluator.left()).end();
      expectEval(p, '@count()', isA<CountFunction>(), isA<NumberResult>(), 0);
      expectEval(p, '@su(12)', isA<ErrorType>(), isA<ErrorResult>(), null);
      expectEval(p, '@sum(12)', isA<SumFunction>(), isA<NumberResult>(), 12);
      expectEval(p, '@sum(12+2)', isA<SumFunction>(), isA<NumberResult>(), 14);
      expectEval(
          p, '@sum(a1)', isA<SumFunction>(), isA<NumberResult>(), 12.12e12);
      expectEval(p, '@sum(a1...z3)', isA<SumFunction>(), isA<NumberResult>(),
          12.12e12 * 2 + 2);
      expectEval(p, '@sum(a1,c2,z3)', isA<SumFunction>(), isA<NumberResult>(),
          12.12e12 * 2 + 2);
      expectEval(p, '@sum(a1,c2)+@sum(a1...c2)', isA<BinaryNumOp>(),
          isA<NumberResult>(), (12.12e12 + 2) * 2);

      expectEval(p, '@sum(a1,c2)+@sum(a1...c2)', isA<BinaryNumOp>(),
          isA<NumberResult>(), (12.12e12 + 2) * 2);
      expectEval(p, '@sum(a1,c2)+@sum(a1,c2)', isA<BinaryNumOp>(),
          isA<NumberResult>(), (12.12e12 + 2) * 2);

      expect(
          p.parse('@sum(a1,c2)+@sum(a1..c2)'), isA<Failure>()); // missing dot
    });

    test('bare functions', () async {
      final p = evaluator.buildFrom(evaluator.bareFunction()).end();
      expectEval(p, '@pi', isA<PiType>(), isA<NumberResult>(), 3.1415926536);
    });

    test('brackets', () async {
      final p = evaluator.buildFrom(evaluator.brackets()).end();

      expectEval(p, '((1+2)*3)', isA<BracketsType>(), isA<NumberResult>(), 9);
      expectEval(p, '(1+2*3)', isA<BracketsType>(), isA<NumberResult>(), 7);
      expectEval(p, '(1+(2*3))', isA<BracketsType>(), isA<NumberResult>(), 7);
      expectEval(p, '(2^(3^2))', isA<BracketsType>(), isA<NumberResult>(), 512);
      expectEval(p, '(2^3^2)', isA<BracketsType>(), isA<NumberResult>(), 512);
      expectEval(p, '((2^3)^2)', isA<BracketsType>(), isA<NumberResult>(), 64);
    });
  });

  group('integrated', () {
    test('mix of tests', () async {
      final p = evaluator.build<FormulaType>();

      expectEval(p, '((1+2)*3)', isA<BracketsType>(), isA<NumberResult>(), 9);
      expectEval(p, '(1+2)*3', isA<BinaryNumOp>(), isA<NumberResult>(), 9);
      expectEval(p, '@sum(1+2)*3', isA<BinaryNumOp>(), isA<NumberResult>(), 9);
      expectEval(p, '@sum(1+2)*3', isA<BinaryNumOp>(), isA<NumberResult>(), 9);
      expectEval(p, '@sum(1+2)*@sum(a1...c2)', isA<BinaryNumOp>(),
          isA<NumberResult>(), 3 * (12.12e12 + 2));
    });

    test('error embedding', () async {
      final p = evaluator.build<FormulaType>();

      // Positive/NegativeOp
      expectEval(p, '+@dERROR', isA<PositiveOp>(), isA<ErrorResult>(), null);
      expectEval(p, '-DD3', isA<NegativeOp>(), isA<ErrorResult>(), null);

      // Sum
      expectEval(
          p, '@SUM(@Error)', isA<SumFunction>(), isA<ErrorResult>(), null);
      expectEval(p, '@SUM(DD3)', isA<SumFunction>(), isA<ErrorResult>(), null);
      expectEval(
          p, '@SUM(D1...DD3)', isA<SumFunction>(), isA<ErrorResult>(), null);
      expectEval(
          p, '@SUM(D1,DD3)', isA<SumFunction>(), isA<ErrorResult>(), null);

      // Lookup
      expectEval(p, '@LOOKUP(1,@Error)', isA<LookupFunction>(),
          isA<ErrorResult>(), null);
      expectEval(
          p, '@LOOKUP(1,DD3)', isA<LookupFunction>(), isA<ErrorResult>(), null);
      expectEval(p, '@LOOKUP(1,D1...DD3)', isA<LookupFunction>(),
          isA<ErrorResult>(), null);
      expectEval(p, '@LOOKUP(1,D1,DD3)', isA<LookupFunction>(),
          isA<ErrorResult>(), null);

      // Npv
      expectEval(
          p, '@NPV(1,@Error)', isA<NpvFunction>(), isA<ErrorResult>(), null);
      expectEval(p, '@NPV(0.5,A1...DD3)', isA<NpvFunction>(),
          isA<ErrorResult>(), null);
      expectEval(p, '@NPV(@Error,1,2,3)', isA<NpvFunction>(),
          isA<ErrorResult>(), null);
      expectEval(p, '@NPV(DD3,A1...A10)', isA<NpvFunction>(),
          isA<ErrorResult>(), null);

      // BinaryOP
      expectEval(p, '1+@ERROR', isA<BinaryNumOp>(), isA<ErrorResult>(), null);
      expectEval(p, '1+DD3', isA<BinaryNumOp>(), isA<ErrorResult>(), null);
      expectEval(p, '@LOOKUP(1-@ERROR)', isA<LookupFunction>(),
          isA<ErrorResult>(), null);
      expectEval(p, '@LOOKUP(@ERROR+1)', isA<LookupFunction>(),
          isA<ErrorResult>(), null);

      // Maths
      expectEval(
          p, '@TAN(@ERROR)', isA<MathsFunction>(), isA<ErrorResult>(), null);
      expectEval(
          p, '@COS(DD3)', isA<MathsFunction>(), isA<ErrorResult>(), null);

      // Min/Max
      expectEval(
          p, '@MIN(@ERROR,2,3)', isA<MinFunction>(), isA<ErrorResult>(), null);
      expectEval(
          p, '@MAX(1,2,DD3)', isA<MaxFunction>(), isA<ErrorResult>(), null);
    });
  });
}
