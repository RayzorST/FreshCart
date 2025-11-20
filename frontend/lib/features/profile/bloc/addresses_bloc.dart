import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';
import 'package:equatable/equatable.dart';

part 'addresses_event.dart';
part 'addresses_state.dart';

class AddressesBloc extends Bloc<AddressesEvent, AddressesState> {
  AddressesBloc() : super(AddressesInitial()) {
    on<LoadAddresses>(_onLoadAddresses);
    on<AddAddress>(_onAddAddress);
    on<UpdateAddress>(_onUpdateAddress);
    on<DeleteAddress>(_onDeleteAddress);
    on<SetDefaultAddress>(_onSetDefaultAddress);
  }

  Future<void> _onLoadAddresses(
    LoadAddresses event,
    Emitter<AddressesState> emit,
  ) async {
    emit(AddressesLoading());
    try {
      final addresses = await ApiClient.getAddresses();
      emit(AddressesLoaded(addresses: addresses));
    } catch (e) {
      emit(AddressesError(message: e.toString()));
    }
  }

  Future<void> _onAddAddress(
    AddAddress event,
    Emitter<AddressesState> emit,
  ) async {
    try {
      await ApiClient.createAddress(event.addressData);
      add(LoadAddresses()); // Перезагружаем список
    } catch (e) {
      emit(AddressesError(message: e.toString()));
    }
  }

  Future<void> _onUpdateAddress(
    UpdateAddress event,
    Emitter<AddressesState> emit,
  ) async {
    try {
      await ApiClient.updateAddress(event.addressId, event.addressData);
      add(LoadAddresses());
    } catch (e) {
      emit(AddressesError(message: e.toString()));
    }
  }

  Future<void> _onDeleteAddress(
    DeleteAddress event,
    Emitter<AddressesState> emit,
  ) async {
    try {
      await ApiClient.deleteAddress(event.addressId);
      add(LoadAddresses());
    } catch (e) {
      emit(AddressesError(message: e.toString()));
    }
  }

  Future<void> _onSetDefaultAddress(
    SetDefaultAddress event,
    Emitter<AddressesState> emit,
  ) async {
    try {
      await ApiClient.setDefaultAddress(event.addressId);
      add(LoadAddresses());
    } catch (e) {
      emit(AddressesError(message: e.toString()));
    }
  }
}