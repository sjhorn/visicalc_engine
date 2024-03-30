import '../result_cache_map.dart';
import '../results/result_type.dart';
import 'formula_type.dart';

class BracketsType extends FormulaType {
  FormulaType value;
  BracketsType(this.value);

  @override
  ResultType eval(ResultCacheMap resultCache,
      [List<FormulaType>? visitedList]) {
    visitedList ??= [];
    return value.eval(resultCache, [...visitedList, this]);
  }

  @override
  String toString() => 'BracketsType($value)';

  @override
  String get asFormula => '(${value.asFormula})';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    value.visit(callback);
  }
}
