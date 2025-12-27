// user_management_state.dart
part of 'user_management_bloc.dart';

abstract class UserManagementState {
  const UserManagementState();
}

class UserManagementInitial extends UserManagementState {
  const UserManagementInitial();
}

class UserManagementLoading extends UserManagementState {
  const UserManagementLoading();
}

class UserManagementLoaded extends UserManagementState {
  final List<UserEntity> users;

  const UserManagementLoaded(this.users);

  List<UserEntity> get activeUsers => users.where((u) => u.isActive!).toList();
  List<UserEntity> get blockedUsers => users.where((u) => !u.isActive!).toList();
  
  List<UserEntity> get adminUsers => users.where((u) => u.isAdmin).toList();
  List<UserEntity> get regularUsers => users.where((u) => !u.isAdmin).toList();

  int get totalUsers => users.length;
  int get activeUsersCount => activeUsers.length;
  int get blockedUsersCount => blockedUsers.length;
  int get adminUsersCount => adminUsers.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserManagementLoaded &&
      _listsEqual(other.users, users);
  }

  bool _listsEqual(List<UserEntity> list1, List<UserEntity> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  @override
  int get hashCode => users.length;
}

class UserManagementError extends UserManagementState {
  final String message;

  const UserManagementError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserManagementError &&
      other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class UserManagementOperationSuccess extends UserManagementState {
  final String message;

  const UserManagementOperationSuccess(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserManagementOperationSuccess &&
      other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}