# VisiCalc Engine Package
[![Pub Package](https://img.shields.io/pub/v/visicalc_engine.svg)](https://pub.dev/packages/visicalc_engine)
[![Build Status](https://github.com/sjhorn/visicalc_engine/actions/workflows/dart.yml/badge.svg?branch=main)](https://github.com/sjhorn/visicalc_engine/actions)
[![codecov](https://codecov.io/gh/sjhorn/visicalc_engine/graph/badge.svg?token=78WVGR0OHY)](https://codecov.io/gh/sjhorn/visicalc_engine)
[![GitHub Issues](https://img.shields.io/github/issues/sjhorn/visicalc_engine.svg)](https://github.com/sjhorn/visicalc_engine/issues)
[![GitHub Forks](https://img.shields.io/github/forks/sjhorn/visicalc_engine.svg)](https://github.com/sjhorn/visicalc_engine/network)
[![GitHub Stars](https://img.shields.io/github/stars/sjhorn/visicalc_engine.svg)](https://github.com/sjhorn/visicalc_engine/stargazers)
![GitHub License](https://img.shields.io/github/license/sjhorn/visicalc_engine)

This package implements a clone of the VisiCalc spreadsheet engine in a dart library that works by parsing the strings of cells (Map<A1,String>) and calculating the result considering references to other cells.

The screenshot below shows the original user interface of Visicalc made by [Dan Bricklin and Bob Frankston](http://danbricklin.com/visicalc.htm).
![VisiCalc Logo from Wikipedia](https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Visicalc_logo.svg/320px-Visicalc_logo.svg.png)
![VisiCalc Spreadsheet User Interface](https://upload.wikimedia.org/wikipedia/commons/7/7a/Visicalc.png)

From [wikipedia](https://en.wikipedia.org/wiki/VisiCalc) 

> VisiCalc ("visible calculator") is the first spreadsheet computer program for personal computers, originally released for Apple II by VisiCorp on October 17, 1979.It is considered the killer application for the Apple II, turning the microcomputer from a hobby for computer enthusiasts into a serious business tool, and then prompting IBM to introduce the IBM PC two years later.More than 700,000 copies were sold in six years, and up to 1 million copies over its history


## Features

 - Supports the calculation and reference language from VisiCalc explained in the [reference card](http://www.bricklin.com/history/refcard1.htm)

 ![Reference Card](https://raw.github.com/sjhorn/visicalc_engine/main/assets/refcard.png)

## Getting started

Simple usage examples below:

```dart
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
```
The `test/` directory explores other use cases for the A1 types and library.

## Usage

The code above in getting started is also available in the `example/example.dart`

## Reference

* The [Visicalc user interface and logo](https://en.wikipedia.org/wiki/VisiCalc) are referenced from wikipeida.
* The parsing depends on the great library [petitparser](https://pub.dev/packages/petitparser) by Lukas Renggli.