import 'package:visicalc_engine/visicalc_engine.dart';

class BinaryNumOp extends FormulaType {
  final String name;
  final FormulaType left;
  final FormulaType right;

  final num Function(num left, num right) function;
  BinaryNumOp(
    this.name,
    this.left,
    this.right,
    this.function,
  );

  @override
  ResultType eval(ResultTypeCache resultCache,
      [List<FormulaType>? visitedList]) {
    final leftResult = left.eval(resultCache, visitedList);
    final rightResult = right.eval(resultCache, visitedList);
    if (leftResult is ErrorResult || rightResult is ErrorResult) {
      return ErrorResult();
    } else if (leftResult is! NumberResult || rightResult is! NumberResult) {
      return NumberResult(0);
    }

    return NumberResult(function(leftResult.value, rightResult.value));
  }

  @override
  String toString() => 'BinaryNumOp($name)';

  @override
  String get asFormula => '${left.asFormula}$name${right.asFormula}';

  @override
  void visit(FormulaTypeVisitor callback) {
    left.visit(callback);
    callback(this);
    right.visit(callback);
  }
}
