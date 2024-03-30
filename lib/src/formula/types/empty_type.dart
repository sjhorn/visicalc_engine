import '../result_cache_map.dart';
import '../results/empty_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';

class EmptyType extends FormulaType {
  EmptyType();

  @override
  ResultType eval(ResultCacheMap resultCache,
          [List<FormulaType>? visitedList]) =>
      EmptyResult();

  @override
  String get asFormula => '';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
  }
}
