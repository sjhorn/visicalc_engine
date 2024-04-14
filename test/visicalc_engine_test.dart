import 'package:a1/a1.dart';
import 'package:test/test.dart';
import 'package:visicalc_engine/src/model/cell_change_type.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  group('parsing a worksheet with ', () {
    final sheet = {
      'A1'.a1: '-12.2',
      'A2'.a1: '(a5+45)',
      'A3'.a1: '13',
      'A4'.a1: '+A2+A5-A6',
      'A5'.a1: '-A3/2+2',
      'A6'.a1: '.23*2',
      'B1'.a1: '+A1+A3*3',
      'B2'.a1: '(A1+A3)*3',
      'B3'.a1: '12.23e-12',
      'B4'.a1: '.23e12',
      'B5'.a1: '+b4',
      'B6'.a1: '+b2',
      'B7'.a1: '@sum(a1...b6)',
      'B8'.a1: '"This is a label',
    };
    Engine engine = Engine(sheet);
    setUp(() {
      engine = Engine(sheet);
    });

    test(' - errors', () async {
      final engine = Engine({'A1'.a1: '@'});
      expect(engine['a1'.a1]?.formulaType, isA<ErrorType>());
      expect(engine['a1'.a1]?.resultType, isA<ErrorResult>());

      expect(() => Engine({'A1'.a1: '@'}, parseErrorThrows: true),
          throwsA(isA<FormatException>()));
    });
    test(' - a negative number', () async {
      expect(engine['A1'.a1]!.formulaType, equals(NegativeOp(NumType(12.2))));
      expect(engine['A1'.a1]!.resultType, equals(NumberResult(-12.2)));
    });
    test(' - brackets and addition number', () async {
      expect(engine['A2'.a1]!.formulaType, isA<BracketsType>());
      expect(engine['A2'.a1]!.resultType, equals(NumberResult(40.5)));
    });
    test(' - a positive number', () async {
      expect(engine['A3'.a1]!.formulaType, equals(NumType(13)));
      expect(engine['A3'.a1]!.resultType, equals(NumberResult(13)));
    });
    test(' - three number sum', () async {
      expect(engine['A4'.a1]!.formulaType, isA<BinaryNumOp>());
      expect(engine['A4'.a1]!.resultType, equals(NumberResult(35.54)));
    });
    test(' - division', () async {
      expect(engine['A5'.a1]!.formulaType, isA<BinaryNumOp>());
      expect(engine['A5'.a1]!.resultType, equals(NumberResult(-4.5)));
    });
    test(' - decimal multiplication', () async {
      expect(engine['A6'.a1]!.formulaType, isA<BinaryNumOp>());
      expect(engine['A6'.a1]!.resultType, equals(NumberResult(0.46)));
    });
    test(' - mixed arithmatic', () async {
      expect(engine['B1'.a1]!.formulaType, isA<BinaryNumOp>());
      expect(engine['B1'.a1]!.resultType, equals(NumberResult(26.8)));
    });
    test(' - reference', () async {
      expect(engine['B5'.a1]!.formulaType, isA<PositiveOp>());
      expect(engine['B5'.a1]!.resultType, equals(NumberResult(.23e12)));
    });
    test(' - function', () async {
      expect(engine['B7'.a1]!.formulaType, isA<SumFunction>());
      expect(engine['B7'.a1]!.resultType,
          equals(NumberResult(460000000104.400024414063)));
    });
    test(' - label', () async {
      expect(engine['B8'.a1]!.formulaType, isA<LabelType>());
      expect(engine['B8'.a1]!.resultType, isA<LabelResult>());
    });
  });
  group('tracking references ', () {
    final sheet = {
      'A1'.a1: '-12.2',
      'A2'.a1: '(a5+45)',
      'A3'.a1: '13',
      'A4'.a1: '+A2+A5-A6',
      'A5'.a1: '-A3/2+2',
      'A6'.a1: '.23*2',
      'B1'.a1: '+A1+A3*3',
      'B2'.a1: '(A1+A3)*3',
      'B3'.a1: '12.23e-12',
      'B4'.a1: '.23e12',
      'B5'.a1: '+b4',
      'B6'.a1: '+b2',
      'B7'.a1: '@sum(a1...b6)',
    };
    Engine engine = Engine({});
    setUp(() {
      engine = Engine(sheet);
    });
    test(' - add dependancies', () async {
      expect(engine.referencesTo('A1'.a1), containsAll({'B1', 'B2', 'B7'}.a1));
      expect(engine.referencesTo('A2'.a1), containsAll({'A4', 'B7'}.a1));
      expect(engine.referencesTo('A3'.a1), containsAll({'A5', 'B2', 'B7'}.a1));
      expect(engine.referencesTo('A4'.a1), containsAll({'B7'}.a1));
      expect(engine.referencesTo('A5'.a1), containsAll({'A4', 'B7'}.a1));
      expect(engine.referencesTo('B1'.a1), containsAll({'B7'}.a1));
      expect(engine.referencesTo('B2'.a1), containsAll({'B6', 'B7'}.a1));
      expect(engine.referencesTo('B3'.a1), containsAll({'B7'}.a1));
      expect(engine.referencesTo('B4'.a1), containsAll({'B5', 'B7'}.a1));
      expect(engine.referencesTo('B5'.a1), containsAll({'B7'}.a1));
      expect(engine.referencesTo('B6'.a1), containsAll({'B7'}.a1));
      expect(engine.referencesTo('B7'.a1), isNull);
    });
    test(' - change dependancies', () async {
      expect(engine.referencesTo('A2'.a1), containsAll({'A4', 'B7'}.a1));
      engine['A4'.a1] = '1';
      expect(engine.referencesTo('A2'.a1), containsAll({'B7'}.a1));
      engine['B7'.a1] = '1';
      expect(engine.referencesTo('A2'.a1), isNull);
      engine['A3'.a1] = '+A2/2';
      expect(engine.referencesTo('A2'.a1), containsAll({'A3'}.a1));
    });
    test(' - clear cell and dependancies', () async {
      engine.clear();
      expect(engine.keys.length, isZero);
      expect(engine.referencesTo('A2'.a1), isNull);
    });
    test(' - remove cell and dependancies + marking deleted', () async {
      engine.remove('A3'.a1, markDeleted: true);
      expect(engine['A2'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['A4'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['A5'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['B1'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['B2'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['B2'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['B6'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['B7'.a1]?.resultType, isA<ErrorResult>());
      expect(engine.referencesTo('A3'.a1), containsAll({'B7'}.a1));
    });
    test(' - remove cell and dependancies sum range', () async {
      engine.remove('B7'.a1);

      expect(engine.referencesTo('A3'.a1), containsAll({'A5', 'B2'}.a1));
      expect(engine.referencesTo('B3'.a1), isNull);
      expect(engine.referencesTo('B5'.a1), isNull);
      expect(engine.referencesTo('B6'.a1), isNull);
    });
  });

  group('moving cells ', () {
    final sheet = {
      'A1'.a1: '-12.2',
      'A2'.a1: '(a5+45)',
      'A3'.a1: '13',
      'A4'.a1: '+A2+A5-A6',
      'A5'.a1: '-A3/2+2',
      'A6'.a1: '.23*2',
      'B1'.a1: '+A1+A3*3',
      'B2'.a1: '(A1+A3)*3',
      'B3'.a1: '12.23e-12',
      'B4'.a1: '.23e12',
      'B5'.a1: '+b4',
      'B6'.a1: '+b2',
      'B7'.a1: '@sum(b1...b6)',
      'B8'.a1: '/-=',
    };
    Engine engine = Engine({});
    setUp(() {
      engine = Engine(sheet);
    });
    test(' - moving a repeating cell to empty cell', () async {
      final origin = 'b8'.a1;
      final destination = 'c1'.a1;

      expect(engine[origin]?.formulaType?.asFormula, isNull);
      expect(engine[origin]?.resultType, isNull);
      expect(engine.referencesTo(origin), isNull);

      expect(engine[destination]?.formulaType, isNull);
      expect(engine[destination]?.resultType, isNull);
      expect(engine.referencesTo(destination), isNull);

      engine.move(origin, destination);

      expect(engine[origin]?.formulaType, isNull);
      expect(engine[origin]?.resultType, isNull);
      expect(engine.referencesTo(origin), isNull);

      expect(engine[destination]?.formulaType, isNull);
      expect(engine[destination]?.resultType, isNull);
      expect(engine.referencesTo(destination), isNull);
      expect(engine[destination], isA<Cell>());
      expect(engine[destination]?.content, isA<RepeatingContent>());
      expect((engine[destination]?.content as RepeatingContent).pattern,
          equals('='));
    });
    test(' - moving an expression cell to empty cell', () async {
      final origin = 'a2'.a1;
      final destination = 'c1'.a1;

      expect(engine[origin]?.formulaType?.asFormula, equals('(A5+45)'));
      expect(engine[origin]?.resultType, equals(NumberResult(40.5)));
      expect(engine.referencesTo(origin), containsAll({'a4'}.a1));

      expect(engine[destination]?.formulaType, isNull);
      expect(engine[destination]?.resultType, isNull);
      expect(engine.referencesTo(destination), isNull);

      expect(engine.referencesTo('a5'.a1), contains(origin));

      engine.move(origin, destination);

      expect(engine[origin]?.formulaType, isNull);
      expect(engine[origin]?.resultType, isNull);
      expect(engine.referencesTo(origin), isNull);

      expect(engine[destination]?.formulaType?.asFormula, equals('(A5+45)'));
      expect(engine[destination]?.resultType, equals(NumberResult(40.5)));
      expect(engine.referencesTo(destination), containsAll({'a4'}.a1));

      expect(engine.referencesTo('a5'.a1), contains(destination));
    });

    test(' - moving a cell with a sum range to empty cell', () async {
      final origin = 'b5'.a1;
      final destination = 'c1'.a1;

      expect(engine[origin]?.formulaType, equals(ReferenceType('b4'.a1)));
      expect(engine[origin]?.resultType, equals(NumberResult(.23e12)));
      expect(engine.referencesTo(origin), containsAll({'b7'}.a1));

      expect(engine[destination]?.formulaType, isNull);
      expect(engine[destination]?.resultType, isNull);
      expect(engine.referencesTo(destination), isNull);

      expect(engine.referencesTo('b4'.a1), containsAll({'b5', 'b7'}.a1));

      engine.move(origin, destination);

      expect(engine[origin]?.formulaType, isNull);
      expect(engine[origin]?.resultType, isNull);
      expect(engine.referencesTo(origin), containsAll({'b7'}.a1));

      expect(engine[destination]?.formulaType, equals(ReferenceType('b4'.a1)));
      expect(engine[destination]?.resultType, equals(NumberResult(.23e12)));
      expect(engine.referencesTo(destination), isNull);

      expect(engine.referencesTo('b4'.a1), containsAll({'c1', 'b7'}.a1));
    });

    test(' - moving a cell to occupied cell', () async {
      final origin = 'a2'.a1;
      final destination = 'a6'.a1;

      expect(engine[origin]?.formulaType?.asFormula, equals('(A5+45)'));
      expect(engine[origin]?.resultType, equals(NumberResult(40.5)));
      expect(engine.referencesTo(origin), containsAll({'a4'}.a1));

      expect(engine[destination]?.formulaType, isA<BinaryNumOp>());
      expect(engine[destination]?.resultType, equals(NumberResult(.46)));
      expect(engine.referencesTo(destination), containsAll({'a4'}.a1));

      expect(engine.referencesTo('a5'.a1), contains(origin));

      engine.move(origin, destination);

      expect(engine[origin]?.formulaType, isNull);
      expect(engine[origin]?.resultType, isNull);
      expect(engine.referencesTo(origin), isNull);

      expect(engine[destination]?.formulaType?.asFormula, equals('(A5+45)'));
      expect(engine[destination]?.resultType, equals(NumberResult(40.5)));
      expect(engine.referencesTo(destination), containsAll({'a4'}.a1));

      expect(engine.referencesTo('a5'.a1), contains(destination));
    });
  });
  group('listening to sheet changes ', () {
    final sheet = {
      'A1'.a1: '-12.2',
      'A2'.a1: '(a5+45)',
      'A3'.a1: '13',
      'A4'.a1: '+A2+A5-A6',
      'A5'.a1: '-A3/2+2',
      'A6'.a1: '.23*2',
      'B1'.a1: 'A1+A3*3',
      'B2'.a1: '(A1+A3)*3',
      'B3'.a1: '12.23e-12',
      'B4'.a1: '.23e12',
      'B5'.a1: '+b4',
      'B6'.a1: '+b2',
      'B7'.a1: '@sum(b1...b6)',
    };
    Engine engine = Engine({});

    List<(CellChangeType, Set<A1>)> changes = [];
    void listener(a1Set, changeType) {
      changes.add((changeType, a1Set));
    }

    setUp(() {
      changes.clear();
      engine = Engine(sheet);
      engine.addListener(listener);
    });
    test(' - remove listener', () async {
      engine.removeListener(listener);
      engine['b6'.a1] = '-12.2';
      expect(changes.isEmpty, isTrue);
    });
    test(' - add single cell without references triggers listeners', () async {
      engine['b6'.a1] = '-12.2';

      expect(changes[0].$1, equals(CellChangeType.referenceDelete));
      expect(changes[0].$2, equals({'b2'.a1}));
      expect(changes[1].$1, equals(CellChangeType.delete));
      expect(changes[1].$2, equals({'b6'.a1}));
      expect(changes[2].$1, equals(CellChangeType.add));
      expect(changes[2].$2, equals({'b6'.a1}));
    });
    test(' - add single cell with references triggers listeners', () async {
      engine['b6'.a1] = '+A1';

      expect(changes[0].$1, equals(CellChangeType.referenceDelete));
      expect(changes[0].$2, equals({'b2'.a1}));
      expect(changes[1].$1, equals(CellChangeType.delete));
      expect(changes[1].$2, equals({'b6'.a1}));
      expect(changes[2].$1, equals(CellChangeType.add));
      expect(changes[2].$2, equals({'b6'.a1}));
      expect(changes[3].$1, equals(CellChangeType.referenceAdd));
      expect(changes[3].$2, equals({'a1'.a1}));
    });
    test(' - remove single cell triggers listener', () async {
      engine.remove('b6'.a1);
      expect(changes[0].$1, equals(CellChangeType.referenceDelete));
      expect(changes[0].$2, equals({'b2'.a1}));
      expect(changes[1].$1, equals(CellChangeType.delete));
      expect(changes[1].$2, equals({'b6'.a1}));
    });
    test(' - move single cell triggers listener', () async {
      final origin = 'a2'.a1;
      final destination = 'c1'.a1;
      engine.move(origin, destination);
      expect(changes[0].$1, equals(CellChangeType.referenceDelete));
      expect(changes[0].$2, contains(origin));
      expect(changes[1].$1, equals(CellChangeType.referenceAdd));
      expect(changes[1].$2, contains(destination));
      expect(changes[2].$1, equals(CellChangeType.referenceDelete));
      expect(changes[2].$2, contains('A5'.a1));
      expect(changes[3].$1, equals(CellChangeType.delete));
      expect(changes[3].$2, contains(origin));
      expect(changes[4].$1, equals(CellChangeType.add));
      expect(changes[4].$2, contains(destination));
      expect(changes[5].$1, equals(CellChangeType.referenceAdd));
      expect(changes[5].$2, contains('A5'.a1));
    });
  });

  group('moving ranges ', () {
    final sheet = {
      'A1'.a1: '-12.2',
      'A2'.a1: '(a5+45)',
      'A3'.a1: '13',
      'A4'.a1: '+A2+A5-A6',
      'A5'.a1: '-A3/2+2',
      'A6'.a1: '.23*2',
      'B1'.a1: '+A1+A3*3',
      'B2'.a1: '(A1+A3)*3',
      'B3'.a1: '12.23e-12',
      'B4'.a1: '.12345678901234e-7',
      'B5'.a1: '+b4',
      'B6'.a1: '+b2',
      'B7'.a1: '@sum(b1...b6)',
    };
    Engine engine = Engine({});
    setUp(() {
      engine = Engine(sheet);
    });
    test(' - moving a range right to empty cell', () async {
      final range = 'a1:a6'.a1Range;
      final destination = 'c1'.a1;

      engine.moveRange(range, destination);

      expect(engine['C1'.a1]?.formulaType?.asFormula, equals('-12.2'));
      expect(engine['C2'.a1]?.formulaType?.asFormula, equals('(C5+45)'));
      expect(engine['C3'.a1]?.formulaType?.asFormula, equals('13'));
      expect(engine['C4'.a1]?.formulaType?.asFormula, equals('+C2+C5-C6'));
      expect(engine['C5'.a1]?.formulaType?.asFormula, equals('-C3/2+2'));
      expect(engine['C6'.a1]?.formulaType?.asFormula, equals('0.23*2'));

      expect(engine.referencesTo('C1'.a1), containsAll({'B2', 'B1'}.a1));
      expect(engine.referencesTo('C2'.a1), containsAll({'C4'}.a1));
      expect(engine.referencesTo('C3'.a1), containsAll({'B2', 'C5', 'B1'}.a1));
      expect(engine.referencesTo('C4'.a1), isNull);
      expect(engine.referencesTo('C5'.a1), containsAll({'C2', 'C4'}.a1));
      expect(engine.referencesTo('C6'.a1), containsAll({'C4'}.a1));
    });

    test(' - moving a range right over existing cell', () async {
      final range = 'a1:a6'.a1Range;
      final destination = 'b1'.a1;

      engine.moveRange(range, destination);

      expect(engine['B1'.a1]?.formulaType?.asFormula, equals('-12.2'));
      expect(engine['B2'.a1]?.formulaType?.asFormula, equals('(B5+45)'));
      expect(engine['B3'.a1]?.formulaType?.asFormula, equals('13'));
      expect(engine['B4'.a1]?.formulaType?.asFormula, equals('+B2+B5-B6'));
      expect(engine['B5'.a1]?.formulaType?.asFormula, equals('-B3/2+2'));
      expect(engine['B6'.a1]?.formulaType?.asFormula, equals('0.23*2'));
      expect(engine['B7'.a1]?.formulaType?.asFormula, equals('@SUM(B1...B6)'));

      expect(engine.referencesTo('B1'.a1), containsAll({'B7'}.a1));
      expect(engine.referencesTo('B2'.a1), containsAll({'B7', 'B4'}.a1));
      expect(engine.referencesTo('B3'.a1), containsAll({'B7', 'B5'}.a1));
      expect(engine.referencesTo('B4'.a1), containsAll({'B7'}.a1));
      expect(engine.referencesTo('B5'.a1), containsAll({'B7', 'B4', 'B2'}.a1));
      expect(engine.referencesTo('B6'.a1), containsAll({'B7', 'B4'}.a1));
    });
    test(' - moving a range left over existing cell', () async {
      final range = 'b1:b6'.a1Range;
      final destination = 'a1'.a1;

      engine.moveRange(range, destination);

      expect(engine['A1'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['A2'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['A3'.a1]?.formulaType?.asFormula, equals('1.223e-11'));
      expect(engine['A4'.a1]?.formulaType?.asFormula, equals('1.23457e-8'));
      expect(engine['A5'.a1]?.formulaType?.asFormula, equals('+A4'));
      expect(engine['A6'.a1]?.formulaType?.asFormula, equals('+A2'));
      expect(engine['A7'.a1]?.formulaType?.asFormula, isNull);
      expect(engine['B7'.a1]?.formulaType?.asFormula, equals('@SUM(A1...A6)'));

      expect(engine.referencesTo('A1'.a1), containsAll({'B7'}.a1));
      expect(engine.referencesTo('A2'.a1), containsAll({'A6'}.a1));
      expect(engine.referencesTo('A3'.a1), containsAll({'B7'}.a1));
      expect(engine.referencesTo('A4'.a1), containsAll({'A5'}.a1));
      expect(engine.referencesTo('B1'.a1), isNull);
      expect(engine.referencesTo('B6'.a1), isNull);
    });

    test(' - moving a column', () async {
      engine.moveColumns(0, 2);

      expect(engine['C1'.a1]?.formulaType?.asFormula, equals('-12.2'));
      expect(engine['C2'.a1]?.formulaType?.asFormula, equals('(C5+45)'));
      expect(engine['C3'.a1]?.formulaType?.asFormula, equals('13'));
      expect(engine['C4'.a1]?.formulaType?.asFormula, equals('+C2+C5-C6'));
      expect(engine['C5'.a1]?.formulaType?.asFormula, equals('-C3/2+2'));
      expect(engine['C6'.a1]?.formulaType?.asFormula, equals('0.23*2'));

      expect(engine.referencesTo('C1'.a1), containsAll({'B2', 'B1'}.a1));
      expect(engine.referencesTo('C2'.a1), containsAll({'C4'}.a1));
      expect(engine.referencesTo('C3'.a1), containsAll({'B2', 'C5', 'B1'}.a1));
      expect(engine.referencesTo('C4'.a1), isNull);
      expect(engine.referencesTo('C5'.a1), containsAll({'C2', 'C4'}.a1));
      expect(engine.referencesTo('C6'.a1), containsAll({'C4'}.a1));
    });

    test(' - moving a row', () async {
      engine.moveRows(0, 2);
      expect(engine['A3'.a1]?.formulaType?.asFormula, equals('-12.2'));
      expect(engine['B3'.a1]?.resultType, isA<ErrorResult>());
    });
    test(' - moving an empty row', () async {
      engine.move('A7'.a1, 'A8'.a1);
      expect(engine['A8'.a1]?.formulaType?.asFormula, isNull);
    });
    test(' - moving a 2 rows', () async {
      engine.moveRows(0, 2, 2);
      expect(engine['A3'.a1]?.formulaType?.asFormula, equals('-12.2'));
      expect(engine['B3'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['A4'.a1]?.formulaType?.asFormula, equals('(A5+45)'));
      expect(engine['B4'.a1]?.resultType, isA<ErrorResult>());
    });
    test(' - clear columns', () async {
      engine.clearColumns(1);
      expect(engine['B1'.a1]?.formulaType?.asFormula, isNull);
      expect(engine['B7'.a1]?.formulaType?.asFormula, isNull);

      expect(engine['A1'.a1]?.formulaType?.asFormula, equals('-12.2'));
      expect(engine['A5'.a1]?.formulaType?.asFormula, equals('-A3/2+2'));
    });
    test(' - clear rows', () async {
      engine.clearRows(0, 2);

      expect(engine['A1'.a1]?.formulaType?.asFormula, isNull);
      expect(engine['B2'.a1]?.formulaType?.asFormula, isNull);

      expect(engine['A3'.a1]?.formulaType?.asFormula, equals('13'));
      expect(engine['B5'.a1]?.formulaType?.asFormula, equals('+B4'));
    });
    test(' - delete columns', () async {
      engine.deleteColumns(0);

      expect(engine['A1'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['a7'.a1]?.formulaType?.asFormula, equals('@SUM(A1...A6)'));
    });
    test(' - delete rows', () async {
      engine.deleteRows(0, 2);
      expect(engine['a1'.a1]?.formulaType?.asFormula, equals('13'));
      expect(engine['A2'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['A5'.a1]?.resultType, isNull);
      expect(engine['B4'.a1]?.resultType, isA<ErrorResult>());
      expect(engine['B5'.a1]?.resultType, isA<ErrorResult>());

      expect(engine.referencesTo('A1'.a1), containsAll({'A3'}.a1));
      expect(engine.referencesTo('B2'.a1), containsAll({'B5', 'B3'}.a1));
    });
    test(' - insert cols', () async {
      engine.insertColumns(1, 2);

      expect(engine['B1'.a1]?.formulaType?.asFormula, isNull);
      expect(engine['B5'.a1]?.formulaType?.asFormula, isNull);
      expect(engine['C2'.a1]?.formulaType?.asFormula, isNull);
      expect(engine['C6'.a1]?.formulaType?.asFormula, isNull);

      expect(engine['D1'.a1]?.formulaType?.asFormula, equals('+A1+A3*3'));
      expect(engine['D7'.a1]?.formulaType?.asFormula, equals('@SUM(D1...D6)'));

      expect(engine['D1'.a1]?.resultType, isA<NumberResult>());
      expect(engine['D5'.a1]?.resultType, isA<NumberResult>());
      expect(engine['D7'.a1]?.resultType, isA<NumberResult>());

      expect(engine.referencesTo('D3'.a1), containsAll({'D7'}.a1));
      expect(engine.referencesTo('D4'.a1), containsAll({'D7', 'D5'}.a1));
    });

    test(' - insert rows', () async {
      engine.insertRows(1, 3);

      expect(engine['a1'.a1]?.formulaType?.asFormula, equals('-12.2'));
      expect(engine['A2'.a1]?.formulaType?.asFormula, isNull);
      expect(engine['B2'.a1]?.formulaType?.asFormula, isNull);
      expect(engine['A3'.a1]?.formulaType?.asFormula, isNull);
      expect(engine['B3'.a1]?.formulaType?.asFormula, isNull);
      expect(engine['A4'.a1]?.formulaType?.asFormula, isNull);
      expect(engine['B4'.a1]?.formulaType?.asFormula, isNull);
      expect(engine['B10'.a1]?.formulaType?.asFormula, equals('@SUM(B1...B9)'));

      expect(engine.referencesTo('A1'.a1), containsAll({'B5', 'B1'}.a1));
      expect(engine.referencesTo('B2'.a1), containsAll({'B10'}.a1));
    });
  });
  group('misc methods', () {
    Engine engine = Engine({});
    setUp(() {
      engine = Engine({
        'A1'.a1: '+A2',
        'A2'.a1: '12',
        'A3'.a1: '/-=',
      }, parseErrorThrows: true);
    });
    test(' - insert a null to delete', () async {
      engine['A1'.a1] = null;
      expect(engine['A1'.a1], isNull);
    });
    test(' - columnsAndRows', () async {
      expect(
          engine.columnsAndRows(criteria: (a1) => false).$1, equals(<int>[]));
      expect(
          engine.columnsAndRows(criteria: (a1) => false).$2, equals(<int>[]));
    });
    test(' - iterator', () async {
      expect(engine.iterator.moveNext(), isTrue);
    });
    test(' - toString', () async {
      expect(
          engine.toString(),
          equals('          A fx           |          A           | \n'
              '------------------------------------------------\n'
              ' 1  +A2                  | 12                   | \n'
              ' 2  12                   | 12                   | \n'
              ' 3  =                    | ==================== | \n'
              ''));
    });
    test(' - referenceToString', () async {
      expect(
        engine.referencesToString(),
        equals('A2: {A1}            \n'),
      );
    });
  });
}
