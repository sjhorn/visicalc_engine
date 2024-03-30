import 'package:test/test.dart';
import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  final evaluator = Evaluator();

  group('references', () {
    final Map<A1, FormulaType> cells = {
      'B2'.a1: NumType(12.23),
    };
    final resultCache = ResultCacheMap(cells);
    FormulaType formulaType =
        evaluator.build<FormulaType>().parse('+A1+B2').value;

    test('forward reference', () async {
      cells['A1'.a1] = NumType(12);

      if (formulaType.eval(resultCache) case NumberResult(:var value)) {
        expect(value, equals(24.23));
      } else {
        fail('Invalid result');
      }
    });
    test('cached reference', () async {
      cells['A1'.a1] = NumType(12);
      formulaType.eval(resultCache); // cache 12

      cells['A1'.a1] = NumType(13);
      if (formulaType.eval(resultCache) case NumberResult(:var value)) {
        expect(value, equals(24.23));
      } else {
        fail('Invalid result');
      }
    });
    test('clear cached reference', () async {
      cells['A1'.a1] = NumType(12);
      formulaType.eval(resultCache); // cache 12

      cells['A1'.a1] = NumType(13);
      resultCache.remove('A1'.a1);
      if (formulaType.eval(resultCache) case NumberResult(:var value)) {
        expect(value, equals(25.23));
      } else {
        fail('Invalid result');
      }
    });
    test('clear all cached reference', () async {
      cells['A1'.a1] = NumType(12);
      formulaType.eval(resultCache); // cache 12

      cells['A1'.a1] = NumType(13);
      resultCache.clear();
      if (formulaType.eval(resultCache) case NumberResult(:var value)) {
        expect(value, equals(25.23));
      } else {
        fail('Invalid result');
      }
    });
  });
}
