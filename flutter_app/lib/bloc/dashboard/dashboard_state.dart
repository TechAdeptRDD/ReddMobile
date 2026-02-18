abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class HandleAvailable extends DashboardState {
  final String handle;
  HandleAvailable(this.handle);
}

class HandleTaken extends DashboardState {
  final String handle;
  HandleTaken(this.handle);
}

class ReddIDPayloadGenerated extends DashboardState {
  final String payloadHex;
  ReddIDPayloadGenerated(this.payloadHex);
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
