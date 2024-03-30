import 'package:a1/a1.dart';
import '../result_cache_map.dart';
import '../results/list_result.dart';
import '../results/not_available_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';
import 'reference_type.dart';

class ListType extends FormulaType {
  final List<FormulaType> list;
  ListType(this.list);

  factory ListType.fromA1List(List<A1> list) {
    return ListType(list.map((a1) => ReferenceType('$a1'.a1)).toList());
  }

  @override
  ResultType eval(ResultCacheMap resultCache,
      [List<FormulaType>? visitedList]) {
    visitedList ??= [];
    if (visitedList.contains(this)) {
      return NotAvailableResult('Circular reference in $list');
    }

    return ListResult.fromIterable(
        list.map((e) => e.eval(resultCache, [...visitedList!, this])));
  }

  @override
  String toString() => 'ListType($list)';

  @override
  String get asFormula => list.map((e) => e.asFormula).join(",");

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    for (var e in list) {
      e.visit(callback);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is ListType) {
      for (final (index, item) in other.list.indexed) {
        if (list[index] != item) return false;
      }
      return true;
    }
    return false;
  }

  @override
  int get hashCode => list.fold(
      0, (previousValue, element) => previousValue ^ element.hashCode);
}
