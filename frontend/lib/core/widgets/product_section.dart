import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/providers/products_provider.dart';
import 'package:client/core/providers/cart_provider.dart';
import 'package:client/core/providers/favorites_provider.dart';
import 'package:client/core/widgets/quantity_controls.dart';
import 'package:client/api/client.dart';
import 'package:go_router/go_router.dart';

class ProductGridSection extends ConsumerWidget {
  final String selectedCategory;

  String _getProductsCountText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return '$count товар';
    } else if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return '$count товара';
    } else {
      return '$count товаров';
    }
  }
  const ProductGridSection({
    super.key,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Column(
      children: [
        _buildProductsHeader(productsAsync, selectedCategory, context),
        _buildProductsGrid(productsAsync, selectedCategory, context, ref),
      ],
    );
  }

  Widget _buildProductsHeader(
    AsyncValue<List<dynamic>> productsAsync,
    String selectedCategory,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Все продукты',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          productsAsync.when(
            loading: () => const Text('... товаров'),
            error: (error, stack) => const Text('0 товаров'),
            data: (products) {
              final filteredProducts = selectedCategory == 'Все'
                  ? products
                  : products.where((p) => p['category']['name'] == selectedCategory).toList();
              
              return Text(
                _getProductsCountText(filteredProducts.length),
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
    BuildContext context,
    WidgetRef ref,
  ) {
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
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
      data: (products) {
        final filteredProducts = selectedCategory == 'Все'
            ? products
            : products.where((p) => p['category']['name'] == selectedCategory).toList();

        if (filteredProducts.isEmpty) {
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

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: filteredProducts.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return _buildProductCard(product, context, ref);
          },
        );
      },
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