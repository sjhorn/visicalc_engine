import 'package:intl/intl.dart';

import 'result_type.dart';

class NumberResult extends ResultType implements Comparable {
  static const double minExponent = 1.0e-6;
  static const double maxExponent = 1.0e21;
  final NumberFormat numFormat = NumberFormat('#.############');
  final num value;

  NumberResult(this.value);

  @override
  String toString() => switch (value.abs()) {
        num(isNaN: var nan, isInfinite: var infinite) when nan || infinite =>
          'ERROR',
        0 => '0',
        (>= minExponent && < maxExponent) => numFormat.format(value),
        _ => value.toStringAsExponential().length > 11
            ? value.toStringAsExponential(5)
            : value.toStringAsExponential(),
      };

  @override
  int compareTo(other) {
    if (other is! NumberResult) return -1;
    return value.compareTo(other.value);
  }

  bool operator <(NumberResult r) => compareTo(r) < 0;
  bool operator >(NumberResult r) => compareTo(r) > 0;

  NumberResult operator +(NumberResult r) => NumberResult(value + r.value);
  NumberResult operator /(num dividor) => NumberResult(value / dividor);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NumberResult && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
