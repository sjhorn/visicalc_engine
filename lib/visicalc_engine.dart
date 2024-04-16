/// VisiCalc Engine
///
/// This dart library aims to emulate the behaviour of the VisiCalc
/// spreadsheet, including cell operations (move,copy, etc.), cell references
/// and functions.
///
/// The engine also allows reading in a spreadsheet either from a
/// [Map<A1,String>] or directly from the file format used by the original
/// app typically saved as .vc files.
///
/// The engine relies heavily on the
/// [PetitParser](https://pub.dev/packages/petitparser) and
/// [A1 Notation libraries](https://pub.dev/packages/a1).
///
/// **See also:**
/// * [VisiCalc on Wikipedia](https://en.wikipedia.org/wiki/Spreadsheet#)
/// * [Dan Bricklin page on VisiCalc](http://danbricklin.com/visicalc.htm)

library;

export 'src/formula/grammar/format_expression.dart';
export 'src/model/cell_change_type.dart';
export 'src/formula/grammar/expression.dart';
export 'src/formula/grammar/evaluator.dart';
export 'src/formula/grammar/file_format.dart';
export 'src/formula/grammar/validate_expression.dart';
export 'src/formula/results/empty_result.dart';
export 'src/formula/results/error_result.dart';
export 'src/formula/results/label_result.dart';
export 'src/formula/results/list_result.dart';
export 'src/formula/results/not_available_result.dart';
export 'src/formula/results/number_result.dart';
export 'src/formula/results/result_type.dart';
export 'src/formula/types/average_function.dart';
export 'src/formula/types/binary_num_op.dart';
export 'src/formula/types/brackets_type.dart';
export 'src/formula/types/count_function.dart';
export 'src/formula/types/error_type.dart';
export 'src/formula/types/formula_type.dart';
export 'src/formula/types/label_type.dart';
export 'src/formula/types/list_function.dart';
export 'src/formula/types/list_range_type.dart';
export 'src/formula/types/list_type.dart';
export 'src/formula/types/lookup_function.dart';
export 'src/formula/types/maths_function.dart';
export 'src/formula/types/max_function.dart';
export 'src/formula/types/min_function.dart';
export 'src/formula/types/negative_op.dart';
export 'src/formula/types/not_available_type.dart';
export 'src/formula/types/npv_function.dart';
export 'src/formula/types/num_type.dart';
export 'src/formula/types/pi_type.dart';
export 'src/formula/types/positive_op.dart';
export 'src/formula/types/reference_type.dart';
export 'src/formula/types/sum_function.dart';
export 'src/model/cell_reference_tracker.dart';
export 'src/model/cell.dart';
export 'src/model/result_type_cache.dart';
export 'src/formula/content/expression_content.dart';
export 'src/formula/content/global_directive_content.dart';
export 'src/formula/content/repeating_content.dart';
export 'src/formula/content/cell_content.dart';
export 'src/model/cell_format.dart';
export 'src/engine.dart';
