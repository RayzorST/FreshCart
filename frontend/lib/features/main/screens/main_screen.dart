import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/features/cart/screens/cart_screen.dart';
import 'package:client/features/main/screens/favorites_screen.dart';
import 'package:client/features/profile/screens/profile_screen.dart';
import 'package:client/core/widgets/navigation_bar.dart';
import 'package:client/core/widgets/camera_fab.dart';
import 'package:client/core/widgets/category_filter.dart';
import 'package:client/core/widgets/product_section.dart';
import 'package:client/core/widgets/promotions_section.dart';
import 'package:client/features/admin/admin_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentIndexProvider);
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
            const CustomBottomNavigationBar(),
            Expanded(
              child: screens[currentIndex],
            ),
          ],
        ),
        floatingActionButton: const CameraFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    }

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