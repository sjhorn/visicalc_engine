import 'package:a1/a1.dart';

import 'package:visicalc_engine/visicalc_engine.dart';

typedef EvalCallback = ResultType Function(A1 cell, ResultTypeCache map);

class ResultTypeCache extends Iterable<MapEntry<A1, ResultType>> {
  final Map<A1, Cell> sheet;
  final Map<A1, ResultType> _resultTypeCache = {};

  final List<Function()> listeners = [];
  ResultTypeCache(this.sheet);

  ResultType? evalAndCache(A1 key, List<FormulaType> visitedList) {
    if (!_resultTypeCache.containsKey(key) && sheet.containsKey(key)) {
      Cell cell = sheet[key]!;
      if (cell.content is! ExpressionContent || cell.formulaType == null) {
        throw (FormatException('Invalid cell'));
      }
      _resultTypeCache[key] = cell.formulaType!.eval(this, visitedList);
    }
    return _resultTypeCache[key];
  }

  List<ResultType> removeAll(Set<A1>? keys) {
    final result = <ResultType>[];
    for (final key in keys ?? {}) {
      final resultType = _resultTypeCache.remove(key);
      if (resultType != null) result.add(resultType);
    }
    return result;
  }

  void clear() => _resultTypeCache.clear();

  Iterable<MapEntry<A1, ResultType>> get entries => _resultTypeCache.entries;

  @override
  Iterator<MapEntry<A1, ResultType>> get iterator => entries.iterator;

  bool containsKey(A1 key) => _resultTypeCache.containsKey(key);
  operator [](A1 key) => _resultTypeCache[key];
}
