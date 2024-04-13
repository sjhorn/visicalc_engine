import 'package:petitparser/petitparser.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

class ExpressionContent extends CellContent {
  static final evaluator = Evaluator().build();

  final FormulaType formulaType;
  ExpressionContent(this.formulaType);

  factory ExpressionContent.fromString(String expression) {
    final ast = evaluator.parse(expression);
    if (ast is Success) {
      return ExpressionContent(ast.value);
    } else {
      final failure = ast as Failure;
      return ExpressionContent(ErrorType(failure.message));
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpressionContent && other.formulaType == formulaType;
  }

  @override
  int get hashCode => formulaType.hashCode;

  @override
  String toString() => 'Expression<${formulaType.asFormula}>';
}
