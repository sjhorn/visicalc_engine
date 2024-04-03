import '../results/error_result.dart';
import '../types/reference_type.dart';

import '../../model/result_type_cache.dart';
import '../results/list_result.dart';
import '../results/result_type.dart';
import 'error_type.dart';
import 'formula_type.dart';
import 'list_type.dart';

abstract class ListFunction extends FormulaType {
  final FormulaType value;
  ListFunction(this.value);

  ResultType evalList(List<ResultType> resultList);

  @override
  ResultType eval(ResultTypeCache resultCache,
      [List<FormulaType>? visitedList]) {
    visitedList ??= [];
    switch (value) {
      case ListType(:var list):
        // Chech for errortype or deleted ref
        if (list.whereType<ErrorType>().isNotEmpty ||
            list
                .whereType<ReferenceType>()
                .where((element) => element.isDeleted)
                .isNotEmpty) {
          return ErrorResult();
        }
        final results = value.eval(resultCache, [...visitedList, this]);
        if (results is ListResult) {
          if (results.list.whereType<ErrorResult>().isNotEmpty) {
            return ErrorResult();
          }
          return evalList(results.list);
        } else {
          return results;
        }
      default:
        return value.eval(resultCache, visitedList);
    }
  }
}
