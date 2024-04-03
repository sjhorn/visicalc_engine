import 'package:visicalc_engine/visicalc_engine.dart';

class NotAvailableResult extends ResultType {
  final String? reason;

  NotAvailableResult([this.reason]);

  @override
  String toString() => 'NA${reason != null ? " - $reason" : ""}';
}
