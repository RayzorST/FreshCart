import 'package:bloc/bloc.dart';
import 'package:client/domain/entities/address_entity.dart';
import 'package:client/domain/repositories/address_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'addresses_event.dart';
part 'addresses_state.dart';

@injectable
class AddressesBloc extends Bloc<AddressesEvent, AddressesState> {
  final AddressRepository _addressRepository;

  AddressesBloc(this._addressRepository) : super(const AddressesState.initial()) {
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
    emit(state.copyWith(status: AddressesStatus.loading));

    try {
      final result = await _addressRepository.getAddresses();

      result.fold(
        (error) {
          emit(state.copyWith(
            status: AddressesStatus.error,
            error: error,
          ));
        },
        (addresses) {
          emit(state.copyWith(
            status: AddressesStatus.loaded,
            addresses: addresses,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: AddressesStatus.error,
        error: 'Ошибка загрузки адресов: $e',
      ));
    }
  }

  Future<void> _onAddAddress(
    AddAddress event,
    Emitter<AddressesState> emit,
  ) async {
    emit(state.copyWith(status: AddressesStatus.saving));

    try {
      final result = await _addressRepository.createAddress(event.addressData);

      result.fold(
        (error) {
          emit(state.copyWith(
            status: AddressesStatus.error,
            error: error,
          ));
        },
        (_) {
          emit(state.copyWith(status: AddressesStatus.saved));
          add(LoadAddresses());
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: AddressesStatus.error,
        error: 'Ошибка добавления адреса: $e',
      ));
    }
  }

  Future<void> _onUpdateAddress(
    UpdateAddress event,
    Emitter<AddressesState> emit,
  ) async {
    emit(state.copyWith(status: AddressesStatus.saving));

    try {
      final result = await _addressRepository.updateAddress(
        event.addressId,
        event.addressData,
      );

      result.fold(
        (error) {
          emit(state.copyWith(
            status: AddressesStatus.error,
            error: error,
          ));
        },
        (_) {
          emit(state.copyWith(status: AddressesStatus.saved));
          add(LoadAddresses());
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: AddressesStatus.error,
        error: 'Ошибка обновления адреса: $e',
      ));
    }
  }

  Future<void> _onDeleteAddress(
    DeleteAddress event,
    Emitter<AddressesState> emit,
  ) async {
    try {
      final result = await _addressRepository.deleteAddress(event.addressId);

      result.fold(
        (error) {
          emit(state.copyWith(
            status: AddressesStatus.error,
            error: error,
          ));
        },
        (_) {
          add(LoadAddresses());
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: AddressesStatus.error,
        error: 'Ошибка удаления адреса: $e',
      ));
    }
  }

  Future<void> _onSetDefaultAddress(
    SetDefaultAddress event,
    Emitter<AddressesState> emit,
  ) async {
    try {
      final result = await _addressRepository.setDefaultAddress(event.addressId);

      result.fold(
        (error) {
          emit(state.copyWith(
            status: AddressesStatus.error,
            error: error,
          ));
        },
        (_) {
          add(LoadAddresses());
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: AddressesStatus.error,
        error: 'Ошибка установки адреса по умолчанию: $e',
      ));
    }
  }
}