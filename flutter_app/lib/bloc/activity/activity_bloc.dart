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
        emit(ActivityLoaded([{'txid': 'f41e...92a1', 'amount': 500.5, 'confirmations': 10, 'timestamp': 1708291200}, {'txid': 'a12c...3b8e', 'amount': -120.0, 'confirmations': 0, 'timestamp': 1708295500}, {'txid': '88df...e221', 'amount': 1500.0, 'confirmations': 100, 'timestamp': 1708280000}]));
      } catch (e) {
        emit(ActivityError(e.toString()));
      }
    });
  }
}
