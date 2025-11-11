import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/providers/products_provider.dart';
import 'package:client/core/providers/cart_provider.dart';
import 'package:client/core/providers/favorites_provider.dart';
import 'package:client/core/widgets/quantity_controls.dart';
import 'package:client/api/client.dart';
import 'package:go_router/go_router.dart';

class ProductGridSection extends ConsumerStatefulWidget {
  const ProductGridSection({
    super.key,
  });

  @override
  ConsumerState<ProductGridSection> createState() => _ProductGridSectionState();
}

class _ProductGridSectionState extends ConsumerState<ProductGridSection> {
  late TextEditingController _searchController;
  bool _isControllerInitialized = false;

  String _getProductsCountText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return '$count товар';
    } else if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return '$count товара';
    } else {
      return '$count товаров';
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isControllerInitialized) {
      final searchQuery = ref.read(searchQueryProvider);
      _searchController.text = searchQuery;
      _isControllerInitialized = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    ref.read(productsProvider.notifier).refresh();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(productsProvider.notifier).refresh();
  }

  void _loadMoreProducts() {
    print('🔄 Loading more products...');
    ref.read(productsProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);

    return Column(
      children: [
        _buildProductsHeader(productsState, context),
        _buildProductsGrid(productsState, context, ref),
      ],
    );
  }

  Widget _buildProductsHeader(
    ProductsState productsState,
    BuildContext context,
  ) {
    final searchQuery = ref.watch(searchQueryProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Все продукты',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (productsState.isLoading && productsState.products.isEmpty)
                const Text('... товаров')
              else if (productsState.error != null && productsState.products.isEmpty)
                const Text('0 товаров')
              else
                Text(
                  _getProductsCountText(productsState.products.length),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Поиск продуктов...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: _clearSearch,
                      padding: const EdgeInsets.all(8),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsGrid(
    ProductsState productsState,
    BuildContext context,
    WidgetRef ref,
  ) {
    final isLoadingMore = ref.watch(productsLoadingMoreProvider);
    final hasMore = ref.watch(hasMoreProductsProvider);

    if (productsState.isLoading && productsState.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productsState.error != null && productsState.products.isEmpty) {
      return Center(
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
              productsState.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(productsProvider.notifier).refresh(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (productsState.products.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Товары не найдены'),
          ],
        ),
      );
    }

    return Column(
      children: [
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: productsState.products.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final product = productsState.products[index];
            return _buildProductCard(product, context, ref);
          },
        ),
        
        // Индикатор загрузки следующих товаров
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        
        // Кнопка для загрузки следующих товаров
        if (hasMore && !isLoadingMore && productsState.products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _loadMoreProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Загрузить еще товары'),
            ),
          ),
        
        // Сообщение что товары закончились
        if (!hasMore && productsState.products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Все товары загружены',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, BuildContext context, WidgetRef ref) {
    final productId = product['id'] as int;
    final quantity = ref.watch(cartProvider)[productId] ?? 0;
    final isFavorite = ref.watch(favoritesProvider)[productId] ?? false;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onProductTap(product, context),
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
                    onQuantityChanged: (productId, quantity) => _updateCartQuantity(productId, quantity, context, ref),
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
                  _toggleFavorite(productId, !isFavorite, context, ref);
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

  void _onProductTap(Map<String, dynamic> product, BuildContext context) {
    context.push('/product/${product['id']}', extra: product);
  }

  Future<void> _updateCartQuantity(int productId, int quantity, BuildContext context, WidgetRef ref) async {
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

  Future<void> _toggleFavorite(int productId, bool isFavorite, BuildContext context, WidgetRef ref) async {
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