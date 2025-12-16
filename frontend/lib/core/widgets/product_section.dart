import 'package:client/domain/entities/cart_item_entity.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/core/widgets/quantity_controls.dart';
import 'package:client/features/main/bloc/main_bloc.dart';
import 'package:client/features/main/bloc/cart_bloc.dart';
import 'package:client/features/main/bloc/favorites_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/core/widgets/product_modal.dart';
import 'package:client/features/product/screens/product_screen.dart';

class ProductGridSection extends StatefulWidget {
  const ProductGridSection({super.key});

  @override
  State<ProductGridSection> createState() => _ProductGridSectionState();
}

class _ProductGridSectionState extends State<ProductGridSection> {
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<MainBloc>().add(SearchQueryChanged(_searchController.text));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<MainBloc>().add(const SearchQueryChanged(''));
  }

  void _loadMoreProducts() {
    context.read<MainBloc>().add(const MoreProductsLoaded());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainBloc, MainState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildProductsHeader(state, context),
            _buildProductsGrid(state, context),
          ],
        );
      },
    );
  }

  Widget _buildProductsHeader(MainState state, BuildContext context) {
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
              if (state.productsStatus == MainStatus.loading && state.products.isEmpty)
                const Text('... товаров')
              else if (state.productsStatus == MainStatus.error && state.products.isEmpty)
                const Text('0 товаров')
              else
                Text(
                  _getProductsCountText(state.products.length),
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
                  if (state.searchQuery.isNotEmpty)
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

  Widget _buildProductsGrid(MainState state, BuildContext context) {
    if (state.productsStatus == MainStatus.loading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.productsStatus == MainStatus.error && state.products.isEmpty) {
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
              state.productsError ?? 'Неизвестная ошибка',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<MainBloc>().add(const ProductsLoaded()),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.products.isEmpty) {
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
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200, 
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: state.products.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final product = state.products[index]; // Теперь это Product, а не dynamic
            return ProductCard(product: product); // Передаем Product
          },
        ),
        
        if (state.productsStatus == MainStatus.loadingMore)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        
        if (state.hasMoreProducts && state.productsStatus != MainStatus.loadingMore && state.products.isNotEmpty)
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
        
        if (!state.hasMoreProducts && state.products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Товары кончились :(',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductEntity product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final productId = product.id;

    // Получаем информацию о избранном из FavoritesBloc
    final isFavorite = context.select<FavoritesBloc, bool>((bloc) {
      return bloc.state.favorites.any((favItem) => favItem.product.id == productId);
    });

    // Получаем количество из корзины
    final cartItem = context.select<CartBloc, CartItemEntity?>((bloc) {
      try {
        return bloc.state.cartItems.firstWhere(
          (item) => item.product.id == productId,
        );
      } catch (e) {
        return null;
      }
    });

    final quantity = cartItem?.quantity ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onProductTap(context),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.fastfood,
                            size: 40,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
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
                        '${product.price} ₽',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Кнопки управления количеством
                  QuantityControls(
                    productId: productId,
                    quantity: quantity,
                    onQuantityChanged: (productId, newQuantity) {
                      final cartBloc = context.read<CartBloc>();
                      
                      if (newQuantity == 0) {
                        // Удаляем из корзины
                        cartBloc.add(CartItemRemoved(productId));
                      } else if (cartItem != null) {
                        // Обновляем существующий товар
                        final updatedCartItem = cartItem.copyWith(
                          quantity: newQuantity,
                          product: product, // Сохраняем продукт
                        );
                        cartBloc.add(CartItemUpdated(updatedCartItem));
                      } else {
                        // Добавляем новый товар
                        final newCartItem = _createCartItem(newQuantity);
                        cartBloc.add(CartItemAdded(newCartItem));
                      }
                    },
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
                  final favoritesBloc = context.read<FavoritesBloc>();
                  final newFavoriteState = !isFavorite;
                  
                  favoritesBloc.add(FavoriteToggled(
                    productId: productId,
                    isFavorite: newFavoriteState,
                    product: newFavoriteState ? product : null,
                  ));
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

  void _onProductTap(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 600) {
      ScreenToModal.show(
        context: context, 
        child: ProductScreen(product: product)
      );
    } else {
      context.push('/product/${product.id}', extra: product);
    }
  }

  CartItemEntity _createCartItem(int quantity) {
    return CartItemEntity(
      product: product,
      quantity: quantity,
      addedAt: DateTime.now(),
    );
  }
}