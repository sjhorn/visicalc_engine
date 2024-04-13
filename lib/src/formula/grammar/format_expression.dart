import 'package:petitparser/petitparser.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

import 'expression.dart';

class FormatExpression extends Expression {
  @override
  Parser start() => cellContent().end();

  // CellFormat.general => '',
  // CellFormat.dollars => '/F\$',
  // CellFormat.graph => '/F*',
  // CellFormat.integer => '/FI',
  // CellFormat.left => '/FL',
  // CellFormat.right => '/FR',
  Parser<String> cellFormat() =>
      seq2(string('/F'), anyOf('\$*ILR')).map2((p0, p1) => p1);

  Parser<LabelContent> label() =>
      seq2(ref0(_labelChars), any().plus().flatten())
          .map2((p0, p1) => LabelContent(p1));

  Parser<String> _labelChars() => [char('"'), pattern('A-Z')].toChoiceParser();

  Parser<RepeatingContent> repeating() =>
      seq2(string('/-'), any().plus().flatten())
          .map2((p0, p1) => RepeatingContent(p1));

  Parser<Cell> cellContent() => seq2(
              cellFormat().optional(),
              [
                expressionWithList()
                    .flatten()
                    .map((value) => ExpressionContent.fromString(value)),
                label(),
                repeating(),
              ].toChoiceParser())
          .map2(
        (format, content) => Cell(
          content: content,
          format: CellFormat.fromChar(format),
        ),
      );
}
