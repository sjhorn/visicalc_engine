import 'package:visicalc_engine/visicalc_engine.dart';

class LabelResult extends ResultType {
  final String label;
  LabelResult(this.label);

  @override
  String toString() => label;
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LabelResult && other.label == label;
  }

  @override
  int get hashCode => label.hashCode;
}
