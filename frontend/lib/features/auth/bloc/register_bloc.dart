import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/usecases/register_usecase.dart';
import 'package:client/domain/entities/user_entity.dart';

part 'register_event.dart';
part 'register_state.dart';

@injectable
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterUseCase _registerUseCase;

  RegisterBloc(this._registerUseCase) : super(RegisterInitial()) {
    on<RegisterButtonPressed>(_onRegisterButtonPressed);
  }

  Future<void> _onRegisterButtonPressed(
    RegisterButtonPressed event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());
    
    final result = await _registerUseCase(
      email: event.email,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
    );
    
    result.fold(
      (error) => emit(RegisterFailure(error: error)),
      (user) => emit(RegisterSuccess(user: user)),
    );
  }
}