import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/api/client.dart';
import 'package:flutter/foundation.dart';

part 'user_management_event.dart';
part 'user_management_state.dart';

class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  UserManagementBloc() : super(const UserManagementInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
    on<ChangeUserRole>(_onChangeUserRole);
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementLoading());
    
    try {
      final users = await ApiClient.getAdminUsers();
      emit(UserManagementLoaded(users));
    } catch (e) {
      emit(UserManagementError('Ошибка загрузки пользователей: $e'));
    }
  }

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      await ApiClient.blockUser(event.userId);
      emit(const UserManagementOperationSuccess('Пользователь заблокирован'));
      add(const LoadUsers());
    } catch (e) {
      emit(UserManagementError('Ошибка при блокировке: $e'));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      await ApiClient.unblockUser(event.userId);
      emit(const UserManagementOperationSuccess('Пользователь разблокирован'));
      add(const LoadUsers());
    } catch (e) {
      emit(UserManagementError('Ошибка при разблокировке: $e'));
    }
  }

  Future<void> _onChangeUserRole(
    ChangeUserRole event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      await ApiClient.setUserRole(event.userId, event.newRole);
      emit(UserManagementOperationSuccess('Роль изменена на ${event.newRole}'));
      add(const LoadUsers());
    } catch (e) {
      emit(UserManagementError('Ошибка при смене роли: $e'));
    }
  }
}