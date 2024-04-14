// Copyright (c) 2024, Scott Horn.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// CellFormat follows the format style of VisiCalc based on its manual
///
/// general - this is the format of a cell if no formatting is provided
/// integer - this forces a decimal to be formatted as an integer
/// dollars - this is 0.00 style format like currency but without the symbol
/// left - left aligned formatting
/// right - right aligned formatting
/// graph - this used the '*' charactor to simluate a bar chart eg. *****
/// defaultFormat - is the dynamic setting for new cells, that be override
/// from general
enum CellFormat {
  general,
  integer,
  dollars,
  left,
  right,
  graph;

  static CellFormat defaultFormat = CellFormat.general;

  static CellFormat fromChar(String? char) => switch (char) {
        '' => CellFormat.general,
        '\$' => CellFormat.dollars,
        '*' => CellFormat.graph,
        'I' => CellFormat.integer,
        'L' => CellFormat.left,
        'R' => CellFormat.right,
        _ => CellFormat.defaultFormat,
      };

  String? get toChar => switch (this) {
        CellFormat.general => null,
        CellFormat.dollars => '\$',
        CellFormat.graph => '*',
        CellFormat.integer => 'I',
        CellFormat.left => 'L',
        CellFormat.right => 'R',
      };
}
