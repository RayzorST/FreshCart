import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:client/api/client.dart';
import 'package:client/core/providers/cart_provider.dart';
import 'package:client/core/widgets/navigation_bar.dart';
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

  String _getProductsCountText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return '$count товар';
    } else if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return '$count товара';
    } else {
      return '$count товаров';
    }
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
    final previousQuantity = _getCurrentQuantity(productId);
    try {
      // Сохраняем предыдущее значение для отката
      
      // Оптимистичное обновление UI
      setState(() {
        _updateLocalQuantity(productId, quantity);
        _updateTotalAmount();
      });

      if (quantity == 0) {
        await ref.read(cartProvider.notifier).removeFromCart(productId);
      } else {
        await ref.read(cartProvider.notifier).updateQuantity(productId, quantity);
      }

    } catch (e) {
      // Откатываем изменения при ошибке
      setState(() {
        _updateLocalQuantity(productId, previousQuantity);
        _updateTotalAmount();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обновления: $e'),
          action: SnackBarAction(
            label: 'Повторить',
            onPressed: () => _updateCartItem(productId, quantity),
          ),
        ),
      );
    }
  }

  void _updateLocalQuantity(int productId, int quantity) {
    final index = _cartItems.indexWhere(
      (item) => _convertToSafeMap(item)['product_id'] == productId
    );
    
    if (index != -1) {
      final item = _convertToSafeMap(_cartItems[index]);
      if (quantity == 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = {...item, 'quantity': quantity};
      }
    }
  }

  int _getCurrentQuantity(int productId) {
    final index = _cartItems.indexWhere(
      (item) => _convertToSafeMap(item)['product_id'] == productId
    );
    if (index != -1) {
      return (_convertToSafeMap(_cartItems[index])['quantity'] as num).toInt();
    }
    return 0;
  }

  void _updateTotalAmount() {
    double newTotal = 0.0;
    double newOriginalTotal = 0.0;
    
    for (var item in _cartItems) {
      final itemMap = _convertToSafeMap(item);
      final quantity = (itemMap['quantity'] as num).toInt();
      final price = (itemMap['display_price'] as num).toDouble();
      final originalPrice = (itemMap['original_price'] as num?)?.toDouble() ?? price;
      
      newTotal += price * quantity;
      newOriginalTotal += originalPrice * quantity;
    }
    
    setState(() {
      _totalAmount = newTotal;
      _originalTotalAmount = newOriginalTotal;
    });
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

    final selectedAddress = ref.read(selectedAddressProvider);
    if (selectedAddress == null) {
      _showAddAddressDialog();
      return;
    }

    setState(() => _isCreatingOrder = true);
    
    try {
      final orderItems = _cartItems.map<Map<String, dynamic>>((item) {
        final itemMap = _convertToSafeMap(item);
        return {
          'product_id': itemMap['product_id'],
          'quantity': itemMap['quantity'],
          'price': (itemMap['display_price'] as num).toDouble(),
        };
      }).toList();
      
      await ApiClient.createOrder(
        selectedAddress['address_line'],
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold,),
        ),
        actions: [
          if (_cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_getProductsCountText(_cartItems.length)}",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
          
          FilledButton.icon(
            onPressed: () => ref.read(currentIndexProvider.notifier).state = 0,
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Перейти к покупкам'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartWithItems() {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12, top: 12),
      children: [
        _buildAddressSelector(),
        ..._cartItems.map((item) {
          final itemMap = _convertToSafeMap(item);
          return _buildCartItem(itemMap);
        }).toList(),
        
        _buildOrderSummary(),
        
        const SizedBox(height: 20),
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

    return Card(
      margin: const EdgeInsets.all(0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок раздела
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Детали заказа',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Разделитель
            Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              height: 1,
            ),
            const SizedBox(height: 16),
            
            // Список стоимостей
            Column(
              children: [
                if (hasDiscount) ...[
                  _buildSummaryRow(
                    'Сумма товаров',
                    '${_originalTotalAmount.toStringAsFixed(2)} ₽',
                    icon: Icons.shopping_cart_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Ваша скидка',
                    '-${totalSavings.toStringAsFixed(2)} ₽',
                    valueColor: Colors.green,
                    icon: Icons.discount_outlined,
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildSummaryRow(
                  'Итого к оплате',
                  '${_totalAmount.toStringAsFixed(2)} ₽',
                  isTotal: true,
                  valueColor: Theme.of(context).colorScheme.primary,
                  icon: Icons.shopping_cart_outlined,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isCreatingOrder ? null : _createOrder,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                ),
                child: _isCreatingOrder
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Оформляем...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Оформить заказ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: valueColor ?? Colors.grey[700],
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? Colors.grey[700],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 17 : null,
              ),
        ),
      ],
    );
  }

  Widget _buildAddressSelector() {
    final addressesAsync = ref.watch(addressesListProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final isExpanded = ref.watch(isAddressExpandedProvider);

    return addressesAsync.when(
      loading: () => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 12),
              Text('Загрузка адресов...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ошибка загрузки адресов',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (addresses) {
        if (addresses.isEmpty) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Адрес доставки',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Адрес не указан',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push('/addresses'),
                    child: Text('Добавить адрес'),
                  ),
                ],
              ),
            ),
          );
        }

        if (selectedAddress == null && addresses.isNotEmpty) {
          final defaultAddress = addresses.firstWhere(
            (addr) => addr['is_default'] == true,
            orElse: () => addresses.first,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedAddressProvider.notifier).state = defaultAddress;
          });
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    ref.read(isAddressExpandedProvider.notifier).state = !isExpanded;
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Адрес доставки',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if (selectedAddress != null) ...[
                              SizedBox(height: 4),
                              Text(
                                selectedAddress['address_line'] ?? 'Адрес не указан',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),

                if (isExpanded) ...[
                  SizedBox(height: 16),
                  ...addresses.map((address) {
                    final isSelected = selectedAddress?['id'] == address['id'];
                    return _buildAddressItem(address, isSelected);
                  }).toList(),
                  
                  SizedBox(height: 12),
                  Divider(height: 1),
                  SizedBox(height: 12),
                  
                  TextButton.icon(
                    onPressed: () => context.push('/addresses'),
                    icon: Icon(Icons.add, size: 18),
                    label: Text('Добавить новый адрес'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressItem(Map<String, dynamic> address, bool isSelected) {
    return Card(
      elevation: 0,
      color: isSelected 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        title: Text(
          address['address_line'] ?? 'Адрес не указан',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
        subtitle: address['apartment'] != null 
            ? Text('Кв. ${address['apartment']}')
            : null,
        trailing: address['is_default'] == true
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'По умолчанию',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
        onTap: () {
          ref.read(selectedAddressProvider.notifier).state = address;
          ref.read(isAddressExpandedProvider.notifier).state = false;
        },
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}