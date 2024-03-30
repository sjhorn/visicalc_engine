import 'package:test/test.dart';
import 'package:a1/a1.dart';
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

    test('cell expression', () async {
      final parser = fileFormat.buildFrom(fileFormat.cellExpression());
      expect(parser.parse('>A9:/FR"TRUE').value,
          equals(('A9'.a1, 'R', LabelFormat('TRUE'))));
      expect(parser.parse('>G9:/-=').value,
          equals(('G9'.a1, null, RepeatingFormat('='))));
      expect(parser.parse('>G8:+F8*10').value,
          equals(('G8'.a1, null, ExpressionFormat('+F8*10'))));
      expect(parser.parse('>F8:+F7+1').value,
          equals(('F8'.a1, null, ExpressionFormat('+F7+1'))));
      expect(parser.parse('>E8:"tes').value,
          equals(('E8'.a1, null, LabelFormat('tes'))));
      expect(parser.parse('>B8:@SUM(A2...A7)').value,
          equals(('B8'.a1, null, ExpressionFormat('@SUM(A2...A7)'))));
      expect(parser.parse('>A8:/FR"label').value,
          equals(('A8'.a1, 'R', LabelFormat('label'))));
      expect(parser.parse('>A10:/-=').value,
          equals(('A10'.a1, null, RepeatingFormat('='))));
    });

    test('global directive', () async {
      final parser = fileFormat.buildFrom(fileFormat.start());

      expect(parser.parse('/W1').value, equals(GlobalDirectiveFormat('W1')));
      expect(parser.parse('/GOC').value, equals(GlobalDirectiveFormat('GOC')));
      expect(parser.parse('/GRA').value, equals(GlobalDirectiveFormat('GRA')));
      expect(parser.parse('/X>A1:>C14:').value,
          equals(GlobalDirectiveFormat('X>A1:>C14:')));
    });

    test('hashCodes', () async {
      expect(LabelFormat('test').hashCode, LabelFormat('test').hashCode);
      expect(
        ExpressionFormat('+A1').hashCode,
        ExpressionFormat('+A1').hashCode,
      );
      expect(
        GlobalDirectiveFormat('/GC10').hashCode,
        GlobalDirectiveFormat('/GC10').hashCode,
      );
      expect(
        RepeatingFormat('/-=').hashCode,
        RepeatingFormat('/-=').hashCode,
      );
      expect(RepeatingFormat('=').toString(), equals('='));
    });
  });
}
