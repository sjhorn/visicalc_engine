// Copyright (c) 2024, Scott Horn.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'package:visicalc_engine/visicalc_engine.dart';

/// Cell class holds all the details for a cell in a spreadsheet
///
/// This includesl the [CellContent] content which could be a Expression
/// [ExpressionContent] or Repeating Character eg. ==== [RepeatingContent]
///
class Cell {
  /// [CellContent] for this cell
  final CellContent? content;

  /// [CellFormat] for this cell
  late final CellFormat format;

  ResultTypeCache? Function()? resultTypeCacheFunc;
  ResultTypeCache? get resultTypeCache => resultTypeCacheFunc?.call();

  FormulaType? _formulaType;

  /// Construct a cell from its content [CellContent], options format [CellFormat]
  /// and function for retrieive the [ResultTypeCache]
  Cell({this.content, CellFormat? format, this.resultTypeCacheFunc}) {
    this.format = format ?? CellFormat.defaultFormat;
  }

  /// Create a cell directly from a [FormulaType]
  factory Cell.fromFormulaType(FormulaType formulaType) =>
      Cell(content: ExpressionContent(formulaType));

  FormulaType? get formulaType {
    _formulaType ??= switch (content) {
      ExpressionContent(:var formulaType) => formulaType,
      _ => null,
    };
    return _formulaType;
  }

  ResultType? get resultType => switch (content) {
        ExpressionContent(:var formulaType) => resultTypeCache == null
            ? formulaType.eval(ResultTypeCache({}))
            : formulaType.eval(resultTypeCache!),
        _ => null,
      };

  String get contentString => switch (content) {
        ExpressionContent() => formulaType?.asFormula ?? '',
        GlobalDirectiveContent(:var directive) => directive,
        RepeatingContent(:var pattern) => pattern,
        _ => '',
      };

  String get resultString => resultType == null ? '' : resultType.toString();

  String formattedString([int columnWidth = 20, CellFormat? formatApplied]) {
    formatApplied ??= format;

    return switch ((content, formatApplied)) {
      (ExpressionContent(), _) => switch (format) {
          CellFormat.general ||
          CellFormat.left =>
            _cellStringLeft(resultString, columnWidth),
          CellFormat.right => _cellStringRight(resultString, columnWidth),
          CellFormat.dollars => resultType!.dollarFormat(columnWidth),
          CellFormat.graph => resultType!.graphFormat(columnWidth),
          CellFormat.integer => resultType!.integer(columnWidth),
        },
      (RepeatingContent(:var pattern), _) => ''.padLeft(columnWidth, pattern),
      _ => contentString
          .substring(0, min(contentString.length, columnWidth))
          .padRight(columnWidth),
    };
  }

  String _cellStringLeft(String content, int width) =>
      content.substring(0, min(content.length, width)).padRight(width);

  String _cellStringRight(String content, int width) =>
      content.substring(0, min(content.length, width)).padLeft(width);

  @override
  String toString() => resultString;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Cell &&
        other.content == content &&
        other.format == format &&
        other.resultTypeCache == resultTypeCache;
  }

  @override
  int get hashCode {
    return content.hashCode ^ format.hashCode ^ resultTypeCache.hashCode;
  }
}

extension on ResultType {
  static String _columnPad(int columnWidth, String content) => content
      .substring(0, min(content.length, columnWidth))
      .padRight(columnWidth);

  String dollarFormat(int columnWidth) {
    if (this is NumberResult) {
      final value = (this as NumberResult).value;
      final dollars = value.floor();
      final cents =
          ((value - dollars) * 100).round().toString().padRight(2, '0');
      return _columnPad(columnWidth, '$dollars.$cents');
    }
    return _columnPad(columnWidth, toString());
  }

  String graphFormat(int columnWidth) {
    if (this is NumberResult) {
      final number = (this as NumberResult).value;
      final value = number < 8 ? number.round() : 8;
      return _columnPad(columnWidth, ''.padRight(value, '*'));
    }
    return _columnPad(columnWidth, toString());
  }

  String integer(int columnWidth) {
    if (this is NumberResult) {
      final number = (this as NumberResult).value;
      return _columnPad(columnWidth, number.round().toString());
    }
    return _columnPad(columnWidth, toString());
  }
}

extension CellExt on FormulaType {
  Cell get cell => Cell.fromFormulaType(this);
}
