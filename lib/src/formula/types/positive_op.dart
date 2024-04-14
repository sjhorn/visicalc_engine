import 'package:visicalc_engine/visicalc_engine.dart';

class PositiveOp extends FormulaType {
  FormulaType value;
  PositiveOp(this.value);

  @override
  ResultType eval(ResultTypeCache resultCache,
      [List<FormulaType>? visitedList]) {
    visitedList ??= [];
    final valueResult = value.eval(resultCache, [...visitedList]);
    if (valueResult is! NumberResult) {
      return valueResult;
    }
    return NumberResult(valueResult.value);
  }

  @override
  String toString() => 'PositiveOp($value)';

  @override
  String get asFormula => '+${value.asFormula}';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    value.visit(callback);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is FormulaType && other is! PositiveOp) {
      return other == value;
    }

    return other is PositiveOp && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
