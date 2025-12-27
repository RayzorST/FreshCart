import 'package:client/domain/repositories/admin_screen_repository.dart';
import 'package:client/api/client.dart';

class AdminScreenRepositoryImpl implements AdminScreenRepository {
  @override
  Future<bool> isUserAdmin() async {
    try {
      return await ApiClient.isUserAdmin();
    } catch (e) {
      return false;
    }
  }
}