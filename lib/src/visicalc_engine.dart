import 'dart:collection';

import 'package:a1/a1.dart';
import 'package:petitparser/petitparser.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

enum CellChangeType { add, update, delete }

typedef CellChangedCallback = void Function(A1 a1, CellChangeType changeType);

class VisicalcEngine with Iterable<A1> {
  static final evaluator = Evaluator().build();
  static final validator = ValidateExpression().build();

  final HashSet<CellChangedCallback> _listeners =
      HashSet<CellChangedCallback>();
  late final Map<A1, FormulaType> _formulaTypeMap;
  late final ResultTypeCache _resultTypeCache;
  late final CellDependencyTracker _tracker;
  final bool parseErrorThrows;

  VisicalcEngine(Map<A1, String> sheet, {this.parseErrorThrows = false}) {
    _formulaTypeMap = _parseSheet(sheet);
    _resultTypeCache = ResultTypeCache(_formulaTypeMap);
    _tracker = CellDependencyTracker();
  }

  Map<A1, FormulaType> _parseSheet(Map<A1, String> sheet) {
    final Map<A1, FormulaType> varMap = <A1, FormulaType>{};
    for (final MapEntry(:key, :value) in sheet.entries) {
      varMap[key] = _parse(value);
    }
    return varMap;
  }

  FormulaType _parse(String cell) {
    final ast = evaluator.parse(cell);
    if (ast is Success) {
      return ast.value;
    } else {
      final failure = ast as Failure;
      if (parseErrorThrows) {
        throw FormatException('Error parsing [$cell]] - ${failure.message}');
      }
      return ErrorType();
    }
  }

  //
  // Map/list like Methods
  //

  /// Lazily eval and cache
  CellValue? operator [](A1 a1) {
    if (_formulaTypeMap.containsKey(a1)) {
      return CellValue(
        () => _formulaTypeMap[a1],
        () => _formulaTypeMap[a1]!.eval(_resultTypeCache),
      );
    }
    return null;
  }

  /// Attempt to parse cell
  void operator []=(A1 key, String cell) {
    if (_formulaTypeMap.containsKey(key)) {
      _tracker.removeDependants(key, _formulaTypeMap[key]!.dependants);
      _resultTypeCache.remove(key);

      // notify of delete
      _notifyListeners(key, CellChangeType.delete);
    }
    final formulaType = _parse(cell);
    _formulaTypeMap[key] = formulaType;
    _tracker.addDependants(key, formulaType.dependants);

    // notify of add
    _notifyListeners(key, CellChangeType.add);
  }

  void clear() {
    final a1List = keys.toList();
    _tracker.clear();
    _formulaTypeMap.clear();
    _resultTypeCache.clear();

    // notify of all keys deleted
    for (final a1 in a1List) {
      _notifyListeners(a1, CellChangeType.delete);
    }
  }

  Iterable<A1> get keys => _formulaTypeMap.keys;

  move(A1 from, A1 to) {}

  CellValue? remove(A1 a1) {
    if (_formulaTypeMap.containsKey(a1)) {
      _tracker.removeDependants(a1, _formulaTypeMap[a1]!.dependants);
      final removed = CellValue(
        () => _formulaTypeMap.remove(a1),
        () => _resultTypeCache.remove(a1),
      );

      // notify of delete
      _notifyListeners(a1, CellChangeType.delete);
      return removed;
    }
    return null;
  }

  // Iterable
  @override
  Iterator<A1> get iterator => keys.iterator;

  // Listeners
  void addListener(CellChangedCallback listener) => _listeners.add(listener);
  void removeListener(CellChangedCallback listener) =>
      _listeners.remove(listener);

  void _notifyListeners(A1 a1, CellChangeType changeType) {
    for (final listener in _listeners) {
      listener(a1, changeType);
    }
    _notifyDependencies(a1, CellChangeType.update);
  }

  void _notifyDependencies(A1 a1, CellChangeType changeType) {
    for (final listener in _listeners) {
      for (A1 dependency in _tracker[a1] ?? []) {
        listener(dependency, changeType);
      }
    }
  }
}
