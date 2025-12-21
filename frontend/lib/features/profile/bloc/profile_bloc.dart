import 'package:bloc/bloc.dart';
import 'package:client/domain/entities/user_entity.dart';
import 'package:client/domain/entities/order_entity.dart';
import 'package:client/domain/repositories/user_repository.dart';
import 'package:client/domain/repositories/order_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'profile_event.dart';
part 'profile_state.dart';

@injectable
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository _userRepository;
  final OrderRepository _orderRepository;

  ProfileBloc(this._userRepository, this._orderRepository)
      : super(const ProfileState.initial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<ChangePassword>(_onChangePassword);
    on<Logout>(_onLogout);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));

    try {
      final userResult = await _userRepository.getProfile();
      final ordersResult = await _orderRepository.getOrders();

      userResult.fold(
        (userError) {
          emit(state.copyWith(
            status: ProfileStatus.error,
            error: userError,
          ));
        },
        (user) {
          ordersResult.fold(
            (ordersError) {
              // Если заказы не загрузились, все равно показываем профиль
              emit(state.copyWith(
                status: ProfileStatus.loaded,
                user: user,
                orders: const [],
                error: ordersError,
              ));
            },
            (orders) {
              emit(state.copyWith(
                status: ProfileStatus.loaded,
                user: user,
                orders: orders,
              ));
            },
          );
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: 'Ошибка загрузки профиля: $e',
      ));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));

    try {
      final result = await _userRepository.updateProfile(event.profileData);

      result.fold(
        (error) {
          emit(state.copyWith(
            status: ProfileStatus.error,
            error: error,
          ));
        },
        (updatedUser) {
          emit(state.copyWith(
            status: ProfileStatus.updated,
            user: updatedUser,
          ));
          // Перезагружаем профиль для обновления заказов
          add(LoadProfile());
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: 'Ошибка обновления профиля: $e',
      ));
    }
  }

  Future<void> _onChangePassword(
    ChangePassword event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));

    try {
      final result = await _userRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      result.fold(
        (error) {
          emit(state.copyWith(
            status: ProfileStatus.error,
            error: error,
          ));
        },
        (_) {
          emit(state.copyWith(
            status: ProfileStatus.passwordChanged,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: 'Ошибка изменения пароля: $e',
      ));
    }
  }

  Future<void> _onLogout(
    Logout event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final result = await _userRepository.logout();

      result.fold(
        (error) {
          emit(state.copyWith(
            status: ProfileStatus.error,
            error: error,
          ));
        },
        (_) {
          emit(state.copyWith(status: ProfileStatus.logoutSuccess));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        error: 'Ошибка выхода: $e',
      ));
    }
  }
}