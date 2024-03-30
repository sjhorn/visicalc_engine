import '../result_cache_map.dart';

import '../results/number_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';

class PiType extends FormulaType {
  @override
  ResultType eval(ResultCacheMap resultCache,
          [List<FormulaType>? visitedList]) =>
      NumberResult(3.1415926536);

  @override
  String get asFormula => '@PI';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
  }
}
