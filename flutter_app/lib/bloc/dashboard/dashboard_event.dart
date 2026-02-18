abstract class DashboardEvent {}

class AcquireReddIDEvent extends DashboardEvent {
  final String handle;
  AcquireReddIDEvent(this.handle);
}
