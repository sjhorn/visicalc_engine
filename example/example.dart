import 'package:petitparser/petitparser.dart';
import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main(List<String> arguments) {
  final rows = {
    'A1'.a1: '-12.2',
    'A2'.a1: '(a5 + 45)',
    'A3'.a1: '13',
    'A4'.a1: '+A2 + A5 - A6',
    'A5'.a1: '-A3 / 2 + 2 ',
    'A6'.a1: '.23 * 2',
    'B1'.a1: 'A1 + A3 * 3',
    'B2'.a1: '(A1 + A3) * 3',
    'B3'.a1: '12.23e-12',
    'B4'.a1: '.23e12',
    'B5'.a1: 'b4',
    'B6'.a1: 'b2',
    'B7'.a1: '@sum(a1...b6)' // 1 + 1 + 28
  };

  final evaluator = Evaluator();
  final parser = evaluator.build();

  final Map<A1, FormulaType> varMap = <A1, FormulaType>{};
  for (final MapEntry(:key, :value) in rows.entries) {
    final ast = parser.parse(value);

    if (ast is Success) {
      varMap[key] = ast.value;
    }
  }
  for (final MapEntry(:key, :value) in varMap.entries) {
    final evalResult = value.eval(ResultCacheMap(varMap));
    print('$key -> ${evalResult.runtimeType} -> $evalResult');
  }
}
