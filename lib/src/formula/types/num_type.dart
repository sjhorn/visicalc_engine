import 'package:intl/intl.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

class NumType extends FormulaType {
  static const double minExponent = 1.0e-6;
  static const double maxExponent = 1.0e21;
  final NumberFormat numFormat = NumberFormat('#.############');

  NumType(this.value);

  final num value;

  @override
  ResultType eval(ResultTypeCache resultCache,
          [List<FormulaType>? visitedList]) =>
      NumberResult(value);

  @override
  String toString() => 'Value{$value}';

  String get _numString => switch (value.abs()) {
        num(isNaN: var nan, isInfinite: var infinite) when nan || infinite =>
          'ERROR',
        0 => '0',
        (>= minExponent && < maxExponent) => numFormat.format(value),
        _ => value.toStringAsExponential().length > 11
            ? value.toStringAsExponential(5)
            : value.toStringAsExponential(),
      };

  @override
  String get asFormula => _numString;

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
