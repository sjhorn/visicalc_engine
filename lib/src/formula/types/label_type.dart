import '../../model/result_type_cache.dart';
import '../results/label_result.dart';
import '../results/result_type.dart';
import '../types/formula_type.dart';

class LabelType extends FormulaType {
  final String label;
  LabelType(this.label);

  @override
  ResultType eval(ResultTypeCache resultCache,
          [List<FormulaType>? visitedList]) =>
      LabelResult(label);

  @override
  String get asFormula => '"$label';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
  }
}
