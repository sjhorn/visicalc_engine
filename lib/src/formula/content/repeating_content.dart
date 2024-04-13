import 'package:visicalc_engine/src/formula/content/cell_content.dart';

class RepeatingContent extends CellContent {
  final String pattern;
  RepeatingContent(this.pattern);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RepeatingContent && other.pattern == pattern;
  }

  @override
  int get hashCode => pattern.hashCode;

  @override
  String toString() => pattern;
}
