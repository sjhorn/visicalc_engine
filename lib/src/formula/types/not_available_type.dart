import '../result_cache_map.dart';

import '../results/not_available_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';

class NotAvailableType extends FormulaType {
  @override
  ResultType eval(ResultCacheMap resultCache,
          [List<FormulaType>? visitedList]) =>
      NotAvailableResult();

  @override
  String get asFormula => '@NA';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
  }
}
