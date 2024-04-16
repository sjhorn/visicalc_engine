import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main(List<String> arguments) {
  final sheet = {
    'A1'.a1: '/FR-12.2',
    'A2'.a1: '(a5+45)',
    'A3'.a1: '/F*13',
    'A4'.a1: '+A2+A5-A6',
    'A5'.a1: '-A3/2+2',
    'A6'.a1: '/F\$.23*2',
    'B1'.a1: '+A1+A3*3',
    'B2'.a1: '(A1+A3)*3',
    'B3'.a1: '12.23e-12',
    'B4'.a1: '.23e12',
    'B5'.a1: '/FRb4',
    'B6'.a1: '+b2',
    'B7'.a1: '@sum(a1...b6)',
    'D13'.a1: '+b2',
  };
  final worksheet = Engine.fromMap(sheet, parseErrorThrows: true);
  print(worksheet);

  // Change cell
  var b5 = worksheet["B5".a1];
  print('B5 formula was ${b5?.formulaType?.asFormula} = $b5');
  print('Now setting B5 to formula a1');
  worksheet['B5'.a1] = '+a1';

  b5 = worksheet["B5".a1];
  print('Now B5 formula is ${b5?.formulaType?.asFormula} = $b5');
  print(worksheet);
  print('Output to a .vc file\n: ${worksheet.toFileContents()}');

  // .vc file example
  final fileContents = '''\
>A1:/FL"TRUE\r
>A2:+B5*10\r
>A3:+B3+1\r
>A4:"tes\r
>A5:@SUM(B2...B5)\r
>B1:/FR"label\r
>B2:123\r
>B3:@PI\r
>B4:+B3\r
>B5:.23*2\r
\u0000''';
  print('Parsing an example of a VisiCalc .vc file format');
  final engine = Engine.fromFileContents(fileContents);
  print(engine);
}
