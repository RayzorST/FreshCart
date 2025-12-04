// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../data/datasources/local/app_database.dart' as _i483;
import '../../data/repositories/auth_repository_impl.dart' as _i895;
import '../../data/repositories/cart_repository_impl.dart' as _i915;
import '../../domain/repositories/auth_repository.dart' as _i1073;
import '../../domain/repositories/cart_repository.dart' as _i46;
import '../../domain/usecases/cart_usecases.dart' as _i44;
import '../../domain/usecases/login_usecase.dart' as _i253;
import '../../domain/usecases/register_usecase.dart' as _i35;
import '../../features/auth/bloc/auth_bloc.dart' as _i55;
import '../../features/auth/bloc/login_bloc.dart' as _i292;
import '../../features/auth/bloc/register_bloc.dart' as _i969;
import '../../features/main/bloc/cart_bloc.dart' as _i377;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  gh.lazySingleton<_i483.AppDatabase>(() => _i483.AppDatabase());
  gh.lazySingleton<_i1073.AuthRepository>(() => _i895.AuthRepositoryImpl());
  gh.factory<_i55.AuthBloc>(() => _i55.AuthBloc(gh<_i1073.AuthRepository>()));
  gh.lazySingleton<_i46.CartRepository>(
    () => _i915.CartRepositoryImpl(gh<_i483.AppDatabase>()),
  );
  gh.factory<_i377.CartBloc>(() => _i377.CartBloc(gh<_i46.CartRepository>()));
  gh.factory<_i253.LoginUseCase>(
    () => _i253.LoginUseCase(gh<_i1073.AuthRepository>()),
  );
  gh.factory<_i35.RegisterUseCase>(
    () => _i35.RegisterUseCase(gh<_i1073.AuthRepository>()),
  );
  gh.factory<_i292.LoginBloc>(() => _i292.LoginBloc(gh<_i253.LoginUseCase>()));
  gh.factory<_i44.GetCartItemsUseCase>(
    () => _i44.GetCartItemsUseCase(gh<_i46.CartRepository>()),
  );
  gh.factory<_i44.AddToCartUseCase>(
    () => _i44.AddToCartUseCase(gh<_i46.CartRepository>()),
  );
  gh.factory<_i44.UpdateCartItemUseCase>(
    () => _i44.UpdateCartItemUseCase(gh<_i46.CartRepository>()),
  );
  gh.factory<_i44.RemoveFromCartUseCase>(
    () => _i44.RemoveFromCartUseCase(gh<_i46.CartRepository>()),
  );
  gh.factory<_i44.SyncCartUseCase>(
    () => _i44.SyncCartUseCase(gh<_i46.CartRepository>()),
  );
  gh.factory<_i969.RegisterBloc>(
    () => _i969.RegisterBloc(gh<_i35.RegisterUseCase>()),
  );
  return getIt;
}
