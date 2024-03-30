import 'result_type.dart';

class ListResult extends ResultType {
  final List<ResultType> list;
  ListResult(this.list);

  factory ListResult.fromIterable(Iterable<ResultType> it) =>
      ListResult(it.toList());

  @override
  String toString() => 'List: ${list.map((e) => e.toString())}';
}
