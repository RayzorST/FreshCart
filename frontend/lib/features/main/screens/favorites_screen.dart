import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/api/client.dart';
import 'package:client/core/providers/favorites_provider.dart';
import 'package:client/core/providers/cart_provider.dart';
import 'package:client/core/widgets/quantity_controls.dart';
import 'package:client/core/widgets/navigation_bar.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'dart:async';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<dynamic> _favoritesProducts = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadFavoritesWithProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoritesWithProducts() async {
    try {
      setState(() => _isLoading = true);
      final favorites = await ApiClient.getFavorites();
      setState(() {
        _favoritesProducts = favorites;
        _filteredProducts = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    ref.read(favoritesSearchQueryProvider.notifier).state = query;
    
    // Отменяем предыдущий таймер
    _searchDebounce?.cancel();
    
    if (query.isEmpty) {
      // Если запрос пустой, сразу показываем все товары
      setState(() {
        _filteredProducts = _favoritesProducts;
        _isSearching = false;
      });
    } else {
      // Сначала делаем быстрый локальный поиск
      _performLocalSearch(query);
      
      // Затем через debounce делаем серверный поиск (если нужно)
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        _performServerSearch(query);
      });
    }
  }

  void _performLocalSearch(String query) {
    setState(() {
      _filteredProducts = _favoritesProducts.where((favorite) {
        final product = favorite['product'];
        final productName = product['name']?.toString().toLowerCase() ?? '';
        return productName.contains(query.toLowerCase());
      }).toList();
      _isSearching = true;
    });
  }

  Future<void> _performServerSearch(String query) async {
    try {
      // Только если локальный поиск не дал результатов или мы хотим актуальные данные
      if (_filteredProducts.isEmpty || query.length >= 3) {
        final searchResults = await ApiClient.getFavorites(search: query);
        setState(() {
          _filteredProducts = searchResults;
          _isSearching = true;
        });
      }
    } catch (e) {
      // Игнорируем ошибки серверного поиска, оставляем локальные результаты
      print('Server search error: $e');
    }
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    ref.read(favoritesSearchQueryProvider.notifier).state = '';
    setState(() {
      _filteredProducts = _favoritesProducts;
      _isSearching = false;
    });
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

  Future<void> _removeFromFavorites(int productId) async {
    try {
      await ref.read(favoritesProvider.notifier).toggleFavorite(productId, false);
      
      setState(() {
        _favoritesProducts.removeWhere((fav) => fav['product_id'] == productId);
        _filteredProducts.removeWhere((fav) => fav['product_id'] == productId);
      });
      
      AppSnackbar.showInfo(context: context, message: 'Удалено из избранного');
    } catch (e) {
      AppSnackbar.showError(context: context, message: 'Ошибка');
    }
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
      AppSnackbar.showError(context: context, message: 'Ошибка обновления корзины');
    }
  }

  void _onProductTap(Map<String, dynamic> product) {
    context.push('/product/${product['id']}', extra: product);
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
          if (_favoritesProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isSearching 
                      ? "${_getProductsCountText(_filteredProducts.length)}"
                      : "${_getProductsCountText(_favoritesProducts.length)}",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoritesProducts.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(),
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
          const SizedBox(height: 8),
          Text(
            'Добавляйте товары в избранное,\nчтобы они были всегда под рукой',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => ref.read(currentIndexProvider.notifier).state = 0,
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Перейти к покупкам'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Column(
      children: [
        // Поле поиска
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

        if (_isSearching && _filteredProducts.isEmpty)
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
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              itemCount: _filteredProducts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final favorite = _filteredProducts[index];
                final product = favorite['product'];
                final productId = product['id'] as int;
                final quantity = ref.watch(cartProvider)[productId] ?? 0;
                
                return _buildFavoriteItem(product, quantity);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> product, int quantity) {
    final productId = product['id'] as int;
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;

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
            _buildProductImage(product),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProductInfo(product, price, productId, quantity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => _onProductTap(product),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: _buildProductImageContent(product),
      ),
    );
  }

  Widget _buildProductImageContent(Map<String, dynamic> product) {
    final imageUrl = product['image_url'];
    if (imageUrl == null || imageUrl.toString().isEmpty) {
      return Icon(
        Icons.fastfood,
        size: 30,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        '${ApiClient.baseUrl}/images/products/${product['id']}/image',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.fastfood,
            size: 30,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
        },
      ),
    );
  }

  Widget _buildProductInfo(Map<String, dynamic> product, double price, int productId, int quantity) {
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
                      product['name'] ?? 'Товар #$productId',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['category']?['name'] ?? 'Без категории',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            _buildFavoriteButton(productId),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$price ₽',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            QuantityControls(
              productId: productId,
              quantity: quantity,
              onQuantityChanged: _updateCartQuantity,
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