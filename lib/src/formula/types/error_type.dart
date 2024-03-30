import '../result_cache_map.dart';
import '../results/error_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';

class ErrorType extends FormulaType {
  @override
  ResultType eval(ResultCacheMap resultCache,
          [List<FormulaType>? visitedList]) =>
      ErrorResult();

  @override
  String get asFormula => '@ERROR';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
  }
}
