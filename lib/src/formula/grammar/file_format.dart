import 'package:petitparser/petitparser.dart';
import 'package:a1/a1.dart';

import 'expression.dart';

class FileFormat extends Expression {
  @override
  Parser start() => [
        cellExpression(),
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
      seq3(char('>'), a1(), char(':')).map3((p0, p1, p2) => A1.parse(p1));

  // CellFormat.general => '',
  // CellFormat.dollars => '/F\$',
  // CellFormat.graph => '/F*',
  // CellFormat.integer => '/FI',
  // CellFormat.left => '/FL',
  // CellFormat.right => '/FR',
  Parser<String> cellFormat() =>
      seq2(string('/F'), anyOf('\$*ILR')).map2((p0, p1) => p1);

  Parser<LabelFormat> label() =>
      seq2(char('"'), any().plus().flatten()).map2((p0, p1) => LabelFormat(p1));

  Parser<RepeatingFormat> repeating() =>
      seq2(string('/-'), any().plus().flatten())
          .map2((p0, p1) => RepeatingFormat(p1));

  Parser cellExpression() => seq3(
      cellPosition(),
      cellFormat().optional(),
      [
        expressionWithList().flatten().map((value) => ExpressionFormat(value)),
        label(),
        repeating(),
      ].toChoiceParser());

  // /W1
  // /GOC
  // /GRA
  // /GC10
  // /X>A1:>C14:
  Parser<GlobalDirectiveFormat> globalDirective() => seq2(char('/'),
          [word(), char(':'), char('>')].toChoiceParser().plus().flatten())
      .map2((p0, p1) => GlobalDirectiveFormat(p1));
}

class LabelFormat {
  final String label;
  LabelFormat(this.label);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LabelFormat && other.label == label;
  }

  @override
  int get hashCode => label.hashCode;
}

class ExpressionFormat {
  final String expression;
  ExpressionFormat(this.expression);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExpressionFormat && other.expression == expression;
  }

  @override
  int get hashCode => expression.hashCode;
}

class GlobalDirectiveFormat {
  final String directive;
  GlobalDirectiveFormat(this.directive);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GlobalDirectiveFormat && other.directive == directive;
  }

  @override
  int get hashCode => directive.hashCode;
}

class RepeatingFormat {
  final String pattern;
  RepeatingFormat(this.pattern);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RepeatingFormat && other.pattern == pattern;
  }

  @override
  int get hashCode => pattern.hashCode;

  @override
  String toString() => pattern;
}
