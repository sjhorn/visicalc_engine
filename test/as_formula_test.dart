import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  final evaluator = Evaluator();

  String parseAsFormula(String expression) {
    FormulaType formula = evaluator
        .buildFrom(evaluator.expressionWithList())
        .end()
        .parse(expression)
        .value;
    return formula.asFormula;
  }

  group('as formula', () {
    test('references', () async {
      expect(parseAsFormula('+A1+A2'), equals('+A1+A2'));
      expect(parseAsFormula('A1+A2'), equals('A1+A2'));
      expect(parseAsFormula('A1-A2'), equals('A1-A2'));
      expect(parseAsFormula('A1/20+C32'), equals('A1/20+C32'));
      expect(parseAsFormula('A1*B2+.23'), equals('A1*B2+0.23'));
    });
    test('functions', () async {
      expect(parseAsFormula('@sum(12)'), equals('@SUM(12)'));
      expect(parseAsFormula('@sum(12,13)'), equals('@SUM(12,13)'));
      expect(parseAsFormula('@sum(A1,13,Z3)'), equals('@SUM(A1,13,Z3)'));
      expect(parseAsFormula('@atan(12)'), equals('@ATAN(12)'));
      expect(parseAsFormula('@lookup(12,A1)'), equals('@LOOKUP(12,A1)'));
    });
    test('bare functions', () async {
      expect(parseAsFormula('@pi'), equals('@PI'));
      expect(parseAsFormula('@pi+1'), equals('@PI+1'));
      expect(parseAsFormula('@PI+A1'), equals('@PI+A1'));
    });
    test('range', () async {
      expect(parseAsFormula('a1...b2'), equals('A1...B2'));
      expect(parseAsFormula('@sum(a1...b2)'), equals('@SUM(A1...B2)'));
      expect(parseAsFormula('@atan(A2...B2)'), equals('@ATAN(A2...B2)'));
    });
    test('unary', () async {
      expect(parseAsFormula('-a1'), equals('-A1'));
      expect(parseAsFormula('-@sum(a1...b2)'), equals('-@SUM(A1...B2)'));
      expect(parseAsFormula('+@atan(A2...B2)'), equals('+@ATAN(A2...B2)'));
      expect(parseAsFormula('@atan(+A2...B2)'), equals('@ATAN(+A2...B2)'));
      expect(
          parseAsFormula('@atan(-A1,A2...B2)'), equals('@ATAN(-A1,A2...B2)'));
    });
    test('binary', () async {
      expect(parseAsFormula('a1*2'), equals('A1*2'));
      expect(parseAsFormula('a1*b2'), equals('A1*B2'));
      expect(parseAsFormula('a1/@PI'), equals('A1/@PI'));
      expect(
          parseAsFormula('@sum(a1...b2)+12/A4'), equals('@SUM(A1...B2)+12/A4'));
      expect(parseAsFormula('@atan(A2...B2)-@COS(A1)'),
          equals('@ATAN(A2...B2)-@COS(A1)'));
    });
    test('power', () async {
      expect(parseAsFormula('a1^b2'), equals('A1^B2'));
      expect(parseAsFormula('@sum(a1...b2)^4^4'), equals('@SUM(A1...B2)^4^4'));
      expect(parseAsFormula('2^@atan(A2...B2)'), equals('2^@ATAN(A2...B2)'));
    });
  });
}
