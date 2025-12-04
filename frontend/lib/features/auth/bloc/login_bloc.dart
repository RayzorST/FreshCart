import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/usecases/login_usecase.dart';
import 'package:client/domain/entities/user_entity.dart';

part 'login_event.dart';
part 'login_state.dart';

@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase _loginUseCase;

  LoginBloc(this._loginUseCase) : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    
    final result = await _loginUseCase(event.email, event.password);
    
    result.fold(
      (error) => emit(LoginFailure(error: error)),
      (user) => emit(LoginSuccess(user: user)),
    );
  }
}