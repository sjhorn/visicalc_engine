import 'package:petitparser/petitparser.dart';
import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

import 'format_expression.dart';

class FileFormat extends FormatExpression {
  @override
  Parser start() => [
        cellContent(),
        globalDirective(),
      ].toChoiceParser().end();

  // >A9:/FR"TRUE
  // >G8:+F8*10
  // >F8:+F7+1
  // >E8:"tes
  // >B8:@SUM(A2...A7)
  // >A8:/FR"label
  // >A10:/-=
  Parser<A1> cellPosition() =>
      seq3(char('>'), ref0(a1), char(':')).map3((p0, p1, p2) => A1.parse(p1));

  Parser<MapEntry<A1, Cell>> cellPositionExpression() =>
      seq2(cellPosition(), cellContent()).map2((p0, p1) => MapEntry(p0, p1));

  // /W1
  // /GOC
  // /GRA
  // /GC10
  // /X>A1:>C14:
  Parser<GlobalDirectiveContent> globalDirective() => seq2(char('/'),
          [word(), char(':'), char('>')].toChoiceParser().plus().flatten())
      .map2((p0, p1) => GlobalDirectiveContent(p1));
}
