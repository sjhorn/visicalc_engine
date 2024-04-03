import 'package:visicalc_engine/visicalc_engine.dart';

class BracketsType extends FormulaType {
  FormulaType value;
  BracketsType(this.value);

  @override
  ResultType eval(ResultTypeCache resultCache,
      [List<FormulaType>? visitedList]) {
    visitedList ??= [];
    return value.eval(resultCache, [...visitedList, this]);
  }

  @override
  String toString() => 'BracketsType($value)';

  @override
  String get asFormula => '(${value.asFormula})';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    value.visit(callback);
  }
}
