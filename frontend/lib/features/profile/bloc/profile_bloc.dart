import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';
import 'package:equatable/equatable.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<ChangePassword>(_onChangePassword);
    on<Logout>(_onLogout);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final user = await ApiClient.getProfile();
      final orders = await ApiClient.getMyOrders();
      emit(ProfileLoaded(user: user, orders: orders));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await ApiClient.updateProfile(event.profileData);
      add(LoadProfile());
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onChangePassword(
    ChangePassword event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await ApiClient.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(PasswordChanged());
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onLogout(
    Logout event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // Просто эмитим успешный выход, а MultiBlocListener сделает остальное
      emit(LogoutSuccess());
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}