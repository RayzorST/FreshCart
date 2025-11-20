import 'package:client/features/main/bloc/cart_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/widgets/splash_screen.dart';

// Auth BLoC
import 'package:client/features/auth/bloc/auth_bloc.dart';
import 'package:client/features/auth/bloc/login_bloc.dart';
import 'package:client/features/auth/bloc/register_bloc.dart';
import 'package:client/features/auth/screens/login_screen.dart';
import 'package:client/features/auth/screens/register_screen.dart';

// Main BLoC
import 'package:client/features/main/bloc/main_bloc.dart';
import 'package:client/features/main/bloc/favorites_bloc.dart';
import 'package:client/features/main/bloc/promotions_bloc.dart';

// Profile BLoC
import 'package:client/features/profile/bloc/profile_bloc.dart';
import 'package:client/features/profile/bloc/order_history_bloc.dart';
import 'package:client/features/profile/bloc/settings_bloc.dart';
import 'package:client/features/profile/bloc/addresses_bloc.dart';

// Screens
import 'package:client/features/main/screens/main_screen.dart';
import 'package:client/features/main/screens/promotion_screen.dart';
import 'package:client/features/analysis/screens/analysis_screen.dart';
import 'package:client/features/analysis/screens/image_picker_screen.dart';
import 'package:client/features/analysis/screens/analysis_history_screen.dart';
import 'package:client/features/product/screens/product_screen.dart';
import 'package:client/features/profile/screens/profile_screen.dart';
import 'package:client/features/profile/screens/addresses_screen.dart';
import 'package:client/features/profile/screens/help_screen.dart';
import 'package:client/features/profile/screens/settings_screen.dart';
import 'package:client/features/profile/screens/order_history_screen.dart';

class FreshCartApp extends StatefulWidget {
  const FreshCartApp({super.key});

  @override
  State<FreshCartApp> createState() => _FreshCartAppState();
}

class _FreshCartAppState extends State<FreshCartApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          pageBuilder: (context, state) => MaterialPage(
            child: SplashScreen(),
          ),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder: (context, state) => MaterialPage(
            child: BlocProvider(
              create: (context) => LoginBloc(),
              child: const LoginScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          pageBuilder: (context, state) => MaterialPage(
            child: BlocProvider(
              create: (context) => RegisterBloc(),
              child: const RegisterScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (context, state) => MaterialPage(
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<MainBloc>()),
                BlocProvider.value(value: context.read<FavoritesBloc>()),
                BlocProvider.value(value: context.read<PromotionsBloc>()),
                BlocProvider.value(value: context.read<AuthBloc>()),
              ],
              child: const MainScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder: (context, state) => MaterialPage(
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<AuthBloc>()),
                BlocProvider(
                  create: (context) => context.read<ProfileBloc>(),
                ),
              ],
              child: const ProfileScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/order-history',
          name: 'order-history',
          pageBuilder: (context, state) => MaterialPage(
            child: BlocProvider(
              create: (context) => OrderHistoryBloc()..add(LoadOrders()),
              child: const OrderHistoryScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/addresses',
          name: 'addresses',
          pageBuilder: (context, state) => MaterialPage(
            child: BlocProvider(
              create: (context) => AddressesBloc()..add(LoadAddresses()),
              child: const AddressesScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => MaterialPage(
            child: BlocProvider.value(
              value: context.read<SettingsBloc>(),
              child: const SettingsScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/help',
          name: 'help',
          builder: (context, state) => const HelpScreen(),
        ),
        GoRoute(
          path: '/analysis/camera',
          name: 'camera',
          builder: (context, state) => const ImagePickerScreen(),
        ),
        GoRoute(
          path: '/analysis/history',
          name: 'analysis-history',
          builder: (context, state) => const AnalysisHistoryScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          name: 'analysis-result',
          builder: (context, state) {
            final imageData = state.extra as String?;
            if (imageData == null) {
              return const Scaffold(
                body: Center(child: Text('Ошибка: изображение не найдено')),
              );
            }
            return AnalysisResultScreen(imageData: imageData);
          },
        ),
        GoRoute(
          path: '/product/:id',
          name: 'product',
          builder: (context, state) {
            try {
              final product = state.extra as Map<String, dynamic>?;
              if (product == null) {
                return const Scaffold(
                  body: Center(child: Text('Ошибка загрузки товара')),
                );
              }
              return ProductScreen(product: product);
            } catch (e) {
              return const Scaffold(
                body: Center(child: Text('Ошибка загрузки товара')),
              );
            }
          },
        ),
        GoRoute(
          path: '/promotion/:promotionId',
          name: 'promotion',
          pageBuilder: (context, state) => MaterialPage(
            child: BlocProvider.value(
              value: context.read<PromotionsBloc>(),
              child: PromotionScreen(
                promotionId: int.tryParse(state.pathParameters['promotionId'] ?? '') ?? 0,
              ),
            ),
          ),
        ),
      ],
      redirect: (context, state) {
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;

        if (authState is AuthLoading || authState is AuthInitial) {
          return null;
        }

        final isAuthenticated = authState is AuthAuthenticated;
        final isSplash = state.uri.path == '/splash';
        final isAuthPage = state.uri.path == '/login' || state.uri.path == '/register';

        if (isSplash) {
          return null;
        }

        if (!isAuthenticated && !isAuthPage) {
          return '/login';
        }

        if (isAuthenticated && isAuthPage) {
          return '/';
        }

        return null;
      },
    );
  }

 @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc()..add(AppStarted()),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => SettingsBloc()..add(LoadThemeSettings()),
          lazy: false,
        ),
        BlocProvider(create: (context) => MainBloc()),
        BlocProvider(create: (context) => FavoritesBloc()..add(const FavoritesLoaded())),
        BlocProvider(create: (context) => PromotionsBloc()),
        BlocProvider(create: (context) => CartBloc()..add(const CartLoaded())),
      ],
      child: Builder(
        builder: (context) {
          return BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {

              if (authState is AuthAuthenticated) {
                context.read<SettingsBloc>().add(LoadNotificationSettings());
                Future.microtask(() => _router.go('/'));
              } else if (authState is AuthUnauthenticated) {
                Future.microtask(() => _router.go('/login'));
              }
            },
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                return BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, settingsState) {
                    final theme = _getTheme(settingsState);
                    
                    return MaterialApp.router(
                      title: 'FreshCart',
                      theme: theme,
                      routerConfig: _router,
                      debugShowCheckedModeBanner: false,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  ThemeData _getTheme(SettingsState state) {
    if (state is SettingsLoaded) {
      return state.isDarkTheme ? AppTheme.darkTheme : AppTheme.lightTheme;
    }
    return AppTheme.lightTheme;
  }
}