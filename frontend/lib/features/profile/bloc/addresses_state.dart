part of 'addresses_bloc.dart';

abstract class AddressesState extends Equatable {
  const AddressesState();

  @override
  List<Object> get props => [];
}

class AddressesInitial extends AddressesState {}

class AddressesLoading extends AddressesState {}

class AddressesLoaded extends AddressesState {
  final List<dynamic> addresses;

  const AddressesLoaded({required this.addresses});

  @override
  List<Object> get props => [addresses];
}

class AddressesError extends AddressesState {
  final String message;

  const AddressesError({required this.message});

  @override
  List<Object> get props => [message];
}