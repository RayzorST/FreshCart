// order_management_repository.dart
import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/order_entity.dart';

abstract class OrderManagementRepository {
  Future<Either<String, List<OrderEntity>>> getOrders({String? status});
  Future<Either<String, void>> updateOrderStatus(int orderId, String status);
}