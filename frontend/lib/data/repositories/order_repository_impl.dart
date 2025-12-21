import 'package:dartz/dartz.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/order_entity.dart';
import 'package:client/domain/repositories/order_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: OrderRepository)
class OrderRepositoryImpl implements OrderRepository {
  @override
  Future<Either<String, List<OrderEntity>>> getOrders() async {
    try {
      final response = await ApiClient.getMyOrders();
      final orders = response
          .whereType<Map<String, dynamic>>()
          .map((json) => OrderEntity.fromJson(json))
          .toList();
      return Right(orders);
    } catch (e) {
      return Left('Ошибка загрузки заказов: $e');
    }
  }
}