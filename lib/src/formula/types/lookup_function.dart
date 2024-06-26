import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

class LookupFunction extends FormulaType {
  final FormulaType? params;
  bool _isDeleteReference = false;
  LookupFunction(this.params);

  @override
  ResultType eval(ResultTypeCache resultCache,
      [List<FormulaType>? visitedList]) {
    if (_isDeleteReference) {
      return ErrorResult();
    } else if (params is ListType && (params as ListType).list.isNotEmpty) {
      final paramList = (params as ListType).list;
      visitedList ??= [];
      final lookupNumber =
          paramList.first.eval(resultCache, [...visitedList, this]);
      if (lookupNumber is ErrorResult) return ErrorResult();
      final range = paramList[1];
      if (lookupNumber is NumberResult && range is ListRangeType) {
        if (range.isColumnLine || range.isRowLine) {
          A1? lastCell;
          for (A1 cell in range.from.rangeTo(range.to)) {
            final result =
                ReferenceType(cell).eval(resultCache, [...visitedList, this]);
            if (result is ErrorResult) return result;
            if (result is NumberResult && result == lookupNumber) {
              return ReferenceType(range.isColumnLine ? cell.right : cell.down)
                  .eval(resultCache, [...visitedList, this]);
            } else if (result is NumberResult && result > lookupNumber) {
              if (lastCell != null) {
                return ReferenceType(
                        range.isColumnLine ? lastCell.right : lastCell.down)
                    .eval(resultCache, [...visitedList, this]);
              } else {
                return NumberResult(0);
              }
            }
            lastCell = cell;
          }
        }
      }
    }
    return ErrorResult();
  }

  ListRangeType? get range => switch (params) {
        ListType(:var list) when list.length == 2 && list[1] is ListRangeType =>
          list[1] as ListRangeType,
        _ => null,
      };

  @override
  Set<A1> get references {
    Set<A1> rangeRefs = switch (range) {
      ListRangeType(:var isColumnLine) when isColumnLine =>
        range!.from.rangeTo(range!.to.right).toSet(),
      ListRangeType(:var isRowLine) when isRowLine =>
        range!.from.rangeTo(range!.to.down).toSet(),
      _ => {},
    };
    return {...rangeRefs, ...(lookup?.references ?? {})};
  }

  FormulaType? get lookup => switch (params) {
        ListType(:var list) when list.length == 2 => list.first,
        _ => null,
      };

  @override
  String get asFormula => '@LOOKUP(${params?.asFormula})';

  void markDeleted() {
    _isDeleteReference = true;
  }

  @override
  void visit(FormulaTypeVisitor callback) {
    callback(this);
    if (params != null) params!.visit(callback);
  }
}
