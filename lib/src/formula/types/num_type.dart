import 'package:visicalc_engine/visicalc_engine.dart';

class NumType extends FormulaType {
  NumType(this.value);

  final num value;

  @override
  ResultType eval(ResultTypeCache resultCache,
          [List<FormulaType>? visitedList]) =>
      NumberResult(value);

  @override
  String toString() => 'Value{$value}';

  @override
  String get asFormula => '$value';

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NumType && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
