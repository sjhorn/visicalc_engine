import 'package:test/test.dart';
import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  final parser = Evaluator().build<FormulaType>();

  group('references', () {
    test('forward references', () async {
      final root = parser.parse('+A3*B4/C1...D2,C5').value;
      final references = [];
      root.visit((instance) {
        if (instance is ReferenceType) references.add(instance.a1);
      });
      expect(references,
          containsAll(['A3', 'B4', 'C1', 'C2', 'D1', 'D2', 'C5'].a1));
    });

    test('cell depedencies', () async {
      Map<A1, FormulaType> cells = {
        'A1'.a1: parser.parse('+A3*B4/C1...D2,C5').value,
        'E1'.a1: parser.parse('+A3*B4/C1...D2,C5').value,
        'F10'.a1: parser.parse('+A3*B4/C1...D2,C5').value,
        'H2'.a1: parser.parse('+A3*B4/C1...D2,C5').value,
      };
      Map<A1, List<A1>> dependencyMap = {};
      for (final MapEntry(:key, :value) in cells.entries) {
        value.visit((instance) {
          if (instance is ReferenceType) {
            (dependencyMap[instance.a1] ??= []).add(key);
          }
        });
      }
      //print(dependencyMap);
    });
  });
}
