import 'package:test/test.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  test('result types', () async {
    expect(EmptyResult().toString(), equals(''));
    expect(ErrorResult().toString(), equals('ERROR'));
    expect(ListResult([ErrorResult(), ErrorResult()]).toString(),
        equals('List: (ERROR, ERROR)'));
    expect(NotAvailableResult('test').toString(), equals('NA - test'));
    expect(NotAvailableResult().toString(), equals('NA'));
  });

  test('number result type', () async {
    var result = NumberResult(12);
    expect(result.toString(), equals('12'));

    expect(result.compareTo('test'), equals(-1));
    expect(result.compareTo(NumberResult(13)), equals(-1));
    expect(result.compareTo(NumberResult(12)), equals(0));
    expect(result.compareTo(NumberResult(11)), equals(1));
    expect(result < NumberResult(11), isFalse);
    expect(result > NumberResult(11), isTrue);
    expect(result == NumberResult(12), isTrue);
    expect(result.hashCode, equals(NumberResult(12).hashCode));
  });

  test('number result type formatting', () async {
    expect(NumberResult(double.nan).toString(), equals('ERROR'));
    expect(NumberResult(double.infinity).toString(), equals('ERROR'));
    expect(NumberResult(double.negativeInfinity).toString(), equals('ERROR'));
    expect(NumberResult(0).toString(), equals('0'));
    expect(NumberResult(-0).toString(), equals('0'));
    expect(NumberResult(1.01234e-7).toString(), equals('1.01234e-7'));
    expect(NumberResult(1.01234e-5).toString(), equals('0.0000101234'));
    expect(NumberResult(1.01234e22).toString(), equals('1.01234e+22'));
    expect(NumberResult(123456789012e22).toString(), equals('1.23457e+33'));
    expect(NumberResult(123456789e22).toString(), equals('1.23457e+30'));
  });
  test('list result type', () async {
    expect(
      ListResult([NumberResult(1)]).hashCode,
      equals(ListResult([NumberResult(1)]).hashCode),
    );
  });
}
