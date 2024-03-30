import 'package:a1/a1.dart';

import 'results/result_type.dart';
import 'types/formula_type.dart';

typedef EvalCallback = ResultType Function(A1 cell, ResultCacheMap map);

class ResultCacheMap {
  final Map<A1, FormulaType> cells;
  final Map<A1, ResultType> _resultCache = {};

  final List<Function()> listeners = [];
  ResultCacheMap(this.cells);

  ResultType? evalAndCache(A1 key, List<FormulaType> visitedList) {
    if (!_resultCache.containsKey(key) && cells.containsKey(key)) {
      _resultCache[key] = cells[key]!.eval(this, visitedList);
    }
    return _resultCache[key];
  }

  ResultType? remove(Object? key) {
    final result = _resultCache.remove(key);
    return result;
  }

  void clear() => _resultCache.clear();
}
