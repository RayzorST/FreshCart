import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const String _tokenKey = 'auth_token';

  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      
      if (token != null) {
        ApiClient.setToken(token);
        try {
          await ApiClient.getProfile();
          emit(AuthAuthenticated());
        } catch (e) {
          await _clearToken();
          emit(AuthUnauthenticated());
        }
      } else {
        ApiClient.clearToken();
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, event.token);
    ApiClient.setToken(event.token);
    emit(AuthAuthenticated());
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    await _clearToken();
    emit(AuthUnauthenticated());
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    ApiClient.clearToken();
  }
}