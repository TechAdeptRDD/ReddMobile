abstract class ActivityEvent {}

class LoadActivity extends ActivityEvent {
  final String address;

  LoadActivity(this.address);
}
