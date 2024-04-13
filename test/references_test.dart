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
    test('move reference', () async {
      final ref = ReferenceType('A1'.a1);
      expect(ref.a1, equals('A1'.a1));
      ref.moveTo('B1'.a1);
      expect(ref.a1, equals('B1'.a1));
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
    });
    test('cell lookup depedencies', () async {
      Map<A1, Cell> sheet = {
        'a1'.a1: NumType(1).cell,
        'a2'.a1: NumType(2).cell,
        'a3'.a1: NumType(3).cell,
        'a4'.a1: NumType(4).cell,
        'b1'.a1: NumType(10).cell,
        'b2'.a1: NumType(20).cell,
        'b3'.a1: NumType(30).cell,
      };
      final result = parser.parse('+A4+@LOOKUP(1,A1...A3)').value;
      expect(result.references, containsAll({'A1', 'A2', 'A3', 'A4'}.a1));
      expect(result.references, containsAll({'B1', 'B2', 'B3'}.a1));
      expect(result.eval(ResultTypeCache(sheet)), isA<NumberResult>());
      result.markDeletedCell('C1'.a1);
      expect(result.eval(ResultTypeCache(sheet)), isA<NumberResult>());
      result.markDeletedCell('A1'.a1);
      expect(result.eval(ResultTypeCache(sheet)), isA<ErrorResult>());
    });
  });
}
