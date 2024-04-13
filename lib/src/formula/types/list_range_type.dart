import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

class ListRangeType extends ListType {
  A1 _from; //A1 get from => (list.first as ReferenceType).a1;
  A1 _to; // A1 get to => (list.last as ReferenceType).a1;
  A1 get from => _from;
  A1 get to => _to;

  @override
  List<FormulaType> get list =>
      from.rangeTo(to).map((a1) => ReferenceType('$a1'.a1)).toList();

  ListRangeType(this._from, this._to) : super([]);

  factory ListRangeType.fromRefTypes(ReferenceType from, ReferenceType to) =>
      ListRangeType(from.a1, to.a1);

  @override
  String toString() => 'ListRangeType($from...$to)';

  bool get isRowLine => from.row == to.row;

  bool get isColumnLine => from.column == to.column;

  @override
  String get asFormula =>
      '$from...$to'; //'${list.first.asFormula}...${list.last.asFormula}';

  void moveFrom(A1 a1) => _from = a1;
  void moveTo(A1 a1) => _to = a1;
}
