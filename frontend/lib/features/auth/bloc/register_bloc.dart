import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc() : super(RegisterInitial()) {
    on<RegisterButtonPressed>(_onRegisterButtonPressed);
  }

  Future<void> _onRegisterButtonPressed(
    RegisterButtonPressed event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());
    
    try {
      final response = await ApiClient.registration(
        event.email,
        event.password,
        event.firstName,
        event.lastName
      );
      
      final token = response['access_token'];
      emit(RegisterSuccess(token: token));
    } catch (e) {
      emit(RegisterFailure(error: e.toString()));
    }
  }
}