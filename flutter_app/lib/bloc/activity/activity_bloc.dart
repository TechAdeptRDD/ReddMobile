import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/blockbook_service.dart';

// --- Events ---
abstract class ActivityEvent extends Equatable {
  const ActivityEvent();
  @override
  List<Object> get props => [];
}

class LoadActivity extends ActivityEvent {}

// --- States ---
abstract class ActivityState extends Equatable {
  const ActivityState();
  @override
  List<Object> get props => [];
}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivityLoaded extends ActivityState {
  final List<dynamic> transactions;
  const ActivityLoaded(this.transactions);
  @override
  List<Object> get props => [transactions];
}

class ActivityError extends ActivityState {
  final String message;
  const ActivityError(this.message);
  @override
  List<Object> get props => [message];
}

// --- Bloc ---
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final BlockbookService blockbookService;

  ActivityBloc({required this.blockbookService}) : super(ActivityInitial()) {
    on<LoadActivity>((event, emit) async {
      emit(ActivityLoading());
      try {
        // We fetch the transactions from the global ReddID Index address
        final txs = await blockbookService
            .getTransactions("Ru6sB6S79Z86V99Xy3S6sB6S79Z86V99Xy3");
        emit(ActivityLoaded(txs));
      } catch (e) {
        emit(ActivityError("Failed to sync network activity."));
      }
    });
  }
}
