import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/api/client.dart';
import 'package:client/core/providers/cart_provider.dart';
import 'package:client/core/widgets/bottom_navigation_bar.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  List<dynamic> _cartItems = [];
  double _totalAmount = 0.0;
  bool _isLoading = true;
  bool _isCreatingOrder = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final cartData = await ApiClient.getCart();
      print('Cart data received: $cartData');

      if (cartData['items'] != null && cartData['items'] is List) {
        final items = await _enrichCartItems(cartData['items']);
        setState(() {
          _cartItems = items;
          _totalAmount = (cartData['final_price'] as num?)?.toDouble() ?? 0.0;
        });
      } else {
        setState(() {
          _cartItems = [];
          _totalAmount = 0.0;
        });
      }
    } catch (e) {
      print('Error loading cart: $e');
      setState(() {
        _error = 'Ошибка загрузки корзины: $e';
        _cartItems = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<dynamic>> _enrichCartItems(List<dynamic> items) async {
    if (items.isEmpty) return [];

    try {
      final products = await ApiClient.getProducts();
      final enrichedItems = <dynamic>[];

      for (var item in items) {
        final itemMap = _convertToSafeMap(item);
        final productId = itemMap['product_id'];
        
        // Безопасно ищем продукт
        Map<String, dynamic>? foundProduct;
        for (var product in products) {
          final productMap = _convertToSafeMap(product);
          if (productMap['id'] == productId) {
            foundProduct = productMap;
            break;
          }
        }

        enrichedItems.add({
          ...itemMap,
          'product': foundProduct,
          'display_price': foundProduct?['price'] ?? itemMap['price'] ?? 0.0,
        });
      }

      return enrichedItems;
    } catch (e) {
      print('Error enriching cart items: $e');
      return items.map((item) => _convertToSafeMap(item)).toList();
    }
  }

  Map<String, dynamic> _convertToSafeMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        return Map<String, dynamic>.from(data);
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  Future<void> _updateCartItem(int productId, int quantity) async {
    try {
      await ref.read(cartProvider.notifier).updateQuantity(productId, quantity);
      await Future.delayed(const Duration(milliseconds: 100));
      await _loadCart();
    } catch (e) {
      print('Error updating cart item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления: $e')),
      );
    }
  }

  Future<void> _createOrder() async {
    if (_cartItems.isEmpty) return;

    setState(() => _isCreatingOrder = true);
    
    try {
      final addresses = await ApiClient.getAddresses();
      
      if (addresses.isEmpty) {
        _showAddAddressDialog();
        return;
      }

      final defaultAddress = addresses.firstWhere(
        (addr) => addr['is_default'] == true,
        orElse: () => addresses.first,
      );

      final orderItems = _cartItems.map<Map<String, dynamic>>((item) {
        final itemMap = _convertToSafeMap(item);
        return {
          'product_id': itemMap['product_id'],
          'quantity': itemMap['quantity'],
          'price': (itemMap['display_price'] as num).toDouble(),
        };
      }).toList();

      print('Creating order with items: $orderItems');
      
      await ApiClient.createOrder(
        defaultAddress['address_line'],
        '',
        orderItems,
      );

      // Очищаем корзину через провайдер
      for (var item in _cartItems) {
        final itemMap = _convertToSafeMap(item);
        await ref.read(cartProvider.notifier).updateQuantity(itemMap['product_id'], 0);
      }

      await _loadCart();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ успешно создан!')),
      );

      context.push('/order-history');
      
    } catch (e) {
      print('Error creating order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка создания заказа: $e')),
      );
    } finally {
      setState(() => _isCreatingOrder = false);
    }
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавьте адрес доставки'),
        content: const Text('Для оформления заказа необходимо добавить адрес доставки.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/addresses');
            },
            child: const Text('Добавить адрес'),
          ),
        ],
      ),
    );
  }

  void _onProductTap(dynamic product) {
    final safeProduct = _convertToSafeMap(product);
    if (safeProduct['id'] != null) {
      context.push('/product/${safeProduct['id']}', extra: safeProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        actions: [
          if (_cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _cartItems.length.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_cartItems.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCartWithItems();
  }

  Widget _buildErrorState() {
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
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadCart,
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
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Корзина пуста',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавляйте товары в корзину,\nчтобы сделать заказ',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          
          ElevatedButton.icon(
            onPressed: () => ref.read(currentIndexProvider.notifier).state = 0,
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Перейти к покупкам'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartWithItems() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              final itemMap = _convertToSafeMap(item);
              return _buildCartItem(itemMap);
            },
          ),
        ),
        _buildOrderSummary(),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final product = _convertToSafeMap(item['product']);
    final productId = item['product_id'];
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    final price = (item['display_price'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
            _buildDeleteButton(productId),
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
        'http://10.0.2.2:8000$imageUrl',
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
        GestureDetector(
          onTap: () => _onProductTap(product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product['name'] ?? 'Товар #$productId',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$price ₽',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            _buildQuantityControls(productId, quantity),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityControls(int productId, int quantity) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      height: 32,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.remove,
              size: 16,
              color: quantity > 1 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            onPressed: quantity > 1 ? () {
              _updateCartItem(productId, quantity - 1);
            } : null,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
          Container(
            width: 24,
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              _updateCartItem(productId, quantity + 1);
            },
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(int productId) {
    return IconButton(
      icon: const Icon(
        Icons.delete_outline,
        color: Colors.red,
        size: 20,
      ),
      onPressed: () => _updateCartItem(productId, 0),
      padding: const EdgeInsets.all(4),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Итого:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '$_totalAmount ₽',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreatingOrder ? null : _createOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCreatingOrder
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Оформить заказ',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}