part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> user;
  final List<dynamic> orders;

  const ProfileLoaded({required this.user, required this.orders});

  @override
  List<Object> get props => [user, orders];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object> get props => [message];
}

class PasswordChanged extends ProfileState {}

class LogoutSuccess extends ProfileState {}