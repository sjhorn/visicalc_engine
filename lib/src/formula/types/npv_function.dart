import 'dart:math';

import '../result_cache_map.dart';
import '../results/error_result.dart';
import '../results/number_result.dart';
import '../results/result_type.dart';
import '../types/formula_type.dart';
import '../types/list_type.dart';

class NpvFunction extends FormulaType {
  final FormulaType? params;
  NpvFunction(this.params);

  @override
  ResultType eval(ResultCacheMap resultCache,
      [List<FormulaType>? visitedList]) {
    if (params is ListType && (params as ListType).list.isNotEmpty) {
      final paramList = (params as ListType).list;
      visitedList ??= [];
      final discountRate =
          paramList.first.eval(resultCache, [...visitedList, this]);
      if (discountRate is ErrorResult) {
        return discountRate;
      } else if (discountRate is NumberResult) {
        var accum = NumberResult(0);

        for (final (index, item)
            in flattenList(paramList.skip(1), resultCache, visitedList)
                .indexed) {
          if (item is ErrorResult) {
            return item;
          } else if (item is NumberResult) {
            accum += item / pow(1 + discountRate.value, index + 1);
          }
        }
        return accum;
      }
    }
    return ErrorResult();
  }

  Iterable<ResultType> flattenList(Iterable<FormulaType> formulaList,
      ResultCacheMap resultCache, List<FormulaType> visitedList) {
    return formulaList.fold<List<ResultType>>(
        [],
        (previousValue, element) => previousValue
          ..addAll(switch (element) {
            ListType(:var list) => flattenList(list, resultCache, visitedList),
            _ => [element.eval(resultCache)],
          }));
  }

  @override
  String get asFormula => '@NPV(${params?.asFormula})';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    if (params != null) params!.visit(callback);
  }
}
