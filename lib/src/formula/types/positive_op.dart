import '../result_cache_map.dart';
import '../results/number_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';

class PositiveOp extends FormulaType {
  FormulaType value;
  PositiveOp(this.value);

  @override
  ResultType eval(ResultCacheMap resultCache,
      [List<FormulaType>? visitedList]) {
    visitedList ??= [];
    final valueResult = value.eval(resultCache, [...visitedList, this]);
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
}
