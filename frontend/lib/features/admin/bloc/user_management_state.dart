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
  final List<dynamic> users;

  const UserManagementLoaded(this.users);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserManagementLoaded &&
      listEquals(other.users, users);
  }

  @override
  int get hashCode => users.hashCode;
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