import 'package:visicalc_engine/visicalc_engine.dart';

class PiType extends FormulaType {
  @override
  ResultType eval(ResultTypeCache resultCache,
          [List<FormulaType>? visitedList]) =>
      NumberResult(3.1415926536);

  @override
  String get asFormula => '@PI';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
  }
}
