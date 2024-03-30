import '../results/number_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';
import 'list_function.dart';

class MaxFunction extends ListFunction {
  MaxFunction(super.value);

  @override
  ResultType evalList(List<ResultType> resultList) {
    final numberList = resultList.whereType<NumberResult>();
    if (numberList.isEmpty) {
      return NumberResult(0);
    }
    return numberList.reduce((max, element) => element > max ? element : max);
  }

  @override
  String get asFormula => '@MAX(${value.asFormula})';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    value.visit(callback);
  }
}
