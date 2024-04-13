import 'package:visicalc_engine/src/formula/content/cell_content.dart';

class LabelContent extends CellContent {
  final String label;
  LabelContent(this.label);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LabelContent && other.label == label;
  }

  @override
  int get hashCode => label.hashCode;
}
