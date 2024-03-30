# VisiCalc Engine Package
[![Pub Package](https://img.shields.io/pub/v/visicalc_engine.svg)](https://pub.dev/packages/visicalc_engine)
[![Build Status](https://github.com/sjhorn/visicalc_engine/actions/workflows/dart.yml/badge.svg?branch=main)](https://github.com/sjhorn/visicalc_engine/actions)
[![codecov](https://codecov.io/gh/sjhorn/visicalc_engine/graph/badge.svg?token=O8MCNXGB6A)](https://codecov.io/gh/sjhorn/visicalc_engine)
[![GitHub Issues](https://img.shields.io/github/issues/sjhorn/visicalc_engine.svg)](https://github.com/sjhorn/visicalc_engine/issues)
[![GitHub Forks](https://img.shields.io/github/forks/sjhorn/visicalc_engine.svg)](https://github.com/sjhorn/visicalc_engine/network)
[![GitHub Stars](https://img.shields.io/github/stars/sjhorn/visicalc_engine.svg)](https://github.com/sjhorn/visicalc_engine/stargazers)
![GitHub License](https://img.shields.io/github/license/sjhorn/visicalc_engine)

This package implements a clone of the VisiCalc engine in a dart library that works by parsing the string of cell and calculating the result considering references to other cells.

The screenshot below shows the original user interface of Visicalc made by [Dan Bricklin and Bob Frankston](http://danbricklin.com/visicalc.htm).
![VisiCalc Logo from Wikipedia](https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Visicalc_logo.svg/320px-Visicalc_logo.svg.png)
![VisiCalc Spreadsheet User Interface](https://upload.wikimedia.org/wikipedia/commons/7/7a/Visicalc.png)

From [wikipedia](https://en.wikipedia.org/wiki/VisiCalc) 

> VisiCalc ("visible calculator") is the first spreadsheet computer program for personal computers, originally released for Apple II by VisiCorp on October 17, 1979.It is considered the killer application for the Apple II, turning the microcomputer from a hobby for computer enthusiasts into a serious business tool, and then prompting IBM to introduce the IBM PC two years later.More than 700,000 copies were sold in six years, and up to 1 million copies over its history


## Features

 - 

## Getting started

Simple usage examples below:

```dart
 

```
The `test/` directory explores other use cases for the A1 types and library.

## Usage

The code above in getting started is also available in the `example/example.dart`

## Reference

* The [Visicalc user interface and logo](https://en.wikipedia.org/wiki/VisiCalc) are referenced from wikipeida.
* The parsing depends on the great library [petitparser](https://pub.dev/packages/petitparser) by Lukas Renggli.