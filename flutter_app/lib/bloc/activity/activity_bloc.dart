import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/blockbook_service.dart';
import 'activity_event.dart';
import 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final BlockbookService blockbookService;

  ActivityBloc({required this.blockbookService}) : super(ActivityInitial()) {
    on<LoadActivity>((event, emit) async {
      emit(ActivityLoading());

      try {
        final txs = await blockbookService.getTransactions(event.address);
        emit(ActivityLoaded(txs));
      } catch (e) {
        emit(ActivityError('Failed to fetch activity: $e'));
      }
    });
  }
}
