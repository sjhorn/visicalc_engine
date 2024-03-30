import 'result_type.dart';

class NotAvailableResult extends ResultType {
  final String? reason;

  NotAvailableResult([this.reason]);

  @override
  String toString() => 'NA${reason != null ? " - $reason" : ""}';
}
