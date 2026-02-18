import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/blockbook_service.dart';

// Events
abstract class ActivityEvent {}
class LoadActivity extends ActivityEvent {
  final String address;
  LoadActivity(this.address);
}

// States
abstract class ActivityState {}
class ActivityInitial extends ActivityState {}
class ActivityLoading extends ActivityState {}
class ActivityLoaded extends ActivityState {
  final List<dynamic> transactions;
  ActivityLoaded(this.transactions);
}
class ActivityError extends ActivityState {
  final String message;
  ActivityError(this.message);
}

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final BlockbookService blockbookService;

  ActivityBloc({required this.blockbookService}) : super(ActivityInitial()) {
    on<LoadActivity>((event, emit) async {
      emit(ActivityLoading());
      try {
        final txs = await blockbookService.getTransactions(event.address);
        emit(ActivityLoaded(txs));
      } catch (e) {
        emit(ActivityError(e.toString()));
      }
    });
  }
}
