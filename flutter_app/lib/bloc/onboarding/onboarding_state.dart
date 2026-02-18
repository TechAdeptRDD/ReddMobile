abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class HandleChecking extends OnboardingState {}

class HandleAvailable extends OnboardingState {}

class HandleUnavailable extends OnboardingState {}

class WalletCreating extends OnboardingState {}

class OnboardingComplete extends OnboardingState {}

class OnboardingError extends OnboardingState {
  OnboardingError(this.message);

  final String message;
}
