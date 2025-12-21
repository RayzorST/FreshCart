// [file name]: register_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/entities/user_entity.dart';
import 'package:client/domain/repositories/auth_repository.dart';

part 'register_event.dart';
part 'register_state.dart';

@injectable
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository _authRepository;

  RegisterBloc(this._authRepository) : super(RegisterInitial()) {
    on<RegisterButtonPressed>(_onRegisterButtonPressed);
  }

  Future<void> _onRegisterButtonPressed(
    RegisterButtonPressed event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());
    
    final result = await _authRepository.register(
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