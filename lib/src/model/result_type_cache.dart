import 'package:a1/a1.dart';

import 'package:visicalc_engine/visicalc_engine.dart';

typedef EvalCallback = ResultType Function(A1 cell, ResultTypeCache map);

class ResultTypeCache extends Iterable<MapEntry<A1, ResultType>> {
  final Map<A1, FormulaType> sheet;
  final Map<A1, ResultType> _resultTypeCache = {};

  final List<Function()> listeners = [];
  ResultTypeCache(this.sheet);

  ResultType? evalAndCache(A1 key, List<FormulaType> visitedList) {
    if (!_resultTypeCache.containsKey(key) && sheet.containsKey(key)) {
      _resultTypeCache[key] = sheet[key]!.eval(this, visitedList);
    }
    return _resultTypeCache[key];
  }

  ResultType? remove(Object? key) {
    final result = _resultTypeCache.remove(key);
    return result;
  }

  void clear() => _resultTypeCache.clear();

  Iterable<MapEntry<A1, ResultType>> get entries => _resultTypeCache.entries;

  @override
  Iterator<MapEntry<A1, ResultType>> get iterator => entries.iterator;

  bool containsKey(A1 key) => _resultTypeCache.containsKey(key);
  operator [](A1 key) => _resultTypeCache[key];
}
