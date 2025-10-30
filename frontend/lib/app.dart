import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/providers/theme_provider.dart';
import 'package:client/features/auth/screens/login_screen.dart';
import 'package:client/features/auth/screens/register_screen.dart';
import 'package:client/features/main/screens/main_screen.dart';
import 'package:client/features/main/screens/promotion_screen.dart';
import 'package:client/features/camera/screens/camera_screen.dart';
import 'package:client/features/analysis/screens/analysis_screen.dart';
import 'package:client/features/product/screens/product_screen.dart';
import 'package:client/features/profile/screens/addresses_screen.dart';
import 'package:client/features/profile/screens/help_screen.dart';
import 'package:client/features/profile/screens/settings_screen.dart';
import 'package:client/features/profile/screens/order_history_screen.dart';
import 'package:client/core/providers/auth_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState != null ? '/' : '/login',

    redirect: (context, state) {
      final isAuthenticated = authState != null;
      final isGoingToAuth = state.uri.path == '/login' || state.uri.path == '/register';
      
      if (!isAuthenticated && !isGoingToAuth) {
        return '/login';
      }
      
      // Если авторизован и пытается попасть на страницы логина/регистрации
      if (isAuthenticated && isGoingToAuth) {
        return '/';
      }
      
      return null;
    },
    
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/camera',
        name: 'camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/analysis',
        name: 'analysis',
        builder: (context, state) => AnalysisScreen(
          imagePath: state.extra as String,
        ),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          try {
            final product = state.extra as Map<String, dynamic>;
            return ProductScreen(product: product);
          } catch (e) {
            print('Error in route: $e');
            print('Extra type: ${state.extra?.runtimeType}');
            print('Extra value: ${state.extra}');
            return const Scaffold(body: Center(child: Text('Ошибка загрузки товара')));
          }
        },
      ),
      GoRoute(
        path: '/promotion/:id',
        builder: (context, state) {
          final promotion = state.extra as Map<String, dynamic>;
          return PromotionScreen(promotion: promotion);
        },
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/order-history',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
    ],
  );
});

class FreshCartApp extends StatelessWidget {
  const FreshCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final router = ref.watch(goRouterProvider);
          final isDarkTheme = ref.watch(themeProvider); // ← Получаем состояние темы
          
          return MaterialApp.router(
            title: 'FreshCart',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light, // ← Используем нашу тему
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}