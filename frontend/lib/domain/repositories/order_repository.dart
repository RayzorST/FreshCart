import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/order_entity.dart';

abstract class OrderRepository {
  Future<Either<String, List<OrderEntity>>> getOrders();
}