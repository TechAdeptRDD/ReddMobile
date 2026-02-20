abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class ReddIDPayloadGenerated extends DashboardState {
  final String payloadHex;
  ReddIDPayloadGenerated(this.payloadHex);
}

class TransactionBroadcastSuccess extends DashboardState {
  final String txid;
  TransactionBroadcastSuccess(this.txid);
}

class HandleTaken extends DashboardState {
  final String handle;
  HandleTaken(this.handle);
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
