import 'dart:collection';

import 'package:a1/a1.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

typedef FormulaTypeVisitor = void Function(FormulaType instance);

abstract class FormulaType {
  ResultType eval(ResultTypeCache resultCache,
      [List<FormulaType>? visitedList]);

  String get asFormula;

  void visit(FormulaTypeVisitor callback);

  bool hasReference(A1 reference) => references.contains(reference);

  Set<A1> get references {
    final set = HashSet<A1>();
    visit((instance) {
      if (instance is ReferenceType && !instance.isDeleted) {
        set.add(instance.a1);
      } else if (instance is LookupFunction) {
        for (final a1 in instance.references) {
          set.add(a1);
        }
      }
    });
    return set;
  }

  void markDeletedCell(A1 cell) {
    visit((instance) {
      if (instance is ReferenceType && instance.a1 == cell) {
        instance.markDeleted();
      } else if (instance is LookupFunction &&
          instance.references.contains(cell)) {
        instance.markDeleted();
      }
    });
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FormulaType && other.asFormula == asFormula;
  }

  @override
  int get hashCode => asFormula.hashCode;
}
