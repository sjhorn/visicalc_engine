import 'package:test/test.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  test('reference type', () async {
    final formula = NumType(23);
    final result = NumberResult(23);
    final cellValue = CellValue(() => formula, () => result);

    expect(cellValue.formulaType, formula);
    expect(cellValue.resultType, result);
    expect(cellValue.toString(), equals('23'));
    expect(CellValue(() => null, () => null).toString(), equals('null'));
  });
}
