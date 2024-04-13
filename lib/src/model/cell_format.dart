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
