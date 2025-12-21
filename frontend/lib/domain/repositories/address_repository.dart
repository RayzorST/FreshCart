import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/address_entity.dart';

abstract class AddressRepository {
  Future<Either<String, List<AddressEntity>>> getAddresses();
  Future<Either<String, AddressEntity>> createAddress(Map<String, dynamic> addressData);
  Future<Either<String, AddressEntity>> updateAddress(int addressId, Map<String, dynamic> addressData);
  Future<Either<String, void>> deleteAddress(int addressId);
  Future<Either<String, void>> setDefaultAddress(int addressId);
}