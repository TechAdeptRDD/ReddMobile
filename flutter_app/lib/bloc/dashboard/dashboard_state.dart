abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class ReddIDPayloadGenerated extends DashboardState {
  final String payloadHex;
  ReddIDPayloadGenerated(this.payloadHex);
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
