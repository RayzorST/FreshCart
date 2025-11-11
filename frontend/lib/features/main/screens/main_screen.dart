import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/features/cart/screens/cart_screen.dart';
import 'package:client/features/main/screens/favorites_screen.dart';
import 'package:client/features/profile/screens/profile_screen.dart';
import 'package:client/core/widgets/bottom_navigation_bar.dart';
import 'package:client/core/widgets/camera_fab.dart';
import 'package:client/core/widgets/category_filter.dart';
import 'package:client/core/widgets/product_section.dart';
import 'package:client/core/widgets/promotions_section.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentIndexProvider);
    
    final List<Widget> screens = [
      _buildHomeScreen(), 
      const CartScreen(),
      const FavoritesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: const CustomBottomNavigationBar(),
      floatingActionButton: const CameraFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
            PromotionsSection(),
            CategoryFilterWidget(),
            ProductGridSection(),
          ],
        ),
      )
    );
  }
}