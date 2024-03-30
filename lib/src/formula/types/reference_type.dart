import 'package:a1/a1.dart';
import '../results/error_result.dart';

import '../result_cache_map.dart';

import '../results/empty_result.dart';
import '../results/not_available_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';

class ReferenceType extends FormulaType {
  ReferenceType(this._a1);

  factory ReferenceType.fromA1String(String a1String) =>
      ReferenceType(a1String.a1);
  A1 _a1;
  A1 get a1 => _a1;
  bool _deletedReference = false;

  @override
  ResultType eval(ResultCacheMap resultCache,
      [List<FormulaType>? visitedList]) {
    visitedList ??= [];
    if (_deletedReference) {
      return ErrorResult();
    } else if (visitedList.contains(this)) {
      // check for circular reference otherwise descend
      return NotAvailableResult('Circular reference in $a1');
    } else {
      //return resultCache[a1] ?? EmptyResult();
      return resultCache.evalAndCache(a1, [...visitedList, this]) ??
          EmptyResult();
    }
  }

  void move(int columnIncrement, int rowIncrement) {
    _a1 = A1.fromVector(_a1.column + columnIncrement, _a1.row + rowIncrement);
  }

  @override
  String toString() => 'ReferenceType{$a1}';

  @override
  String get asFormula => _deletedReference ? '@ERROR' : '$a1';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReferenceType && other.a1 == a1;
  }

  @override
  int get hashCode => a1.hashCode;

  void markDeleted() {
    _deletedReference = true;
  }

  bool get isDeleted => _deletedReference;
}
