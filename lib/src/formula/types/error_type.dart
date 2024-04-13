import '../../model/result_type_cache.dart';
import '../results/error_result.dart';
import '../results/result_type.dart';
import 'formula_type.dart';

class ErrorType extends FormulaType {
  final String errorMessage;

  ErrorType([this.errorMessage = '']);

  @override
  ResultType eval(ResultTypeCache resultCache,
          [List<FormulaType>? visitedList]) =>
      ErrorResult();

  @override
  String get asFormula => '@ERROR';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
  }
}
