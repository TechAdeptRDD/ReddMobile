abstract class DashboardEvent {}

class AcquireReddIDEvent extends DashboardEvent {
  final String handle;
  AcquireReddIDEvent(this.handle);
}

class BroadcastTransactionEvent extends DashboardEvent {
  final String signedTxHex;
  BroadcastTransactionEvent(this.signedTxHex);
}
