import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    
    try {
      final response = await ApiClient.login(event.email, event.password);
      final token = response['access_token'];
      emit(LoginSuccess(token: token));
    } catch (e) {
      emit(LoginFailure(error: e.toString()));
    }
  }
}