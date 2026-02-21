import 'package:equatable/equatable.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final String address;
  final String formattedBalance;
  final String fiatValue;
  final List<dynamic> history;

  const DashboardLoaded(
    this.address,
    this.formattedBalance,
    this.fiatValue,
    this.history,
  );

  @override
  List<Object> get props => [address, formattedBalance, fiatValue, history];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object> get props => [message];
}

class ReddIDPayloadGenerated extends DashboardState {
  final String payloadHex;

  const ReddIDPayloadGenerated(this.payloadHex);

  @override
  List<Object> get props => [payloadHex];
}
