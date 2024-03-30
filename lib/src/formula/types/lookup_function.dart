import 'package:a1/a1.dart';
import '../results/error_result.dart';
import '../types/error_type.dart';
import '../result_cache_map.dart';
import '../types/list_range_type.dart';
import '../types/reference_type.dart';

import '../results/number_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';
import 'list_type.dart';

class LookupFunction extends FormulaType {
  final FormulaType? params;
  LookupFunction(this.params);

  @override
  ResultType eval(ResultCacheMap resultCache,
      [List<FormulaType>? visitedList]) {
    if (params is ListType && (params as ListType).list.isNotEmpty) {
      final paramList = (params as ListType).list;
      visitedList ??= [];
      final lookupNumber =
          paramList.first.eval(resultCache, [...visitedList, this]);
      if (lookupNumber is ErrorResult) return ErrorResult();
      final range = paramList[1];
      if (lookupNumber is NumberResult && range is ListRangeType) {
        if (range.list.whereType<ErrorType>().isNotEmpty) {
          return ErrorResult();
        }
        if (range.isColumnLine || range.isRowLine) {
          A1? lastCell;
          for (A1 cell in range.from.rangeTo(range.to)) {
            final result =
                ReferenceType(cell).eval(resultCache, [...visitedList, this]);
            if (result is ErrorResult) return result;
            if (result is NumberResult && result == lookupNumber) {
              return ReferenceType(range.isColumnLine ? cell.right : cell.down)
                  .eval(resultCache, [...visitedList, this]);
            } else if (result is NumberResult && result > lookupNumber) {
              if (lastCell != null) {
                return ReferenceType(
                        range.isColumnLine ? lastCell.right : lastCell.down)
                    .eval(resultCache, [...visitedList, this]);
              } else {
                return NumberResult(0);
              }
            }
            lastCell = cell;
          }
        }
      }
    }
    return ErrorResult();
  }

  ListRangeType? get range => switch (params) {
        ListType(:var list) when list.length == 2 && list[1] is ListRangeType =>
          list[1] as ListRangeType,
        _ => null,
      };

  List<A1> get dependencies => switch (range) {
        ListRangeType(:var isColumnLine) when isColumnLine =>
          range!.from.right.rangeTo(range!.to.right),
        ListRangeType(:var isRowLine) when isRowLine =>
          range!.from.down.rangeTo(range!.to.down),
        _ => [],
      };

  @override
  String get asFormula => '@LOOKUP(${params?.asFormula})';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    if (params != null) params!.visit(callback);
  }
}
