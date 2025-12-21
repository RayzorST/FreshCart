part of 'addresses_bloc.dart';

enum AddressesStatus {
  initial,
  loading,
  loaded,
  saving,
  saved,
  error,
}

class AddressesState extends Equatable {
  final AddressesStatus status;
  final List<AddressEntity> addresses;
  final String? error;

  const AddressesState({
    required this.status,
    required this.addresses,
    this.error,
  });

  const AddressesState.initial()
      : status = AddressesStatus.initial,
        addresses = const [],
        error = null;

  AddressesState copyWith({
    AddressesStatus? status,
    List<AddressEntity>? addresses,
    String? error,
  }) {
    return AddressesState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, addresses, error];
}