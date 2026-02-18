import '../../models/transaction.dart';

abstract class ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivityLoaded extends ActivityState {
  final List<Transaction> txs;

  ActivityLoaded(this.txs);
}

class ActivityError extends ActivityState {
  final String message;

  ActivityError(this.message);
}
