import 'package:test/test.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  test('empty', () async {
    final cell = Cell();
    expect(cell.format, CellFormat.defaultFormat);
    expect(cell.formulaType, isNull);
    expect(cell.resultType, isNull);
    expect(cell.toString(), '');
  });

  test('expression', () async {
    final formula = NumType(23);
    final result = NumberResult(23);
    final cellValue = Cell(
      content: ExpressionContent(formula),
      resultTypeCacheFunc: () => ResultTypeCache({}),
    );

    expect(cellValue.formulaType, formula);
    expect(cellValue.resultType, result);
    expect(cellValue.toString(), equals('23'));
  });
  test('expression number formats', () async {
    final content = ExpressionContent(NumType(8));
    final cell0 = Cell(content: content, format: CellFormat.defaultFormat);
    final cell1 = Cell(content: content, format: CellFormat.dollars);
    final cell2 = Cell(content: content, format: CellFormat.graph);
    final cell3 = Cell(content: content, format: CellFormat.left);
    final cell4 = Cell(content: content, format: CellFormat.right);
    final cell5 = Cell(content: content, format: CellFormat.integer);

    expect(cell0.formattedString(5), equals('8    '));
    expect(cell1.formattedString(5), equals('8.00 '));
    expect(cell2.formattedString(5), equals('*****'));
    expect(cell3.formattedString(5), equals('8    '));
    expect(cell4.formattedString(5), equals('    8'));
    expect(cell5.formattedString(5), equals('8    '));
  });
  test('expression label formats', () async {
    final content = ExpressionContent(LabelType('abc'));
    final cell0 = Cell(content: content, format: CellFormat.defaultFormat);
    final cell1 = Cell(content: content, format: CellFormat.dollars);
    final cell2 = Cell(content: content, format: CellFormat.graph);
    final cell3 = Cell(content: content, format: CellFormat.left);
    final cell4 = Cell(content: content, format: CellFormat.right);
    final cell5 = Cell(content: content, format: CellFormat.integer);
    final cell6 = Cell(content: content, format: null);

    expect(cell0.formattedString(5), equals('abc  '));
    expect(cell1.formattedString(5), equals('abc  '));
    expect(cell2.formattedString(5), equals('abc  '));
    expect(cell3.formattedString(5), equals('abc  '));
    expect(cell4.formattedString(5), equals('  abc'));
    expect(cell5.formattedString(5), equals('abc  '));
    expect(cell6.formattedString(5), equals('abc  '));
  });
  test('null content / format', () async {
    final cell1 = Cell(content: null, format: CellFormat.dollars);
    final cell2 = Cell(content: null, format: CellFormat.graph);
    final cell3 = Cell(content: null, format: CellFormat.integer);

    expect(cell1.formattedString(5), equals(''.padRight(5)));
    expect(cell2.formattedString(5), equals(''.padRight(5)));
    expect(cell3.formattedString(5), equals(''.padRight(5)));
  });
  test('repeating format', () async {
    final cellValue = Cell(content: RepeatingContent('='));
    expect(cellValue.formattedString(20), equals(''.padRight(20, "=")));
  });
  test('equality of cells', () async {
    final content = NumType(1);
    final expressionContent = ExpressionContent(content);
    final cell1 = Cell(content: expressionContent);
    final cell2 = Cell(content: ExpressionContent(LabelType('hello')));
    final cell3 = Cell(content: RepeatingContent('='));
    final cell4 = Cell(content: expressionContent, format: CellFormat.dollars);
    final cell5 = Cell(
        content: expressionContent,
        resultTypeCacheFunc: () => ResultTypeCache({}));

    expect(cell1 == cell2, isFalse);
    expect(cell2 == cell3, isFalse);
    expect(cell1 == cell3, isFalse);
    expect(cell1.hashCode == cell2.hashCode, isFalse);
    expect(cell2.hashCode,
        equals(Cell(content: ExpressionContent(LabelType('hello'))).hashCode));

    expect(cell4 == cell1, isFalse);
    expect(cell5 == cell1, isFalse);
  });
}
