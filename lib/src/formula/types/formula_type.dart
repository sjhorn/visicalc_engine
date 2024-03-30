import '../result_cache_map.dart';
import '../results/result_type.dart';

typedef FormulaTypeVisitor = void Function(FormulaType instance);

abstract class FormulaType {
  ResultType eval(ResultCacheMap resultCache, [List<FormulaType>? visitedList]);

  String get asFormula;

  void visit(FormulaTypeVisitor callback);
}
