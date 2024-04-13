import 'package:visicalc_engine/src/formula/content/cell_content.dart';

class GlobalDirectiveContent extends CellContent {
  final String directive;
  GlobalDirectiveContent(this.directive);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GlobalDirectiveContent && other.directive == directive;
  }

  @override
  int get hashCode => directive.hashCode;
}
