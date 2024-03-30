import 'package:test/test.dart';
import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  final references = Evaluator();

  (FormulaType, List<FormulaType>) parseFormulaTree(String expression) {
    FormulaType formula = references.build().parse(expression).value;
    List<FormulaType> tree = [];
    formula.visit((instance) => tree.add(instance));
    return (formula, tree);
  }

  group('visit instances', () {
    test('references', () async {
      expect(
        parseFormulaTree('+A1+B2').$2,
        containsAll([
          ReferenceType('a1'.a1),
          ReferenceType('b2'.a1),
        ]),
      );
      expect(
        parseFormulaTree('+A1+B2+@Sum(c1...d2)').$2,
        containsAll([
          ReferenceType('a1'.a1),
          ReferenceType('b2'.a1),
          ReferenceType('c1'.a1),
          ReferenceType('d2'.a1),
        ]),
      );
      expect(
        parseFormulaTree('+A1+B2+@Sum(c1,d2,e2)').$2,
        containsAll([
          ReferenceType('a1'.a1),
          ReferenceType('b2'.a1),
          ReferenceType('c1'.a1),
          ReferenceType('d2'.a1),
          ReferenceType('e2'.a1),
        ]),
      );
    });

    test('adjust references', () async {
      final (formula, tree) = parseFormulaTree('+A1+B2');
      expect(formula.asFormula, equals('+A1+B2'));
      for (ReferenceType ref in tree.whereType<ReferenceType>()) {
        ref.move(1, 1);
      }
      expect(formula.asFormula, equals('+B2+C3'));
    });
  });
}
