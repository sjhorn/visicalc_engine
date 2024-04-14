// Copyright (c) 2024, Scott Horn.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:petitparser/petitparser.dart';
import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

/// FileFormat is the Grammar for parsing the .vc fileformat
/// which includes the cellPosition and global directives
///
/// eg. >A9:... indicates the [A1] cell
/// eg. /W1 indicates a single window...ie no split window
class FileFormat extends FormatExpression {
  @override
  Parser start() => [
        cellPositionExpression(),
        globalDirective(),
      ].toChoiceParser().end();

  /// cellPosition specific which cell this content is parsed into
  ///
  /// Examples:
  /// ```
  /// >A9:/FR"TRUE
  /// >G8:+F8*10
  /// >F8:+F7+1
  /// >E8:"tes
  /// >B8:@SUM(A2...A7)
  /// >A8:/FR"label
  /// >A10:/-=
  /// ```
  Parser<A1> cellPosition() =>
      seq3(char('>'), ref0(a1), char(':')).map3((p0, p1, p2) => A1.parse(p1));

  Parser<MapEntry<A1, Cell>> cellPositionExpression() =>
      seq2(cellPosition(), cellContent()).map2((p0, p1) => MapEntry(p0, p1));

  /// globalDirective indicates different directive to VisiCalc including
  ///
  /// /WH - window split horizontal
  /// /WV - window split vertical
  /// /W1 - return to not split/single window
  /// /WS - windows are synchronised (always in this engine)
  /// /WU - windows are unsynchronised (not used in this engine)
  /// /GOC - global order recalculation either by column (not used)
  /// /GOR - global order recalculation either by row (not used)
  /// /GC10 - set the global column width to 10 (valid 3 to 37)
  /// /GF$ - set the global default format to dollar format
  /// /GRA - global recalculation - automatic (always in this engine)
  /// /GRM - global recalculation - manual (not used as always auto)
  /// /X>A1:>C14: - the current first and last cells?
  ///
  /// Examples:
  /// ```
  /// /W1
  /// /GOC
  /// /GRA
  /// /GC10
  /// /X>A1:>C14:
  /// ```
  Parser<GlobalDirectiveContent> globalDirective() => seq2(char('/'),
          [word(), char(':'), char('>')].toChoiceParser().plus().flatten())
      .map2((p0, p1) => GlobalDirectiveContent(p1));
}
