import '../results/number_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';
import 'list_function.dart';

class SumFunction extends ListFunction {
  SumFunction(super.value);

  @override
  ResultType evalList(List<ResultType> resultList) => [
        ...resultList.whereType<NumberResult>(),
        NumberResult(0)
      ].reduce((sum, e) => sum + e);

  @override
  String get asFormula => '@SUM(${value.asFormula})';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    value.visit(callback);
  }
}
