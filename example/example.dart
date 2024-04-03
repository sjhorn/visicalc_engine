import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main(List<String> arguments) {
  final sheet = {
    'A1'.a1: '-12.2',
    'A2'.a1: '(a5+45)',
    'A3'.a1: '13',
    'A4'.a1: '+A2+A5-A6',
    'A5'.a1: '-A3/2+2',
    'A6'.a1: '.23*2',
    'B1'.a1: 'A1+A3*3',
    'B2'.a1: '(A1+A3)*3',
    'B3'.a1: '12.23e-12',
    'B4'.a1: '.23e12',
    'B5'.a1: 'b4',
    'B6'.a1: 'b2',
    'B7'.a1: '@sum(a1...b6)',
  };
  final worksheet = VisicalcEngine(sheet, parseErrorThrows: true);
  for (final a1 in worksheet) {
    print('$a1: ${worksheet[a1]}');
  }

  // Change cell
  var b5 = worksheet["B5".a1];
  print('B5 formula was ${b5?.formulaType?.asFormula} = $b5');
  print('Seeting to a1');
  worksheet['B5'.a1] = 'a1';
  print('Now B5 formula is ${b5?.formulaType?.asFormula} = $b5');
}
