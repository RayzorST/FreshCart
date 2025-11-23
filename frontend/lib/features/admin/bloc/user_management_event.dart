part of 'user_management_bloc.dart';

abstract class UserManagementEvent {
  const UserManagementEvent();
}

class LoadUsers extends UserManagementEvent {
  const LoadUsers();
}

class BlockUser extends UserManagementEvent {
  final int userId;

  const BlockUser(this.userId);
}

class UnblockUser extends UserManagementEvent {
  final int userId;

  const UnblockUser(this.userId);
}

class ChangeUserRole extends UserManagementEvent {
  final int userId;
  final String newRole;

  const ChangeUserRole({
    required this.userId,
    required this.newRole,
  });
}