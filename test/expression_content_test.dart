import 'package:test/test.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  test('expression content', () async {
    final ec = ExpressionContent.fromString('+');

    expect(ec.formulaType, isA<ErrorType>());
    expect(ec.toString(), equals('Expression<@ERROR>'));
  });
}
