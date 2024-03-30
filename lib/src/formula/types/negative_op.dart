import '../result_cache_map.dart';
import '../results/number_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';

class NegativeOp extends FormulaType {
  FormulaType value;
  NegativeOp(this.value);

  @override
  ResultType eval(ResultCacheMap resultCache,
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
}
