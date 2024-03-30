import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  final noCursor = A1Cursor.none();
  final endCursor = A1Cursor.end();

  group('complete expressions', () {
    final validation = ValidateExpression();

    test('decimal', () async {
      final parser = validation.buildFrom(validation.decimal()).end();

      expect(parser.parse('.42').value, noCursor);
      expect(parser.parse('.42e1').value, noCursor);
      expect(parser.parse('.42e+2').value, noCursor);
      expect(parser.parse('.42e-4').value, noCursor);
      expect(parser.parse('.42e-23').value, noCursor);

      expect(parser.parse('0.42e-23'), isA<Failure>());
      expect(parser.parse('e-23'), isA<Failure>());
      expect(parser.parse('-23'), isA<Failure>());
      expect(parser.parse('a.23'), isA<Failure>());
    });

    test('number', () async {
      final parser = validation.buildFrom(validation.number()).end();

      expect(parser.parse('0.42').value, noCursor);
      expect(parser.parse('12.42e1').value, noCursor);
      expect(parser.parse('1231.42e+2').value, noCursor);
      expect(parser.parse('1.42e-4').value, noCursor);
      expect(parser.parse('0.42e-23').value, noCursor);

      expect(parser.parse('.42e-23'), isA<Failure>());
      expect(parser.parse('e-23'), isA<Failure>());
      expect(parser.parse('-.23'), isA<Failure>());
      expect(parser.parse('a.23'), isA<Failure>());
    });

    test('a1', () async {
      final parser = validation.buildFrom(validation.a1()).end();

      expect(parser.parse('a1').value, A1Cursor.offset(2));
      expect(parser.parse('b32').value, A1Cursor.offset(3));
      expect(parser.parse('b32').value, A1Cursor.offset(3));
      expect(parser.parse('cc12').value, A1Cursor.offset(4));
      expect(parser.parse('abcdefg123').value, A1Cursor.offset(10));

      expect(parser.parse('12a'), isA<Failure>());
      expect(parser.parse('--a3'), isA<Failure>());
      expect(parser.parse('a++'), isA<Failure>());
      expect(parser.parse('a.23'), isA<Failure>());
    });

    test('brackets', () async {
      final parser = validation.buildFrom(validation.brackets()).end();

      expect(parser.parse('(a1)').value, noCursor);
      expect(parser.parse('(12)').value, noCursor);
      expect(parser.parse('(a1...c2)').value, noCursor);
      expect(parser.parse('(a1,c2,d3)').value, noCursor);
      expect(parser.parse('(1+2)').value, noCursor);
      expect(parser.parse('(1+2/3)').value, noCursor);
      expect(parser.parse('(1+(2+3))').value, noCursor);
      expect(parser.parse('((3+1)+2)').value, noCursor);
      expect(parser.parse('(a1+(1+c2))').value, noCursor);
    });

    test('prefix', () async {
      final parser = validation.buildFrom(validation.prefixes()).end();

      expect(parser.parse('+a1').value, A1Cursor.offset(2));
      expect(parser.parse('+12').value, noCursor);
      expect(parser.parse('+12.12').value, noCursor);
      expect(parser.parse('-12.12e12').value, noCursor);
      expect(parser.parse('+12.12e-12').value, noCursor);
      expect(parser.parse('-12.12e+12').value, noCursor);
    });

    test('range', () async {
      final parser = validation.buildFrom(validation.range()).end();

      expect(parser.parse('A1...B2').value, A1Cursor.offset(2));
      expect(parser.parse('ABCDED123...C2').value, A1Cursor.offset(2));
      expect(parser.parse('C2...B200').value, A1Cursor.offset(4));
      expect(parser.parse('Z1...ZZZZ1000').value, A1Cursor.offset(8));
      expect(parser.parse('q4...q4').value, A1Cursor.offset(2));

      expect(parser.parse('a1..b2'), isA<Failure>());
      expect(parser.parse('a1....+c2'), isA<Failure>());
      expect(parser.parse('...c2'), isA<Failure>());
      expect(parser.parse('a1...c2...'), isA<Failure>());
    });

    test('left', () async {
      final parser = validation.buildFrom(validation.left()).end();

      expect(parser.parse('1+2').value, noCursor);
      expect(parser.parse('+1+2').value, noCursor);
      expect(parser.parse('123-23').value, noCursor);
      expect(parser.parse('+200/40').value, noCursor);
      expect(parser.parse('+A1*A2').value, A1Cursor.offset(2));
      expect(parser.parse('A1+A2/12').value, noCursor);
      expect(parser.parse('q4*q4').value, A1Cursor.offset(2));
      expect(parser.parse('+@sum()*q4').value, A1Cursor.offset(2));
      expect(parser.parse('-@Sum(q4)+45+23').value, noCursor);
      expect(parser.parse('@Sum(q4+2)+45+23').value, noCursor);

      expect(parser.parse('1+/2'), isA<Failure>());
      expect(parser.parse('1~2'), isA<Failure>());
      expect(parser.parse('+a1+*c2'), isA<Failure>());
      expect(parser.parse('/c2'), isA<Failure>());
    });

    test('list', () async {
      final parser = validation.buildFrom(validation.list()).end();

      expect(parser.parse('1,2').value, noCursor);
      expect(parser.parse('1,2,3').value, noCursor);
      expect(parser.parse('A1,2,A123').value, A1Cursor.offset(4));
      expect(parser.parse('A1*A2,B2').value, A1Cursor.offset(2));
      expect(parser.parse('10^23^12,23').value, noCursor);
      expect(parser.parse('A1+A2/12,-1').value, noCursor);
      expect(parser.parse('q4*q4,x3').value, A1Cursor.offset(2));
      expect(parser.parse('12,@sum()*q4').value, A1Cursor.offset(2));
      expect(parser.parse('@Sum(q4),@avg(a1)+45+23').value, noCursor);
      expect(parser.parse('12,3+@Sum(q4+2)+45+23').value, noCursor);

      expect(parser.parse(','), isA<Failure>());
      expect(parser.parse('1,,'), isA<Failure>());
      expect(parser.parse('+,12'), isA<Failure>());
      expect(parser.parse('0.,23'), isA<Failure>());
    });
    test('bare function', () async {
      final parser = validation.buildFrom(validation.bareFunction()).end();

      expect(parser.parse('@pi').value, noCursor);
    });

    test('function', () async {
      final parser = validation.buildFrom(validation.function()).end();

      expect(parser.parse('@func(1,2)').value, noCursor);
      expect(parser.parse('@func(+1,2,3)').value, noCursor);
      expect(parser.parse('@func(-A1)').value, noCursor);
      expect(parser.parse('@func(-10^23^@func(12),23)').value, noCursor);
      expect(parser.parse('@func(a10...a2)').value, noCursor);
      expect(parser.parse('@func(a1...v4,1+2,t1...t3)').value, noCursor);

      expect(parser.parse('@s)'), isA<Failure>());
      expect(parser.parse('s()'), isA<Failure>());
      expect(parser.parse('.()'), isA<Failure>());
      expect(parser.parse('().)'), isA<Failure>());
    });

    test('expression', () async {
      final parser = validation.buildFrom(validation.expression()).end();

      expect(parser.parse('+(a1+b2)/c2').value, A1Cursor.offset(2));
      expect(parser.parse('+a1/b2/c2').value, A1Cursor.offset(2));
      expect(parser.parse('+A1+@SUM(A1').value, A1Cursor.offset(2));
      expect(parser.parse('+A1+@SUM(A1)').value, noCursor);
      expect(parser.parse('@SUM(A1)/A1*@AVG(ZZZ1)').value, noCursor);
      expect(parser.parse('@SUM(A1,B2)/A1*@AVG(ZZZ1...D3)').value, noCursor);
      expect(parser.parse('@SUM(A1,B2)/A1*@AVG(ZZZ1...D323423').value,
          A1Cursor.offset(7));

      expect(parser.parse('@s+.+a)'), isA<Failure>());
      expect(parser.parse('@s!.~a)'), isA<Failure>());
      expect(parser.parse('./@s)'), isA<Failure>());
    });

    test('expression with list', () async {
      final parser =
          validation.buildFrom(validation.expressionWithList()).end();

      expect(parser.parse('A1+@SUM(B2,A33)').value, noCursor);
      expect(parser.parse('-A1+@SUM(B2,A33').value, A1Cursor.offset(3));
      expect(parser.parse('ZV4,C3,A1...B2').value, A1Cursor.offset(2));
      expect(parser.parse('+A1...B2,C3').value, A1Cursor.offset(2));
      expect(
          parser.parse('A1+@SUM(B2,A33)+@AVG(V4,@SUM(123))').value, noCursor);
      expect(parser.parse('-A1+@SUM(B2,A33)+@AVG(V4,@SUM(123))+A1').value,
          A1Cursor.offset(2));
    });
  });

  group('partial expressions', () {
    final validation = ValidateExpression();

    test('decimal', () async {
      final parser = validation.buildFrom(validation.decimal()).end();

      expect(parser.parse('.').value, noCursor);
      expect(parser.parse('.42e').value, noCursor);
      expect(parser.parse('.42e+').value, noCursor);
      expect(parser.parse('.42e-').value, noCursor);

      expect(parser.parse('0.'), isA<Failure>());
      expect(parser.parse('0.42e'), isA<Failure>());
      expect(parser.parse('a.23'), isA<Failure>());
    });

    test('number', () async {
      final parser = validation.buildFrom(validation.number()).end();

      expect(parser.parse('0.').value, noCursor);
      expect(parser.parse('12.42e').value, noCursor);
      expect(parser.parse('1231.42e+').value, noCursor);
      expect(parser.parse('1.42e-').value, noCursor);
      expect(parser.parse('0.42e-').value, noCursor);

      expect(parser.parse('.42e'), isA<Failure>());
      expect(parser.parse('e-23'), isA<Failure>());
      expect(parser.parse('-.23'), isA<Failure>());
    });

    test('a1', () async {
      final parser = validation.buildFrom(validation.a1()).end();

      expect(parser.parse('a').value, A1Cursor.offset(1));
      expect(parser.parse('bbbbb').value, A1Cursor.offset(5));
      expect(parser.parse('b').value, A1Cursor.offset(1));
      expect(parser.parse('cc').value, A1Cursor.offset(2));
      expect(parser.parse('abcdefg').value, A1Cursor.offset(7));
      expect(parser.parse('a12aaa'), isA<Failure>());
      expect(parser.parse('--a'), isA<Failure>());
      expect(parser.parse('a++'), isA<Failure>());
      expect(parser.parse('a.23'), isA<Failure>());
    });

    test('prefix', () async {
      final parser = validation.buildFrom(validation.prefixes()).end();

      expect(parser.parse('+a').value, A1Cursor.offset(1));
      expect(parser.parse('+').value, endCursor);
      expect(parser.parse('-12.12e1').value, noCursor);
      expect(parser.parse('+12.12e-').value, noCursor);
      expect(parser.parse('-12.12e+').value, noCursor);
    });

    test('range', () async {
      final parser = validation.buildFrom(validation.range()).end();

      expect(parser.parse('A1...').value, endCursor);
      expect(parser.parse('A1...B').value, A1Cursor.offset(1));
      expect(parser.parse('ABCDED123...').value, endCursor);
      expect(parser.parse('C2...BBBBB').value, A1Cursor.offset(5));
      expect(parser.parse('Z1...ZZZZ').value, A1Cursor.offset(4));
      expect(parser.parse('q4...q').value, A1Cursor.offset(1));

      expect(parser.parse('a1...+'), isA<Failure>());
      expect(parser.parse('+a1....++'), isA<Failure>());
      expect(parser.parse('...c2'), isA<Failure>());
      expect(parser.parse('a1...c2...'), isA<Failure>());
    });

    test('left', () async {
      final parser = validation.buildFrom(validation.left()).end();

      expect(parser.parse('1+').value, endCursor);
      expect(parser.parse('123-').value, endCursor);
      expect(parser.parse('+200/').value, endCursor);
      expect(parser.parse('-A1*').value, endCursor);
      expect(parser.parse('-10^23^').value, endCursor);
      expect(parser.parse('-A1+A2/').value, endCursor);
      expect(parser.parse('q4*').value, endCursor);
      expect(parser.parse('+@sum()*q').value, A1Cursor.offset(1));
      expect(parser.parse('@Sum(q4)+45+').value, endCursor);
      expect(parser.parse('@Sum(q4+2)+').value, endCursor);
    });

    test('list', () async {
      final parser = validation.buildFrom(validation.list()).end();

      expect(parser.parse('1,').value, endCursor);
      expect(parser.parse('+1,2,').value, endCursor);
      expect(parser.parse('+A1,2,').value, endCursor);
      expect(parser.parse('-A1*A2,').value, endCursor);
      expect(parser.parse('-10^23^12,').value, endCursor);
      expect(parser.parse('-A1+A2/12,').value, endCursor);
      expect(parser.parse('q4*q4,').value, endCursor);
      expect(parser.parse('@Sum(q4),').value, endCursor);
      expect(parser.parse('q4,1').value, noCursor);
    });

    test('bare function', () async {
      final parser = validation.buildFrom(validation.bareFunction()).end();

      expect(parser.parse('@').value, noCursor);
      expect(parser.parse('@p').value, noCursor);
    });
    test('function', () async {
      final parser = validation.buildFrom(validation.function()).end();

      expect(parser.parse('@func(').value, endCursor);
      expect(parser.parse('@func(1').value, noCursor);
      expect(parser.parse('@func(1,2').value, noCursor);
      expect(parser.parse('@func(').value, endCursor);
      expect(parser.parse('@func(-10^23^@func(1)').value, noCursor);
      expect(parser.parse('@func(a10...').value, endCursor);
      expect(
          parser.parse('@func(a1...v4,1+2,t1...t3').value, A1Cursor.offset(2));
    });

    test('expression', () async {
      final parser = validation.buildFrom(validation.expression()).end();

      expect(parser.parse('+(a1/b2)/c').value, A1Cursor.offset(1));

      expect(parser.parse('+A1+@SUM(').value, endCursor);
      expect(parser.parse('@SUM(A1)/A1*@AVG(ZZZ').value, A1Cursor.offset(3));
      expect(parser.parse('@SUM(A1,B2)/').value, endCursor);
      expect(parser.parse('@SUM(A1,B2)/A1*@AVG(ZZZ1...').value, endCursor);
      expect(parser.parse('1+1').value, noCursor);
      expect(parser.parse('1+').value, endCursor);
      expect(parser.parse('1+a1').value, A1Cursor.offset(2));
    });

    test('expression with list', () async {
      final parser =
          validation.buildFrom(validation.expressionWithList()).end();

      expect(parser.parse('@pi+1').value, noCursor);
      expect(parser.parse('A1+@SUM(A').value, A1Cursor.offset(1));
      expect(parser.parse('+A1+@SUM(B2,A33').value, A1Cursor.offset(3));
      expect(parser.parse('A1+@SUM(B2,').value, endCursor);
      expect(parser.parse('-ZV4,C3,A1...B').value, A1Cursor.offset(1));
      expect(parser.parse('A1...B2,C').value, A1Cursor.offset(1));
      expect(parser.parse('A1+@SUM(B2,A33)+@AVG(V4,@SUM(123)').value, noCursor);
      expect(parser.parse('A1+@SUM(B2,A33)+@AVG(V4,@SUM(123))+A').value,
          A1Cursor.offset(1));
    });
  });

  group('full expression', () {
    final parser = ValidateExpression().build();
    test(' methods', () {
      expect(parser.parse('A1+@SUM(B2,A33)+@AVG(V4,@SUM(123)').value, noCursor);
    });
  });

  group('A1Cursor', () {
    test(' methods', () {
      final a1c = A1Cursor.offset(0, true);
      expect(a1c.toString(), equals('end'));
      expect(A1Cursor.offset(1).toString(), equals('offset(offset: 1)'));

      expect(a1c.hashCode, equals(A1Cursor.end(true).hashCode));

      expect(a1c.copyWith(kind: A1CursorKind.end), equals(a1c));
    });
  });
}
