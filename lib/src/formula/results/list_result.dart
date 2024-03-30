import 'result_type.dart';

class ListResult extends ResultType {
  final List<ResultType> list;
  ListResult(this.list);

  factory ListResult.fromIterable(Iterable<ResultType> it) =>
      ListResult(it.toList());

  @override
  String toString() => 'List: ${list.map((e) => e.toString())}';
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is ListResult) {
      for (final (index, item) in other.list.indexed) {
        if (list[index] != item) return false;
      }
      return true;
    }
    return false;
  }

  @override
  int get hashCode => list.fold(
      0, (previousValue, element) => previousValue ^ element.hashCode);
}
