import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/features/main/screens/cart_screen.dart';
import 'package:client/features/main/screens/favorites_screen.dart';
import 'package:client/features/profile/screens/profile_screen.dart';
import 'package:client/core/widgets/navigation_bar.dart';
import 'package:client/core/widgets/camera_fab.dart';
import 'package:client/features/admin/screens/admin_screen.dart';
import 'package:client/features/main/bloc/main_bloc.dart';
import 'package:client/core/widgets/promotions_section.dart';
import 'package:client/core/widgets/category_filter.dart';
import 'package:client/core/widgets/product_section.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<MainBloc>();
      bloc.add(const PromotionsLoaded());
      bloc.add(const CategoriesLoaded());
      bloc.add(const ProductsLoaded());
    });
  }

  void _onItemTapped(int index) {
    context.read<MainBloc>().add(MainTabChanged(index));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainBloc, MainState>(
      builder: (context, state) {
        final isWideScreen = MediaQuery.of(context).size.width > 600;
        
        final List<Widget> screens = [
          _buildHomeScreen(), 
          const CartScreen(),
          const FavoritesScreen(),
          const ProfileScreen(),
          if (kIsWeb) const AdminScreen(),
        ];

        if (isWideScreen) {
          return Scaffold(
            body: Row(
              children: [
                // Боковая навигация для широких экранов
                CustomNavigationBar(
                  currentIndex: state.currentTabIndex,
                  onItemTapped: _onItemTapped,
                  isVertical: true,
                ),
                Expanded(
                  child: screens[state.currentTabIndex],
                ),
              ],
            ),
            floatingActionButton: const CameraFAB(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        }

        return Scaffold(
          body: screens[state.currentTabIndex],
          bottomNavigationBar: CustomNavigationBar(
            currentIndex: state.currentTabIndex,
            onItemTapped: _onItemTapped,
            isVertical: false,
          ),
          floatingActionButton: const CameraFAB(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  Widget _buildHomeScreen() { 
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Продуктовый маркет',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const PromotionsSection(),
            const CategoryFilterWidget(),
            const ProductGridSection(),
          ],
        ),
      )
    );
  }
}