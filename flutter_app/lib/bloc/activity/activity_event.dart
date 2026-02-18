abstract class ActivityEvent {}

class FetchActivityEvent extends ActivityEvent {
  final String address;

  FetchActivityEvent(this.address);
}
