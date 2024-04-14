// Copyright (c) 2024, Scott Horn.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:petitparser/petitparser.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

/// FormatExpression allows parsing in formats the optionally appear
/// at the start of a cell expression
class FormatExpression extends Expression {
  @override
  Parser start() => cellContent().end();

  /// cellFormat represents the format for a cell
  ///
  /// CellFormat.general => '',
  /// CellFormat.dollars => '/F\$',
  /// CellFormat.graph => '/F*',
  /// CellFormat.integer => '/FI',
  /// CellFormat.left => '/FL',
  /// CellFormat.right => '/FR',
  Parser<String> cellFormat() =>
      seq2(string('/F'), anyOf('\$*ILR')).map2((p0, p1) => p1);

  /// repeating is a repeating character format used to fill a cell
  /// with that character
  ///
  /// Examples:
  /// /-= - ============
  /// /-- - ------------
  /// /-> - >>>>>>>>>>>>
  Parser<RepeatingContent> repeating() =>
      seq2(string('/-'), any().plus().flatten())
          .map2((p0, p1) => RepeatingContent(p1));

  /// cellContent can either be an expression or repeating
  Parser<Cell> cellContent() => seq2(
              cellFormat().optional(),
              [
                labelOrExpression()
                    .flatten()
                    .map((value) => ExpressionContent.fromString(value)),
                repeating(),
              ].toChoiceParser())
          .map2(
        (format, content) => Cell(
          content: content,
          format: CellFormat.fromChar(format),
        ),
      );
}
