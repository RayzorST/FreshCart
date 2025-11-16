import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/providers/theme_provider.dart';
import 'package:client/core/widgets/splash_screen.dart';
import 'package:client/features/auth/screens/login_screen.dart';
import 'package:client/features/auth/screens/register_screen.dart';
import 'package:client/features/main/screens/main_screen.dart';
import 'package:client/features/main/screens/promotion_screen.dart';
import 'package:client/features/analysis/screens/analysis_screen.dart';
import 'package:client/features/analysis/screens/image_picker_screen.dart';
import 'package:client/features/analysis/screens/analysis_history_screen.dart';
import 'package:client/features/product/screens/product_screen.dart';
import 'package:client/features/profile/screens/addresses_screen.dart';
import 'package:client/features/profile/screens/help_screen.dart';
import 'package:client/features/profile/screens/settings_screen.dart';
import 'package:client/features/profile/screens/order_history_screen.dart';
import 'package:client/core/providers/auth_provider.dart';

class FreshCartApp extends StatelessWidget {
  const FreshCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'FreshCart',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return Container(color: Colors.black);
    }

    return _MainApp();
  }
}

class _MainApp extends ConsumerStatefulWidget {
  const _MainApp();

  @override
  ConsumerState<_MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<_MainApp> {
  bool _isAppInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      _waitForAuth(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (mounted) {
      setState(() {
        _isAppInitialized = true;
      });
    }
  }

  Future<void> _waitForAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final authState = ref.read(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAppInitialized) {
      return const SplashScreen();
    }

    return _AppWithRouter();
  }
}

class _AppWithRouter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDarkTheme = ref.watch(themeProvider);

    final router = GoRouter(
      initialLocation: authState != null ? '/' : '/login',
      
      redirect: (context, state) {
        final isAuthenticated = authState != null;
        final isGoingToAuth = state.uri.path == '/login' || state.uri.path == '/register';
        
        if (!isAuthenticated && !isGoingToAuth) {
          return '/login';
        }
        
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
          path: '/analysis/camera',
          name: 'camera',
          builder: (context, state) => const ImagePickerScreen(),
        ),
        GoRoute(
          path: '/analysis/history',
          builder: (context, state) => const AnalysisHistoryScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
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
              return const Scaffold(body: Center(child: Text('Ошибка загрузки товара')));
            }
          },
        ),
        GoRoute(
          path: '/promotion/:promotionId',
          name: 'promotion',
          builder: (context, state) {
            final promotionId = int.tryParse(state.pathParameters['promotionId'] ?? '');
            return PromotionScreen(promotionId: promotionId);
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

    return MaterialApp.router(
      title: 'FreshCart',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}