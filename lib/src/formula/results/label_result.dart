import 'package:visicalc_engine/visicalc_engine.dart';

class LabelResult extends ResultType {
  final String label;
  LabelResult(this.label);

  @override
  String toString() => label;
}
