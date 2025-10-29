import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/features/cart/screens/cart_screen.dart';
import 'package:client/features/main/screens/favorites_screen.dart';
import 'package:client/features/profile/screens/profile_screen.dart';
import 'package:client/core/widgets/bottom_navigation_bar.dart';
import 'package:client/core/widgets/camera_fab.dart';
import 'package:client/core/providers/products_provider.dart';
import 'package:client/core/providers/cart_provider.dart';
import 'package:client/core/providers/favorites_provider.dart';
import 'package:client/api/client.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final List<Map<String, dynamic>> _promotions = [
    {
      'id': '1',
      'title': 'Скидка 20%',
      'color': Colors.green,
    },
    {
      'id': '2', 
      'title': 'Акция на мясо',
      'color': Colors.red,
    },
    {
      'id': '3',
      'title': 'Фруктовая неделя',
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentIndexProvider);
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
    final List<Widget> screens = [
      _buildHomeScreen(productsAsync, categoriesAsync, selectedCategory),
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

  Widget _buildHomeScreen(
    AsyncValue<List<dynamic>> productsAsync,
    AsyncValue<List<dynamic>> categoriesAsync,
    String selectedCategory,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(
            'Продуктовый маркет',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 0,
          floating: true,
          snap: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Реализовать поиск
              },
            ),
          ],
        ),

        // Акции
        SliverToBoxAdapter(
          child: SizedBox(
            height: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        'Акции',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_promotions.length}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _promotions.length,
                    itemBuilder: (context, index) {
                      final promotion = _promotions[index];
                      return _buildPromotionCard(promotion, context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Фильтр по категориям
        SliverToBoxAdapter(
          child: _buildCategoryFilter(categoriesAsync, selectedCategory),
        ),

        // Заголовок продуктов
        SliverToBoxAdapter(
          child: _buildProductsHeader(productsAsync, selectedCategory),
        ),

        // Сетка продуктов
        _buildProductsGrid(productsAsync, selectedCategory),
      ],
    );
  }

  Widget _buildCategoryFilter(
    AsyncValue<List<dynamic>> categoriesAsync,
    String selectedCategory,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Фильтр:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 8),
          categoriesAsync.when(
            loading: () => Container(
              width: 150,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(child: Text('Загрузка...')),
                  Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
            error: (error, stack) => Container(
              width: 150,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(child: Text('Ошибка')),
                  Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
            data: (categories) {
              final categoryNames = ['Все', ...categories.map((c) => c['name'].toString())];
              
              return PopupMenuButton<String>(
                onSelected: (String newValue) {
                  ref.read(selectedCategoryProvider.notifier).state = newValue;
                },
                surfaceTintColor: Colors.transparent,
                constraints: const BoxConstraints(
                  minWidth: 150,
                  maxWidth: 150,
                ),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.green, width: 1.0),
                  borderRadius: BorderRadius.circular(8),
                ),
                itemBuilder: (BuildContext context) => categoryNames.map((String category) {
                  return PopupMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedCategory,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsHeader(
    AsyncValue<List<dynamic>> productsAsync,
    String selectedCategory,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Все продукты',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          productsAsync.when(
            loading: () => const Text('... товаров'),
            error: (error, stack) => const Text('0 товаров'),
            data: (products) {
              final filteredProducts = selectedCategory == 'Все'
                  ? products
                  : products.where((p) => p['category']['name'] == selectedCategory).toList();
              
              return Text(
                '${filteredProducts.length} товаров',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(
    AsyncValue<List<dynamic>> productsAsync,
    String selectedCategory,
  ) {
    return productsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки товаров',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(productsProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
      data: (products) {
        final filteredProducts = selectedCategory == 'Все'
            ? products
            : products.where((p) => p['category']['name'] == selectedCategory).toList();

        if (filteredProducts.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Товары не найдены'),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = filteredProducts[index];
                return _buildProductCard(product);
              },
              childCount: filteredProducts.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productId = product['id'] as int;
    final quantity = ref.watch(cartProvider)[productId] ?? 0;
    final isFavorite = ref.watch(favoritesProvider)[productId] ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onProductTap(product),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Изображение продукта
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    child: product['image_url'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'http://10.0.2.2:8000${product['image_url']}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.fastfood,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.fastfood,
                            size: 40,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Название и цена
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product['name'],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${product['price']} ₽',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Кнопки добавления в корзину
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    height: 35,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove,
                            size: 18,
                            color: quantity > 0 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          onPressed: quantity > 0 ? () {
                            _updateCartQuantity(productId, quantity - 1);
                          } : null,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        
                        Container(
                          width: 30,
                          alignment: Alignment.center,
                          child: Text(
                            quantity.toString(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        
                        IconButton(
                          icon: Icon(
                            Icons.add,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            _addToCart(productId);
                          },
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Кнопка избранного в правом верхнем углу
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey[600],
                  size: 20,
                ),
                onPressed: () {
                  _toggleFavorite(productId, !isFavorite);
                },
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion, BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/promotion/${promotion['id']}');
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              promotion['color'].withOpacity(0.2),
              promotion['color'].withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: promotion['color'].withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Icon(
                Icons.local_offer_outlined,
                size: 80,
                color: promotion['color'].withOpacity(0.2),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  promotion['title'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: promotion['color'],
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onProductTap(Map<String, dynamic> product) {
    context.push('/product/${product['id']}', extra: product);
  }

  Future<void> _addToCart(int productId) async {
    try {
      await ref.read(cartProvider.notifier).addToCart(productId);
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка добавления в корзину: $e')),
      );
    }
  }

  Future<void> _updateCartQuantity(int productId, int quantity) async {
    try {
      await ref.read(cartProvider.notifier).updateQuantity(productId, quantity);
    } catch (e) {
      print('Error updating cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления корзины: $e')),
      );
    }
  }

  Future<void> _toggleFavorite(int productId, bool isFavorite) async {
    try {
      await ref.read(favoritesProvider.notifier).toggleFavorite(productId, isFavorite);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFavorite ? 'Добавлено в избранное' : 'Удалено из избранного'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}