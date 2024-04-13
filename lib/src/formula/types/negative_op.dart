import 'package:visicalc_engine/visicalc_engine.dart';

class NegativeOp extends FormulaType {
  FormulaType value;
  NegativeOp(this.value);

  @override
  ResultType eval(ResultTypeCache resultCache,
      [List<FormulaType>? visitedList]) {
    visitedList ??= [];
    final valueResult = value.eval(resultCache, [...visitedList, this]);
    if (valueResult is! NumberResult) {
      return valueResult;
    }
    return NumberResult(-1 * valueResult.value);
  }

  @override
  String toString() => 'NegativeOp($value)';

  @override
  String get asFormula => '-${value.asFormula}';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    value.visit(callback);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NegativeOp && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
