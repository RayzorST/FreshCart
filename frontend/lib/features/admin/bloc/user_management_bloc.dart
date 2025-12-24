// user_management_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/domain/entities/user_entity.dart';
import 'package:client/domain/repositories/user_management_repository.dart';

part 'user_management_event.dart';
part 'user_management_state.dart';

class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  final UserManagementRepository repository;

  UserManagementBloc({required this.repository}) : super(const UserManagementInitial()) {
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
    
    final result = await repository.getUsers();
    
    result.fold(
      (error) => emit(UserManagementError(error)),
      (users) => emit(UserManagementLoaded(users)),
    );
  }

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<UserManagementState> emit,
  ) async {
    final result = await repository.blockUser(event.userId);
    
    result.fold(
      (error) => emit(UserManagementError(error)),
      (_) {
        emit(const UserManagementOperationSuccess('Пользователь заблокирован'));
        add(const LoadUsers());
      },
    );
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<UserManagementState> emit,
  ) async {
    final result = await repository.unblockUser(event.userId);
    
    result.fold(
      (error) => emit(UserManagementError(error)),
      (_) {
        emit(const UserManagementOperationSuccess('Пользователь разблокирован'));
        add(const LoadUsers());
      },
    );
  }

  Future<void> _onChangeUserRole(
    ChangeUserRole event,
    Emitter<UserManagementState> emit,
  ) async {
    final result = await repository.changeUserRole(event.userId, event.newRole);
    
    result.fold(
      (error) => emit(UserManagementError(error)),
      (_) {
        emit(UserManagementOperationSuccess('Роль изменена на ${event.newRole}'));
        add(const LoadUsers());
      },
    );
  }
}