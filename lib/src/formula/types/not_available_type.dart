import 'package:visicalc_engine/visicalc_engine.dart';

class NotAvailableType extends FormulaType {
  @override
  ResultType eval(ResultTypeCache resultCache,
          [List<FormulaType>? visitedList]) =>
      NotAvailableResult();

  @override
  String get asFormula => '@NA';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
  }
}
