// [file name]: login_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/entities/user_entity.dart';
import 'package:client/domain/repositories/auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;

  LoginBloc(this._authRepository) : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    
    final result = await _authRepository.login(event.email, event.password);
    
    result.fold(
      (error) => emit(LoginFailure(error: error)),
      (user) => emit(LoginSuccess(user: user)),
    );
  }
}