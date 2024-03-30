import 'result_type.dart';

class LabelResult extends ResultType {
  final String label;
  LabelResult(this.label);

  @override
  String toString() => label;
}
