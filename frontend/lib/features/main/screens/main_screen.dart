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
import 'package:client/core/providers/promotions_provider.dart'; 
import 'package:client/api/client.dart';
import 'package:client/core/widgets/quantity_controls.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentIndexProvider);
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final promotionsAsync = ref.watch(promotionsListProvider);
    
    final List<Widget> screens = [
      _buildHomeScreen(productsAsync, categoriesAsync, selectedCategory, promotionsAsync),
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
    AsyncValue<List<dynamic>> promotionsAsync,
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

        SliverToBoxAdapter(
          child: _buildPromotionsSection(promotionsAsync),
        ),

        SliverToBoxAdapter(
          child: _buildCategoryFilter(categoriesAsync, selectedCategory),
        ),

        SliverToBoxAdapter(
          child: _buildProductsHeader(productsAsync, selectedCategory),
        ),

        _buildProductsGrid(productsAsync, selectedCategory),
      ],
    );
  }

  Widget _buildPromotionsSection(AsyncValue<List<dynamic>> promotionsAsync) {
    return SizedBox(
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
                promotionsAsync.when(
                  loading: () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '...',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  error: (error, stack) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '0',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  data: (promotions) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${promotions.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: promotionsAsync.when(
              loading: () => _buildPromotionsLoading(),
              error: (error, stack) => _buildPromotionsError(error),
              data: (promotions) => _buildPromotionsList(promotions),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsLoading() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildPromotionsError(Object error) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Container(
          width: 200,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[400], size: 24),
                const SizedBox(height: 8),
                Text(
                  'Ошибка загрузки',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[700],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionsList(List<dynamic> promotions) {
    if (promotions.isEmpty) {
      return ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, color: Colors.grey[400], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Нет активных акций',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: promotions.length,
      itemBuilder: (context, index) {
        final promotion = promotions[index];
        return _buildPromotionCard(promotion, context);
      },
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion, BuildContext context) {
    Color getPromotionColor(String promotionType) {
      switch (promotionType) {
        case 'percentage':
          return Colors.green;
        case 'fixed':
          return Colors.blue;
        case 'gift':
          return Colors.orange;
        default:
          return Colors.purple;
      }
    }

    String getPromotionDescription() {
      final type = promotion['promotion_type'];
      final value = promotion['value'];
      
      switch (type) {
        case 'percentage':
          return 'Скидка $value%';
        case 'fixed':
          final amount = (value / 100).toStringAsFixed(2);
          return 'Скидка $amount ₽';
        case 'gift':
          return 'Подарок';
        default:
          return promotion['name'];
      }
    }

    final color = getPromotionColor(promotion['promotion_type']);
    final description = getPromotionDescription();

    return GestureDetector(
      onTap: () {
        print(promotion);
        context.push('/promotion/${promotion['id']}', extra: promotion);
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
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
                color: color.withOpacity(0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    promotion['name'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color.withOpacity(0.8),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              childAspectRatio: 0.65,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    child: product['image_url'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              '${ApiClient.baseUrl}/images/products/${product['id']}/image',
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
                  
                  QuantityControls(
                    productId: productId,
                    quantity: quantity,
                    onQuantityChanged: _updateCartQuantity,
                    fullWidth: true,
                  ),
                ],
              ),
            ),

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

  void _onProductTap(Map<String, dynamic> product) {
    context.push('/product/${product['id']}', extra: product);
  }

  Future<void> _updateCartQuantity(int productId, int quantity) async {
    try {
      final currentQuantity = ref.read(cartProvider)[productId] ?? 0;
      
      if (currentQuantity == 0 && quantity > 0) {
        await ref.read(cartProvider.notifier).addToCart(productId);
      } else {
        await ref.read(cartProvider.notifier).updateQuantity(productId, quantity);
      }
    } catch (e) {
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