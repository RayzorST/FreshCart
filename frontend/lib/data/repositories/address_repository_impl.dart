import 'package:dartz/dartz.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/address_entity.dart';
import 'package:client/domain/repositories/address_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AddressRepository)
class AddressRepositoryImpl implements AddressRepository {
  @override
  Future<Either<String, List<AddressEntity>>> getAddresses() async {
    try {
      final response = await ApiClient.getAddresses();
      final addresses = response
          .whereType<Map<String, dynamic>>()
          .map((json) => AddressEntity.fromJson(json))
          .toList();
      return Right(addresses);
    } catch (e) {
      return Left('Ошибка загрузки адресов: $e');
    }
  }

  @override
  Future<Either<String, AddressEntity>> createAddress(Map<String, dynamic> addressData) async {
    try {
      final response = await ApiClient.createAddress(addressData);
      final address = AddressEntity.fromJson(response);
      return Right(address);
    } catch (e) {
      return Left('Ошибка создания адреса: $e');
    }
  }

  @override
  Future<Either<String, AddressEntity>> updateAddress(int addressId, Map<String, dynamic> addressData) async {
    try {
      final response = await ApiClient.updateAddress(addressId, addressData);
      final address = AddressEntity.fromJson(response);
      return Right(address);
    } catch (e) {
      return Left('Ошибка обновления адреса: $e');
    }
  }

  @override
  Future<Either<String, void>> deleteAddress(int addressId) async {
    try {
      await ApiClient.deleteAddress(addressId);
      return const Right(null);
    } catch (e) {
      return Left('Ошибка удаления адреса: $e');
    }
  }

  @override
  Future<Either<String, void>> setDefaultAddress(int addressId) async {
    try {
      await ApiClient.setDefaultAddress(addressId);
      return const Right(null);
    } catch (e) {
      return Left('Ошибка установки адреса по умолчанию: $e');
    }
  }
}