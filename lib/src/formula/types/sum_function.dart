import 'package:visicalc_engine/visicalc_engine.dart';

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
