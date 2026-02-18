abstract class DashboardEvent {}

class AcquireReddIDEvent extends DashboardEvent {
  final String handle;
  AcquireReddIDEvent(this.handle);
}

class CheckHandleAvailabilityEvent extends DashboardEvent {
  final String handle;
  CheckHandleAvailabilityEvent(this.handle);
}
