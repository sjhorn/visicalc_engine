# VisiCalc Engine Package
[![Pub Package](https://img.shields.io/pub/v/visicalc_engine.svg)](https://pub.dev/packages/visicalc_engine)
[![Build Status](https://github.com/sjhorn/visicalc_engine/actions/workflows/dart.yml/badge.svg?branch=main)](https://github.com/sjhorn/visicalc_engine/actions)
[![codecov](https://codecov.io/gh/sjhorn/visicalc_engine/graph/badge.svg?token=78WVGR0OHY)](https://codecov.io/gh/sjhorn/visicalc_engine)
[![GitHub Issues](https://img.shields.io/github/issues/sjhorn/visicalc_engine.svg)](https://github.com/sjhorn/visicalc_engine/issues)
[![GitHub Forks](https://img.shields.io/github/forks/sjhorn/visicalc_engine.svg)](https://github.com/sjhorn/visicalc_engine/network)
[![GitHub Stars](https://img.shields.io/github/stars/sjhorn/visicalc_engine.svg)](https://github.com/sjhorn/visicalc_engine/stargazers)
![GitHub License](https://img.shields.io/github/license/sjhorn/visicalc_engine)

This package implements a clone of the VisiCalc spreadsheet engine in a dart library that works by parsing the strings of cells (Map<A1,String>) and calculating the result considering references to other cells.

The screenshot below shows the original user interface of Visicalc made by [Dan Bricklin and Bob Frankston](https://danbricklin.com/visicalc.htm).
![VisiCalc Logo from Wikipedia](https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Visicalc_logo.svg/320px-Visicalc_logo.svg.png)
![VisiCalc Spreadsheet User Interface](https://upload.wikimedia.org/wikipedia/commons/7/7a/Visicalc.png)

From [wikipedia](https://en.wikipedia.org/wiki/VisiCalc) 

> VisiCalc ("visible calculator") is the first spreadsheet computer program for personal computers, originally released for Apple II by VisiCorp on October 17, 1979.It is considered the killer application for the Apple II, turning the microcomputer from a hobby for computer enthusiasts into a serious business tool, and then prompting IBM to introduce the IBM PC two years later.More than 700,000 copies were sold in six years, and up to 1 million copies over its history


## Features

 - Supports the calculation and reference language from VisiCalc explained in the [reference card](https://www.bricklin.com/history/refcard1.htm)

 ![Reference Card](https://raw.github.com/sjhorn/visicalc_engine/main/assets/refcard.png)

## Getting started

Simple usage examples below:

```dart
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
  final worksheet = Engine(sheet, parseErrorThrows: true);
  print(worksheet);

  // Change cell
  var b5 = worksheet["B5".a1];
  print('B5 formula was ${b5?.formulaType?.asFormula} = $b5');
  print('Now setting B5 to formula a1');
  worksheet['B5'.a1] = '+a1';

  b5 = worksheet["B5".a1];
  print('Now B5 formula is ${b5?.formulaType?.asFormula} = $b5');
  print(worksheet);

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
```

The result looks as follows:
```
          A fx           |          A           |       B fx           |          B           |       C fx           |          C           |       D fx           |          D           | 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 1  -12.2                |                -12.2 | +A1+A3*3             | 26.8                 |                      |                      |                      |                      | 
 2  (A5+45)              | 40.5                 | (A1+A3)*3            | 2.4                  |                      |                      |                      |                      | 
 3  13                   | ********             | 1.223e-11            | 1.223e-11            |                      |                      |                      |                      | 
 4  +A2+A5-A6            | 35.54                | 230000000000         | 230000000000         |                      |                      |                      |                      | 
 5  -A3/2+2              | -4.5                 | B4                   |         230000000000 |                      |                      |                      |                      | 
 6  0.23*2               | 0.46                 | +B2                  | 2.4                  |                      |                      |                      |                      | 
 7                       |                      | @SUM(A1...B6)        | 460000000104.4000244 |                      |                      |                      |                      | 
 8                       |                      |                      |                      |                      |                      |                      |                      | 
 9                       |                      |                      |                      |                      |                      |                      |                      | 
10                       |                      |                      |                      |                      |                      |                      |                      | 
11                       |                      |                      |                      |                      |                      |                      |                      | 
12                       |                      |                      |                      |                      |                      |                      |                      | 
13                       |                      |                      |                      |                      |                      | +B2                  | 2.4                  | 

B5 formula was B4 = 230000000000
Now setting B5 to formula a1
Now B5 formula is +A1 = -12.2
          A fx           |          A           |       B fx           |          B           |       C fx           |          C           |       D fx           |          D           | 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 1  -12.2                |                -12.2 | +A1+A3*3             | 26.8                 |                      |                      |                      |                      | 
 2  (A5+45)              | 40.5                 | (A1+A3)*3            | 2.4                  |                      |                      |                      |                      | 
 3  13                   | ********             | 1.223e-11            | 1.223e-11            |                      |                      |                      |                      | 
 4  +A2+A5-A6            | 35.54                | 230000000000         | 230000000000         |                      |                      |                      |                      | 
 5  -A3/2+2              | -4.5                 | +A1                  | -12.2                |                      |                      |                      |                      | 
 6  0.23*2               | 0.46                 | +B2                  | 2.4                  |                      |                      |                      |                      | 
 7                       |                      | @SUM(A1...B6)        | 230000000092.1999816 |                      |                      |                      |                      | 
 8                       |                      |                      |                      |                      |                      |                      |                      | 
 9                       |                      |                      |                      |                      |                      |                      |                      | 
10                       |                      |                      |                      |                      |                      |                      |                      | 
11                       |                      |                      |                      |                      |                      |                      |                      | 
12                       |                      |                      |                      |                      |                      |                      |                      | 
13                       |                      |                      |                      |                      |                      | +B2                  | 2.4                  | 

Parsing an example of a VisiCalc .vc file format
          A fx           |          A           |       B fx           |          B           | 
-----------------------------------------------------------------------------------------------
 1  "TRUE                | TRUE                 | "label               |                label | 
 2  +B5*10               | 4.6                  | 123                  | 123                  | 
 3  +B3+1                | 4.1415926536         | @PI                  | 3.1415926536         | 
 4  "tes                 | tes                  | +B3                  | 3.1415926536         | 
 5  @SUM(B2...B5)        | 129.7431853072       | 0.23*2               | 0.46                 | 
```


The `test/` directory explores other use cases for the A1 types and library.

## Usage

The code above in getting started is also available in the `example/example.dart`

## Reference

* The [Visicalc user interface and logo](https://en.wikipedia.org/wiki/VisiCalc) are referenced from wikipeida.
* The parsing depends on the great library [petitparser](https://pub.dev/packages/petitparser) by Lukas Renggli.