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

import '../../data/repositories/address_repository_impl.dart' as _i1071;
import '../../data/repositories/auth_repository_impl.dart' as _i895;
import '../../data/repositories/cart_repository_impl.dart' as _i915;
import '../../data/repositories/category_repository_impl.dart' as _i538;
import '../../data/repositories/favorite_repository_impl.dart' as _i1024;
import '../../data/repositories/order_repository_impl.dart' as _i717;
import '../../data/repositories/product_repository_impl.dart' as _i876;
import '../../data/repositories/promotion_repository_impl.dart' as _i490;
import '../../data/repositories/user_repository_impl.dart' as _i790;
import '../../domain/repositories/address_repository.dart' as _i956;
import '../../domain/repositories/auth_repository.dart' as _i1073;
import '../../domain/repositories/cart_repository.dart' as _i46;
import '../../domain/repositories/category_repository.dart' as _i485;
import '../../domain/repositories/favorite_repository.dart' as _i780;
import '../../domain/repositories/order_repository.dart' as _i507;
import '../../domain/repositories/product_repository.dart' as _i933;
import '../../domain/repositories/promotion_repository.dart' as _i501;
import '../../domain/repositories/user_repository.dart' as _i271;
import '../../features/auth/bloc/auth_bloc.dart' as _i55;
import '../../features/auth/bloc/login_bloc.dart' as _i292;
import '../../features/auth/bloc/register_bloc.dart' as _i969;
import '../../features/main/bloc/cart_bloc.dart' as _i377;
import '../../features/main/bloc/favorites_bloc.dart' as _i58;
import '../../features/main/bloc/main_bloc.dart' as _i299;
import '../../features/main/bloc/promotions_bloc.dart' as _i831;
import '../../features/profile/bloc/addresses_bloc.dart' as _i124;
import '../../features/profile/bloc/order_history_bloc.dart' as _i701;
import '../../features/profile/bloc/profile_bloc.dart' as _i40;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  gh.lazySingleton<_i933.ProductRepository>(
    () => _i876.ProductRepositoryImpl(),
  );
  gh.lazySingleton<_i271.UserRepository>(() => _i790.UserRepositoryImpl());
  gh.lazySingleton<_i956.AddressRepository>(
    () => _i1071.AddressRepositoryImpl(),
  );
  gh.lazySingleton<_i501.PromotionRepository>(
    () => _i490.PromotionRepositoryImpl(),
  );
  gh.lazySingleton<_i507.OrderRepository>(() => _i717.OrderRepositoryImpl());
  gh.lazySingleton<_i46.CartRepository>(() => _i915.CartRepositoryImpl());
  gh.lazySingleton<_i1073.AuthRepository>(() => _i895.AuthRepositoryImpl());
  gh.factory<_i55.AuthBloc>(() => _i55.AuthBloc(gh<_i1073.AuthRepository>()));
  gh.factory<_i292.LoginBloc>(
    () => _i292.LoginBloc(gh<_i1073.AuthRepository>()),
  );
  gh.factory<_i969.RegisterBloc>(
    () => _i969.RegisterBloc(gh<_i1073.AuthRepository>()),
  );
  gh.lazySingleton<_i780.FavoriteRepository>(
    () => _i1024.FavoriteRepositoryImpl(),
  );
  gh.lazySingleton<_i485.CategoryRepository>(
    () => _i538.CategoryRepositoryImpl(),
  );
  gh.factory<_i40.ProfileBloc>(
    () => _i40.ProfileBloc(
      gh<_i271.UserRepository>(),
      gh<_i507.OrderRepository>(),
    ),
  );
  gh.factory<_i377.CartBloc>(() => _i377.CartBloc(gh<_i46.CartRepository>()));
  gh.factory<_i124.AddressesBloc>(
    () => _i124.AddressesBloc(gh<_i956.AddressRepository>()),
  );
  gh.factory<_i299.MainBloc>(
    () => _i299.MainBloc(
      gh<_i933.ProductRepository>(),
      gh<_i501.PromotionRepository>(),
    ),
  );
  gh.factory<_i831.PromotionsBloc>(
    () => _i831.PromotionsBloc(gh<_i501.PromotionRepository>()),
  );
  gh.factory<_i701.OrderHistoryBloc>(
    () => _i701.OrderHistoryBloc(gh<_i507.OrderRepository>()),
  );
  gh.factory<_i58.FavoritesBloc>(
    () => _i58.FavoritesBloc(gh<_i780.FavoriteRepository>()),
  );
  return getIt;
}
