import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/repositories/auth_repository.dart';
import 'package:client/domain/entities/user_entity.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final isLoggedIn = await _authRepository.isLoggedIn();
    
    if (isLoggedIn) {
      try {
        final userResult = await _authRepository.getCurrentUser();
        
        userResult.fold(
          (error) {
            emit(AuthUnauthenticated());
          },
          (user) {
            emit(AuthAuthenticated(user: user));
          },
        );
      } catch (e) {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedIn(
    LoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthAuthenticated(user: event.user));
  }

  Future<void> _onLoggedOut(
    LoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.clearToken();
    emit(AuthUnauthenticated());
  }
}