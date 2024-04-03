import 'package:visicalc_engine/visicalc_engine.dart';

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
