import 'package:visicalc_engine/visicalc_engine.dart';

class CellValue {
  final FormulaType? Function() formulaTypeGetter;
  final ResultType? Function() resultTypeGetter;
  FormulaType? get formulaType => formulaTypeGetter();
  ResultType? get resultType => resultTypeGetter();

  CellValue(this.formulaTypeGetter, this.resultTypeGetter);

  @override
  String toString() => resultType?.toString() ?? 'null';
}
