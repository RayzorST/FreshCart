import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/api/client.dart';
import 'package:client/core/providers/cart_provider.dart';
import 'package:client/core/widgets/bottom_navigation_bar.dart';
import 'package:client/core/widgets/quantity_controls.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  List<dynamic> _cartItems = [];
  double _totalAmount = 0.0;
  double _originalTotalAmount = 0.0;
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

      if (cartData['items'] != null && cartData['items'] is List) {
        final items = await _enrichCartItems(cartData['items']);
        setState(() {
          _cartItems = items;
          _totalAmount = (cartData['final_price'] as num?)?.toDouble() ?? 0.0;
          _originalTotalAmount = (cartData['total_price'] as num?)?.toDouble() ?? _totalAmount;
        });
      } else {
        setState(() {
          _cartItems = [];
          _totalAmount = 0.0;
          _originalTotalAmount = 0.0;
        });
      }
    } catch (e) {
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
        
        Map<String, dynamic>? foundProduct;
        for (var product in products) {
          final productMap = _convertToSafeMap(product);
          if (productMap['id'] == productId) {
            foundProduct = productMap;
            break;
          }
        }

        final originalPrice = foundProduct?['price'] ?? itemMap['price'] ?? 0.0;
        final discountedPrice = itemMap['discount_price'] ?? itemMap['display_price'] ?? originalPrice;
        final hasDiscount = discountedPrice < originalPrice;
        final appliedPromotions = itemMap['applied_promotions'] ?? [];

        enrichedItems.add({
          ...itemMap,
          'product': foundProduct,
          'display_price': discountedPrice,
          'original_price': originalPrice,
          'has_discount': hasDiscount,
          'discount_amount': originalPrice - discountedPrice,
          'applied_promotions': appliedPromotions,
        });
      }

      return enrichedItems;
    } catch (e) {
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
      if (quantity == 0) {
        await ref.read(cartProvider.notifier).removeFromCart(productId);
      } else {
        await ref.read(cartProvider.notifier).updateQuantity(productId, quantity);
      }
      //await Future.delayed(const Duration(milliseconds: 100));
      await _loadCart();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления: $e')),
      );
    }
  }

  void _navigateToPromotionScreen(List<dynamic> appliedPromotions, BuildContext context) {
    if (appliedPromotions.isEmpty) return;

    if (appliedPromotions.length > 1) {
      _showPromotionsDialog(appliedPromotions, 'Примененные акции');
    } else {
      final promotion = appliedPromotions.first;
      print(promotion);
      context.push('/promotion/${promotion['promotion_id']}', extra: promotion);
    }
  }

  void _showPromotionsDialog(List<dynamic> promotions, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promotion = _convertToSafeMap(promotions[index]);
              return ListTile(
                leading: Icon(
                  Icons.local_offer_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(promotion['name'] ?? 'Акция'),
                subtitle: promotion['description'] != null 
                    ? Text(promotion['description'])
                    : null,
                trailing: promotion['value'] != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          promotion['promotion_type'] == 'percentage' 
                              ? '-${promotion['value']}%'
                              : '-${promotion['value']}₽',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context); // Закрываем диалог
                  context.push('/promotion', extra: promotion);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
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

      for (var item in _cartItems) {
        final itemMap = _convertToSafeMap(item);
        await ref.read(cartProvider.notifier).removeFromCart(itemMap['product_id']);
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
        title: Text(
          'Корзина',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _cartItems.length.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
    final appliedPromotions = item['applied_promotions'] ?? [];

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
              child: _buildProductInfo(product, price, productId, quantity, appliedPromotions),
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

  Widget _buildProductInfo(Map<String, dynamic> product, double price, int productId, int quantity, List<dynamic> appliedPromotions) {
    final item = _convertToSafeMap(product);
    final hasDiscount = item['price'] != price;
    final originalPrice = (item['price'] as num?)?.toDouble() ?? price;
    final discountedPrice = price;
    final hasPromotions = appliedPromotions.isNotEmpty;

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
            ),
            if (hasPromotions) 
              IconButton(
                icon: Icon(
                  Icons.local_offer_outlined,
                  size: 20,
                  color: Colors.orange,
                ),
                onPressed: () => _navigateToPromotionScreen(appliedPromotions, context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            _buildDeleteButton(productId),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    if (hasDiscount) ...[
                      Text(
                        '$originalPrice ₽',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '$discountedPrice ₽',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: hasDiscount ? Colors.green : Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            QuantityControls(
              productId: productId,
              quantity: quantity,
              onQuantityChanged: _updateCartItem,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeleteButton(int productId) {
    return IconButton(
      icon: const Icon(
        Icons.delete_outline,
        color: Colors.red,
        size: 22,
      ),
      onPressed: () => _updateCartItem(productId, 0),
      padding: const EdgeInsets.all(4),
    );
  }

  Widget _buildOrderSummary() {
    final hasDiscount = _originalTotalAmount > _totalAmount;
    final totalSavings = _originalTotalAmount - _totalAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasDiscount) ...[
            _buildSummaryRow('Сумма без скидок', '${_originalTotalAmount.toStringAsFixed(2)} ₽'),
            _buildSummaryRow('Скидка', '-${totalSavings.toStringAsFixed(2)} ₽', isDiscount: true),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
          ],
          _buildSummaryRow(
            'Итого к оплате',
            '${_totalAmount.toStringAsFixed(2)} ₽',
            isTotal: true,
            isDiscounted: hasDiscount,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreatingOrder ? null : _createOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCreatingOrder
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      'Оформить заказ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isTotal = false, bool isDiscounted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDiscount ? Colors.green : Colors.grey[700],
                  fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDiscount 
                      ? Colors.green
                      : isDiscounted && isTotal
                          ? Colors.green
                          : Colors.grey[700],
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : null,
                ),
          ),
        ],
      ),
    );
  }
}