import 'package:visicalc_engine/visicalc_engine.dart';

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
