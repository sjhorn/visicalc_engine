import 'dart:collection';

import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

typedef FormulaTypeVisitor = void Function(FormulaType instance);

abstract class FormulaType {
  ResultType eval(ResultTypeCache resultCache,
      [List<FormulaType>? visitedList]);

  String get asFormula;

  void visit(FormulaTypeVisitor callback);

  Set<A1> get dependants {
    final set = HashSet<A1>();
    visit((instance) {
      if (instance is ReferenceType) {
        set.add(instance.a1);
      } else if (instance is LookupFunction) {
        for (final a1 in instance.dependencies) {
          set.add(a1);
        }
      }
    });
    return set;
  }
}
