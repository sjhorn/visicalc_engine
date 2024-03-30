import 'package:a1/a1.dart';

import 'list_type.dart';
import 'reference_type.dart';

class ListRangeType extends ListType {
  A1 get from => (list.first as ReferenceType).a1;
  A1 get to => (list.last as ReferenceType).a1;
  ListRangeType(A1 from, A1 to)
      : super(from.rangeTo(to).map((a1) => ReferenceType('$a1'.a1)).toList());

  factory ListRangeType.fromRefTypes(ReferenceType from, ReferenceType to) =>
      ListRangeType(from.a1, to.a1);

  @override
  String toString() => 'ListRangeType($from...$to)';

  bool get isRowLine => from.row == to.row;

  bool get isColumnLine => from.column == to.column;

  @override
  String get asFormula => '${list.first.asFormula}...${list.last.asFormula}';
}
