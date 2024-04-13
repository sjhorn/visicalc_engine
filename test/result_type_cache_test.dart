import 'package:test/test.dart';
import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  final evaluator = Evaluator();

  group('references', () {
    final Map<A1, Cell> cells = {
      'B2'.a1: Cell.fromFormulaType(NumType(12.23)),
    };
    final resultCache = ResultTypeCache(cells);
    FormulaType formulaType =
        evaluator.build<FormulaType>().parse('+A1+B2').value;

    test('forward reference', () async {
      cells['A1'.a1] = Cell.fromFormulaType(NumType(12));

      if (formulaType.eval(resultCache) case NumberResult(:var value)) {
        expect(value, equals(24.23));
      } else {
        fail('Invalid result');
      }
    });
    test('cached reference', () async {
      cells['A1'.a1] = Cell.fromFormulaType(NumType(12));
      formulaType.eval(resultCache); // cache 12

      cells['A1'.a1] = Cell.fromFormulaType(NumType(13));
      if (formulaType.eval(resultCache) case NumberResult(:var value)) {
        expect(value, equals(24.23));
      } else {
        fail('Invalid result');
      }
    });
    test('clear cached reference', () async {
      cells['A1'.a1] = Cell.fromFormulaType(NumType(12));
      formulaType.eval(resultCache); // cache 12

      cells['A1'.a1] = Cell.fromFormulaType(NumType(13));
      resultCache.removeAll({'A1'.a1});
      if (formulaType.eval(resultCache) case NumberResult(:var value)) {
        expect(value, equals(25.23));
      } else {
        fail('Invalid result');
      }
    });
    test('clear all cached reference', () async {
      cells['A1'.a1] = Cell.fromFormulaType(NumType(12));
      formulaType.eval(resultCache); // cache 12

      cells['A1'.a1] = Cell.fromFormulaType(NumType(13));
      resultCache.clear();
      if (formulaType.eval(resultCache) case NumberResult(:var value)) {
        expect(value, equals(25.23));
      } else {
        fail('Invalid result');
      }
    });
  });

  group('ResultTypeCache', () {
    ResultTypeCache resultTypeCacheMap = ResultTypeCache({});
    Map<A1, Cell> sheet = {};
    setUp(() {
      sheet = {
        'A1'.a1: ReferenceType('B2'.a1).cell,
        'A2'.a1: Cell(content: LabelContent('test')),
        'B2'.a1: NumType(23).cell,
        'C3'.a1: BinaryNumOp(
          '+',
          ReferenceType('A1'.a1),
          ReferenceType('B2'.a1),
          (left, right) => left + right,
        ).cell
      };
      resultTypeCacheMap = ResultTypeCache(sheet);

      // eval and cache
      resultTypeCacheMap.evalAndCache('A1'.a1, []);
      resultTypeCacheMap.evalAndCache('B2'.a1, []);
      resultTypeCacheMap.evalAndCache('C3'.a1, []);
    });
    test(' adds value to cache', () async {
      expect(resultTypeCacheMap, containsPair('A1'.a1, NumberResult(23)));
    });

    test(' uses cached value', () async {
      sheet['C3'.a1] = Cell.fromFormulaType(NumType(1));
      expect(
        resultTypeCacheMap.evalAndCache('C3'.a1, []),
        equals(NumberResult(46)),
      );
      resultTypeCacheMap.removeAll({'C3'.a1});
      expect(
        resultTypeCacheMap.evalAndCache('C3'.a1, []),
        equals(NumberResult(1)),
      );
    });

    test(' removes value from cache', () async {
      final a1 = 'A1'.a1;
      final result = resultTypeCacheMap.removeAll({a1}).first;
      expect(resultTypeCacheMap.containsKey(a1), isFalse);
      expect(result, equals(NumberResult(23)));
    });

    test(' iterates and clears correctly', () async {
      int countEm() {
        int count = 0;
        final iterator = resultTypeCacheMap.iterator;
        while (iterator.moveNext()) {
          count++;
        }
        return count;
      }

      expect(resultTypeCacheMap.iterator, isA<Iterator>());
      expect(countEm(), equals(3));

      resultTypeCacheMap.removeAll({'A1'.a1});
      expect(countEm(), equals(2));

      resultTypeCacheMap.clear();
      expect(countEm(), equals(0));
    });
    test(' invalid cache item', () async {
      expect(() => resultTypeCacheMap.evalAndCache('a2'.a1, []),
          throwsA(isA<FormatException>()));
    });
  });
}
