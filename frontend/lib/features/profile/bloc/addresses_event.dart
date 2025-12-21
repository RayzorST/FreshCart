part of 'addresses_bloc.dart';

abstract class AddressesEvent extends Equatable {
  const AddressesEvent();

  @override
  List<Object> get props => [];
}

class LoadAddresses extends AddressesEvent {
  const LoadAddresses();
}

class AddAddress extends AddressesEvent {
  final Map<String, dynamic> addressData;

  const AddAddress(this.addressData);

  @override
  List<Object> get props => [addressData];
}

class UpdateAddress extends AddressesEvent {
  final int addressId;
  final Map<String, dynamic> addressData;

  const UpdateAddress(this.addressId, this.addressData);

  @override
  List<Object> get props => [addressId, addressData];
}

class DeleteAddress extends AddressesEvent {
  final int addressId;

  const DeleteAddress(this.addressId);

  @override
  List<Object> get props => [addressId];
}

class SetDefaultAddress extends AddressesEvent {
  final int addressId;

  const SetDefaultAddress(this.addressId);

  @override
  List<Object> get props => [addressId];
}