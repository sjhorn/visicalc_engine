import '../results/number_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';
import 'list_function.dart';

class CountFunction extends ListFunction {
  CountFunction(super.value);

  @override
  ResultType evalList(List<ResultType> resultList) =>
      NumberResult(resultList.whereType<NumberResult>().length);

  @override
  String get asFormula => '@COUNT(${value.asFormula})';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    value.visit(callback);
  }
}
