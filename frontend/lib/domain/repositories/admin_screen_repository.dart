// admin_screen_repository.dart
import 'package:dartz/dartz.dart';

abstract class AdminScreenRepository {
  Future<bool> isUserAdmin();
}