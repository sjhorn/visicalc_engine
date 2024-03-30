import 'dart:math';

import '../result_cache_map.dart';

import '../results/error_result.dart';
import '../results/number_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';

class MathsFunction extends FormulaType {
  final String name;
  final FormulaType? params;

  MathsFunction(this.name, this.params);

  @override
  ResultType eval(ResultCacheMap resultCache,
      [List<FormulaType>? visitedList]) {
    visitedList ??= [];
    final result = params?.eval(resultCache, [...visitedList, this]);
    //print(result);
    if (result is NumberResult) {
      return switch (name) {
        '@abs(' => NumberResult(result.value.abs()),
        '@int(' => NumberResult(result.value.toInt()),
        '@exp(' => NumberResult(exp(result.value)),
        '@sqrt(' => NumberResult(sqrt(result.value)),
        '@ln(' => NumberResult(log(result.value)),
        '@log10(' => NumberResult(log(result.value) / ln10),
        '@sin(' => NumberResult(sin(result.value)),
        '@asin(' => NumberResult(asin(result.value)),
        '@cos(' => NumberResult(cos(result.value)),
        '@acos(' => NumberResult(acos(result.value)),
        '@tan(' => NumberResult(tan(result.value)),
        '@atan(' => NumberResult(atan(result.value)),
        _ => ErrorResult(),
      };
    }
    return ErrorResult();
  }

  @override
  String get asFormula => '${name.toUpperCase()}${params?.asFormula ?? ""})';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    if (params != null) params!.visit(callback);
  }
}
