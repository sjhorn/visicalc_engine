import 'package:visicalc_engine/visicalc_engine.dart';

class MinFunction extends ListFunction {
  MinFunction(super.value);

  @override
  ResultType evalList(List<ResultType> resultList) {
    final numberList = resultList.whereType<NumberResult>();
    if (numberList.isEmpty) {
      return NumberResult(0);
    }
    return numberList.reduce((min, element) => element < min ? element : min);
  }

  @override
  String get asFormula => '@MIN(${value.asFormula})';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    value.visit(callback);
  }
}
