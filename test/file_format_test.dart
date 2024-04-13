import 'package:a1/a1.dart';
import 'package:test/test.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  final fileFormat = FileFormat();

  group('cell expression', () {
    test('cell position', () async {
      final parser = fileFormat.buildFrom(fileFormat.cellPosition());

      expect(parser.parse('>A9:/FR"TRUE').value, equals('A9'.a1));
      expect(parser.parse('>G8:+F8*10').value, equals('G8'.a1));
      expect(parser.parse('>F8:+F7+1').value, equals('F8'.a1));
      expect(parser.parse('>E8:"tes').value, equals('E8'.a1));
      expect(parser.parse('>B8:@SUM(A2...A7)').value, equals('B8'.a1));
      expect(parser.parse('>A8:/FR"label').value, equals('A8'.a1));
    });

    test('cell format', () async {
      final parser = fileFormat.buildFrom(fileFormat.cellFormat());
      expect(parser.parse('/FR').value, equals('R'));
      expect(parser.parse('/F*').value, equals('*'));
      expect(parser.parse('/F\$').value, equals('\$'));
    });

    test('cell position expression', () async {
      final parser = fileFormat.buildFrom(fileFormat.cellPositionExpression());

      (A1, String?, CellContent?) parseString(String src) {
        final ast = parser.parse(src);
        return (
          ast.value.key,
          ast.value.value.format?.toChar,
          ast.value.value.content
        );
      }

      expect(parseString('>A9:/FR"TRUE'),
          equals(('A9'.a1, 'R', LabelContent('TRUE'))));
      expect(parseString('>G9:/-='),
          equals(('G9'.a1, null, RepeatingContent('='))));
      expect(parseString('>G8:+F8*10'),
          equals(('G8'.a1, null, ExpressionContent.fromString('+F8*10'))));
      expect(parseString('>F8:+F7+1'),
          equals(('F8'.a1, null, ExpressionContent.fromString('+F7+1'))));
      expect(parseString('>E8:"tes'),
          equals(('E8'.a1, null, LabelContent('tes'))));
      expect(
          parseString('>B8:@SUM(A2...A7)'),
          equals(
              ('B8'.a1, null, ExpressionContent.fromString('@SUM(A2...A7)'))));
      expect(parseString('>A8:/FR"label'),
          equals(('A8'.a1, 'R', LabelContent('label'))));
      expect(parseString('>A10:/-='),
          equals(('A10'.a1, null, RepeatingContent('='))));
    });

    test('global directive', () async {
      final parser = fileFormat.buildFrom(fileFormat.start());

      expect(parser.parse('/W1').value, equals(GlobalDirectiveContent('W1')));
      expect(parser.parse('/GOC').value, equals(GlobalDirectiveContent('GOC')));
      expect(parser.parse('/GRA').value, equals(GlobalDirectiveContent('GRA')));
      expect(parser.parse('/X>A1:>C14:').value,
          equals(GlobalDirectiveContent('X>A1:>C14:')));
    });

    test('hashCodes', () async {
      expect(LabelContent('test').hashCode, LabelContent('test').hashCode);
      expect(
        ExpressionContent.fromString('+A1').hashCode,
        ExpressionContent.fromString('+A1').hashCode,
      );
      expect(
        GlobalDirectiveContent('/GC10').hashCode,
        GlobalDirectiveContent('/GC10').hashCode,
      );
      expect(
        RepeatingContent('/-=').hashCode,
        RepeatingContent('/-=').hashCode,
      );
      expect(RepeatingContent('=').toString(), equals('='));
    });
  });
}
