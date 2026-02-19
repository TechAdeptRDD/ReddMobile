import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// --- Events ---
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override List<Object> get props => [];
}
class LoadDashboardData extends DashboardEvent {}

// --- States ---
abstract class DashboardState extends Equatable {
  const DashboardState();
  @override List<Object> get props => [];
}
class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}

// --- Bloc ---
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<LoadDashboardData>((event, emit) async {
      emit(DashboardLoading());
      // Logic for loading wallet balance will go here
    });
  }
}
