import 'package:a1/a1.dart';
import 'package:test/test.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  final cache = ResultTypeCache({});
  test('reference type', () async {
    final ref = ReferenceType('A1'.a1);

    expect(ref.toString(), equals('ReferenceType{A1}'));
    expect(ref.eval(cache), isA<EmptyResult>());

    expect(ref.eval(cache, [ref]), isA<NotAvailableResult>());

    ref.markDeleted();
    expect(ref.eval(cache), isA<ErrorResult>());
    expect(ref.hashCode, equals('A1'.a1.hashCode));
  });

  test('positiveop type', () async {
    bool visited = false;
    final number = NumType(-1);
    final op = PositiveOp(number);
    expect(op.toString(), equals('PositiveOp(Value{-1})'));

    op.visit((it) => it == op ? visited = true : '');
    expect(visited, equals(true));
    expect(op, equals(number));
    expect(number, equals(op));
    expect(op, equals(op));
    expect(PositiveOp(number), equals(op));
  });
  test('negativeop type', () async {
    bool visited = false;
    final negop = NegativeOp(NumType(-1));

    expect(negop.toString(), equals('NegativeOp(Value{-1})'));
    expect(negop.hashCode, equals(NegativeOp(NumType(-1)).hashCode));

    negop.visit((it) => it == negop ? visited = true : '');
    expect(visited, equals(true));
  });

  test('pi type', () async {
    FormulaType? self;
    final pi = PiType();
    pi.visit((it) => self = it);
    expect(self, equals(pi));
  });

  test('num type', () async {
    FormulaType? self;
    final numType = NumType(2);
    numType.visit((instance) => self = instance);
    expect(numType.toString(), equals('Value{2}'));
    expect(self, equals(numType));
  });
  test('npvfunction type', () async {
    FormulaType? self;
    final npv = NpvFunction(null);
    npv.visit((instance) => self = instance);
    expect(npv.eval(cache), isA<ErrorResult>());
    expect(npv.asFormula, equals('@NPV(null)'));
    expect(self, equals(npv));
  });
  test('not available type', () async {
    FormulaType? self;
    final na = NotAvailableType();
    na.visit((instance) => self = instance);
    expect(na.eval(cache), isA<NotAvailableResult>());
    expect(na.asFormula, equals('@NA'));
    expect(self, equals(na));
  });

  test('min function type', () async {
    bool visited = false;
    final type = MinFunction(ListType([NumType(1), NumType(2)]));
    type.visit((instance) => instance == type ? visited = true : '');
    expect(type.eval(cache), isA<NumberResult>());
    expect(type.eval(cache), equals(NumberResult(1)));
    expect(type.asFormula, equals('@MIN(1,2)'));
    expect(visited, isTrue);

    expect(MinFunction(ListType([])).eval(cache), equals(NumberResult(0)));
  });
  test('max function type', () async {
    bool visited = false;
    final type = MaxFunction(ListType([NumType(1), NumType(2)]));
    type.visit((instance) => instance == type ? visited = true : '');
    expect(type.eval(cache), isA<NumberResult>());
    expect(type.eval(cache), equals(NumberResult(2)));
    expect(type.asFormula, equals('@MAX(1,2)'));
    expect(visited, isTrue);

    expect(MaxFunction(ListType([])).eval(cache), equals(NumberResult(0)));
  });
  test('maths function type', () async {
    final funcList =
        'abs,int,exp,sqrt,ln,log10,sin,asin,cos,acos,tan'.split(',');
    for (final name in funcList) {
      final type = MathsFunction('@$name(', NumType(1));
      bool visited = false;
      type.visit((instance) => instance == type ? visited = true : '');
      expect(type.eval(cache), isA<NumberResult>(), reason: name);
      expect(type.asFormula, equals('@${name.toUpperCase()}(1)'), reason: name);
      expect(visited, isTrue);
    }
    expect(
      MathsFunction('@invalid(', NumType(1)).eval(cache),
      isA<ErrorResult>(),
    );
  });
  test('lookup function type', () async {
    final cache2 = ResultTypeCache({
      'A1'.a1: NumType(1).cell,
      'A2'.a1: NumType(2).cell,
      'B1'.a1: NumType(1).cell,
      'B2'.a1: NumType(2).cell,
      'C1'.a1: NumType(1).cell,
      'C2'.a1: NumType(1).cell,
      'D1'.a1: NumType(3).cell,
      'D2'.a1: NumType(2).cell,
      'E1'.a1: ErrorType().cell,
      'E2'.a1: ErrorType().cell,
      'F1'.a1: NumType(3).cell,
      'F2'.a1: NumType(2).cell,
    });

    // Column Range
    final colRange = ListRangeType('A1'.a1, 'A2'.a1);
    bool visited = false;
    final type = LookupFunction(ListType([
      NumType(2),
      colRange,
    ]));
    type.visit((instance) => instance == type ? visited = true : '');
    expect(type.eval(cache2), isA<NumberResult>());
    expect(type.eval(cache2), equals(NumberResult(2)));
    expect(type.asFormula, equals('@LOOKUP(2,A1...A2)'));
    expect(visited, isTrue);

    expect(type.range, equals(colRange));
    expect(type.references, containsAll({'B1', 'B2'}.a1));

    // Row Range
    final rowRange = ListRangeType('C1'.a1, 'D1'.a1);
    visited = false;
    final type2 = LookupFunction(ListType([
      NumType(2),
      rowRange,
    ]));
    type2.visit((instance) => instance == type2 ? visited = true : '');
    expect(type2.eval(cache2), isA<NumberResult>());
    expect(type2.eval(cache2), equals(NumberResult(1)));
    expect(type2.asFormula, equals('@LOOKUP(2,C1...D1)'));
    expect(visited, isTrue);

    expect(type2.range, equals(rowRange));
    expect(type2.references, containsAll({'C2', 'D2'}.a1));

    // Error in range
    final type3 = LookupFunction(ListType([
      NumType(2),
      ListRangeType('E1'.a1, 'F1'.a1),
    ]));
    expect(type3.eval(cache2), isA<ErrorResult>());

    // First lookup is too high
    final type4 = LookupFunction(ListType([
      NumType(0),
      ListRangeType('A1'.a1, 'B1'.a1),
    ]));
    expect(type4.eval(cache2), equals(NumberResult(0)));

    // Range is not a lline
    final type5 = LookupFunction(ListType([
      NumType(0),
      ListRangeType('A1'.a1, 'C2'.a1),
    ]));
    expect(type5.references, equals(<A1>{}));
  });
  test('deleted lookupfunction', () async {
    // Deleted
    final type6 = LookupFunction(ListType([
      NumType(0),
      ListRangeType('A1'.a1, 'C2'.a1),
    ]));
    type6.markDeleted();
    expect(type6.eval(ResultTypeCache({})), isA<ErrorResult>());
  });

  test('list type', () async {
    bool visited = false;
    final type = ListType([NumType(1), NumType(2)]);
    type.visit((instance) => instance == type ? visited = true : '');
    expect(type.eval(cache), isA<ListResult>());
    expect(
      type.eval(cache),
      equals(ListResult([NumberResult(1), NumberResult(2)])),
    );
    expect(type.asFormula, equals('1,2'));
    expect(type.toString(), equals('ListType([Value{1}, Value{2}])'));
    expect(visited, isTrue);

    // Equality
    expect(type == ListType([NumType(1), NumType(2)]), isTrue);
    expect(type.hashCode, equals(ListType([NumType(1), NumType(2)]).hashCode));

    // from A1List
    expect(ListType.fromA1List(['A1'.a1, 'B2'.a1]), isA<ListType>());

    // circular check
    expect(type.eval(cache, [type]), isA<NotAvailableResult>());
  });

  test('list range type', () {
    bool visited = false;
    final type = ListRangeType('A1'.a1, 'B2'.a1);
    expect(type.toString(), equals('ListRangeType(A1...B2)'));
    type.visit((instance) => instance == type ? visited = true : '');
    expect(visited, isTrue);
  });

  test('error type', () {
    bool visited = false;
    final type = ErrorType();
    expect(type.asFormula, equals('@ERROR'));
    type.visit((instance) => instance == type ? visited = true : '');
    expect(visited, isTrue);
  });
  test('count function type', () {
    bool visited = false;
    final type = CountFunction(ListType([NumType(1), NumType(2)]));
    expect(type.asFormula, equals('@COUNT(1,2)'));
    expect(type.eval(cache), equals(NumberResult(2)));
    type.visit((instance) => instance == type ? visited = true : '');
    expect(visited, isTrue);
  });
  test('brackets type', () {
    bool visited = false;
    final type = BracketsType(NumType(1));
    expect(type.asFormula, equals('(1)'));
    expect(type.toString(), equals('BracketsType(Value{1})'));
    expect(type.eval(cache), equals(NumberResult(1)));
    type.visit((instance) => instance == type ? visited = true : '');
    expect(visited, isTrue);
  });
  test('BinaryNumOp type', () {
    bool visited = false;
    final type =
        BinaryNumOp('+', NumType(1), NumType(1), (left, right) => left + right);
    expect(type.asFormula, equals('1+1'));
    expect(type.toString(), equals('BinaryNumOp(+)'));
    expect(type.eval(cache), equals(NumberResult(2)));
    type.visit((instance) => instance == type ? visited = true : '');
    expect(visited, isTrue);

    final type2 = BinaryNumOp(
        '+', NumType(1), NotAvailableType(), (left, right) => left + right);
    expect(type2.eval(cache), equals(NumberResult(0)));
  });
  test('average function type', () {
    bool visited = false;
    final type =
        AverageFunction(ListType([NumType(1), NumType(2), NumType(3)]));
    expect(type.asFormula, equals('@AVERAGE(1,2,3)'));
    expect(type.eval(cache), equals(NumberResult(2)));
    type.visit((instance) => instance == type ? visited = true : '');
    expect(visited, isTrue);
  });
  test('label type', () {
    bool visited = false;
    final type = LabelType('hello');
    expect(type.asFormula, equals('"hello'));
    expect(type.eval(cache), equals(LabelResult('hello')));
    type.visit((instance) => instance == type ? visited = true : '');
    expect(visited, isTrue);
    expect(type.hashCode, equals(LabelType('hello').hashCode));
  });
}
