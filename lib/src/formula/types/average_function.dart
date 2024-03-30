import 'formula_type.dart';
import 'sum_function.dart';

import '../results/number_result.dart';
import '../results/result_type.dart';

class AverageFunction extends SumFunction {
  AverageFunction(super.value);

  @override
  ResultType evalList(List<ResultType> resultList) =>
      (super.evalList(resultList) as NumberResult) /
      resultList.whereType<NumberResult>().length;

  @override
  String get asFormula => '@AVERAGE(${value.asFormula})';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    value.visit(callback);
  }
}
