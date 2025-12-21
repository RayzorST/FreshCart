part of 'profile_bloc.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  updating,
  updated,
  passwordChanged,
  logoutSuccess,
  error,
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final UserEntity? user;
  final List<OrderEntity> orders;
  final String? error;

  const ProfileState({
    required this.status,
    this.user,
    required this.orders,
    this.error,
  });

  const ProfileState.initial()
      : status = ProfileStatus.initial,
        user = null,
        orders = const [],
        error = null;

  ProfileState copyWith({
    ProfileStatus? status,
    UserEntity? user,
    List<OrderEntity>? orders,
    String? error,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      orders: orders ?? this.orders,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, user, orders, error];
}