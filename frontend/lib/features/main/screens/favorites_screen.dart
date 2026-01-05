import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/main/bloc/favorites_bloc.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/domain/entities/cart_item_entity.dart';
import 'package:client/domain/entities/favorite_item_entity.dart';
import 'package:client/features/main/bloc/cart_bloc.dart';
import 'package:client/features/product/screens/product_screen.dart';
import 'package:client/core/widgets/screen_modal.dart';
import 'package:client/core/widgets/quantity_controls.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesBloc>().add(const FavoritesLoaded());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<FavoritesBloc>().add(
      FavoritesSearchChanged(_searchController.text),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<FavoritesBloc>().add(const FavoritesSearchCleared());
  }

  String _getProductsCountText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return '$count товар';
    } else if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return '$count товара';
    } else {
      return '$count товаров';
    }
  }

  void _removeFromFavorites(int productId) {
    context.read<FavoritesBloc>().add(FavoriteRemoved(productId));
    
    AppSnackbar.showInfo(
      context: context, 
      message: 'Товар удален из избранного',
    );
  }

  void _onProductTap(ProductEntity product) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 600) {
      ScreenToModal.show(context: context, child: ProductScreen(product: product));
    } else {
      context.push('/product/${product.id}', extra: product);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Избранное',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          BlocBuilder<FavoritesBloc, FavoritesState>(
            builder: (context, state) {
              final displayCount = state.isSearching 
                  ? state.filteredFavorites.length
                  : state.favorites.length;
              
              if (displayCount > 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getProductsCountText(displayCount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<FavoritesBloc, FavoritesState>(
        listener: (context, state) {
          if (state.error != null) {
            AppSnackbar.showError(context: context, message: state.error!);
          }
        },
        builder: (context, state) {
          if (state.status == FavoritesStatus.error && state.favorites.isEmpty) {
            return _buildErrorState(state.error!);
          }

          if (state.favorites.isEmpty) {
            return _buildEmptyState();
          }
          
          if (state.status == FavoritesStatus.initial || 
              state.status == FavoritesStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildFavoritesContent(context, state);
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.read<FavoritesBloc>().add(const FavoritesLoaded()),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Пока ничего нет в избранном',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              context.go('/');
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Перейти к покупкам'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesContent(BuildContext context, FavoritesState state) {
    final displayFavorites = state.isSearching 
        ? state.filteredFavorites 
        : state.favorites;

    return Column(
      children: [
        // Поиск
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
                        hintText: 'Поиск в избранном...',
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
                  if (_searchController.text.isNotEmpty)
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

        if (state.isSearching && displayFavorites.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ничего не найдено',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Попробуйте изменить запрос',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return _buildFavoritesGrid(context, displayFavorites);
                } else {
                  return _buildFavoritesList(context, displayFavorites);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFavoritesList(BuildContext context, List<FavoriteItemEntity> favorites) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
      itemCount: favorites.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return _buildFavoriteItem(context, favorite);
      },
    );
  }

  Widget _buildFavoritesGrid(BuildContext context, List<FavoriteItemEntity> favorites) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400, 
        mainAxisExtent: 150, 
        mainAxisSpacing: 12, 
        crossAxisSpacing: 12, 
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return _buildFavoriteItem(context, favorite);
      },
    );
  }

  Widget _buildFavoriteItem(BuildContext context, FavoriteItemEntity favorite) {
    final product = favorite.product;

    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(context, product),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProductInfo(context, product),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context, ProductEntity product) {
    return GestureDetector(
      onTap: () => _onProductTap(product),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: _buildProductImageContent(context, product),
      ),
    );
  }

  Widget _buildProductImageContent(BuildContext context, ProductEntity product) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        product.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.fastfood,
              size: 30,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context, ProductEntity product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _onProductTap(product),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.category != null)
                      Text(
                        product.category!.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                  ],
                ),
              ),
            ),
            _buildFavoriteButton(product.id),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${product.price} ₽',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            // Ограничиваем ширину QuantityControls
            SizedBox(
              width: 120, // Фиксированная ширина
              child: BlocBuilder<CartBloc, CartState>(
                builder: (context, cartState) {
                  CartItemEntity? cartItem;
                  try {
                    cartItem = cartState.cartItems.firstWhere(
                      (item) => item.product.id == product.id,
                    );
                  } catch (e) {
                    cartItem = null;
                  }
                  
                  final quantity = cartItem?.quantity ?? 0;
                  
                  return QuantityControls(
                    productId: product.id,
                    quantity: quantity,
                    onQuantityChanged: (productId, newQuantity) {
                      if (newQuantity == 0) {
                        context.read<CartBloc>().add(CartItemRemoved(productId));
                      } else {
                        context.read<CartBloc>().add(CartItemUpdated(productId, newQuantity));
                      }
                    },
                    fullWidth: false, // Не fullWidth!
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFavoriteButton(int productId) {
    return IconButton(
      icon: const Icon(
        Icons.favorite,
        color: Colors.red,
        size: 22,
      ),
      onPressed: () => _removeFromFavorites(productId),
      padding: const EdgeInsets.all(4),
    );
  }
}