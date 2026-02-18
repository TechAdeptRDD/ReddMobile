abstract class OnboardingEvent {}

class CheckHandle extends OnboardingEvent {
  CheckHandle(this.handle);

  final String handle;
}

class ClaimHandleAndCreateWallet extends OnboardingEvent {
  ClaimHandleAndCreateWallet(this.handle);

  final String handle;
}
