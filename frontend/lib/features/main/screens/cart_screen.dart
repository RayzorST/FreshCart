import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/api/client.dart';
import 'package:client/core/widgets/quantity_controls.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/main/bloc/cart_bloc.dart';
import 'package:client/core/widgets/product_modal.dart';
import 'package:client/features/product/screens/product_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<CartBloc>();
      bloc.add(const CartLoaded());
      bloc.add(const AddressesLoaded());
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

  void _navigateToPromotionScreen(List<dynamic> appliedPromotions, BuildContext context) {
    if (appliedPromotions.isEmpty) return;

    if (appliedPromotions.length > 1) {
      _showPromotionsDialog(appliedPromotions, 'Примененные акции');
    } else {
      final promotion = appliedPromotions.first;
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
                  Navigator.pop(context);
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

  void _createOrder(BuildContext context) {
    context.read<CartBloc>().add(const CartOrderCreated());
  }

  void _showAddAddressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавьте адрес доставки'),
        content: const Text('Для оформления заказа необходимо добавить адрес доставки.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CartBloc>().add(const AddressDialogDismissed());
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CartBloc>().add(const AddressDialogDismissed());
              context.push('/addresses');
            },
            child: const Text('Добавить адрес'),
          ),
        ],
      ),
    );
  }

  void _onProductTap(dynamic product, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 600) {
      ScreenToModal.show(context: context, child: ProductScreen(product: product));
    } else {
      context.push('/product/${product['id']}', extra: product);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Корзина',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state.cartItems.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getProductsCountText(state.cartItems.length),
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
      body: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          
          if (state.status == CartStatus.orderCreated) {
            AppSnackbar.showSuccess(context: context, message: 'Заказ успешно создан!');
            context.push('/order-history');
          }
          
          if (state.status == CartStatus.error && state.error != null) {
            AppSnackbar.showError(context: context, message: state.error!);
          }

          if (state.showAddressDialog) {
            _showAddAddressDialog(context);
          }
        },
        builder: (context, state) {
          return _buildBody(context, state);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CartState state) {
    if (state.status == CartStatus.initial || state.status == CartStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == CartStatus.error && state.cartItems.isEmpty) {
      return _buildErrorState(context, state.error!);
    }

    if (state.cartItems.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildCartWithItems(context, state);
  }

  Widget _buildErrorState(BuildContext context, String error) {
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
            onPressed: () => context.read<CartBloc>().add(const CartReloaded()),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            onPressed: () {
              
              
              if (context.canPop()) {
                context.pop();
              }
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Перейти к покупкам'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartWithItems(BuildContext context, CartState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        
        if (constraints.maxWidth > 900) {
          return _buildWideLayout(context, state);
        } else {
          return _buildNarrowLayout(context, state);
        }
      },
    );
  }

  Widget _buildWideLayout(BuildContext context, CartState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildAddressSelector(context, state),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildProductsGrid(context, state),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          
          SizedBox(
            width: 400,
            child: _buildOrderSummary(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context, CartState state) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12, top: 12),
      children: [
        _buildAddressSelector(context, state),
        ...state.cartItems.map((item) {
          final itemMap = _convertToSafeMap(item);
          return Column(
            children: [
              _buildCartItem(context, itemMap),
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
        _buildOrderSummary(context, state),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProductsGrid(BuildContext context, CartState state) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 500, 
        mainAxisExtent: 150, 
        mainAxisSpacing: 12, 
        crossAxisSpacing: 12, 
      ),
      itemCount: state.cartItems.length,
      itemBuilder: (context, index) {
        final item = state.cartItems[index];
        final itemMap = _convertToSafeMap(item);
        return _buildCartItem(context, itemMap);
      },
    );
  }

  Widget _buildCartItem(BuildContext context, Map<String, dynamic> item) {
    final product = _convertToSafeMap(item['product']);
    final productId = item['product_id'];
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    final price = (item['display_price'] as num?)?.toDouble() ?? 0.0;
    final appliedPromotions = item['applied_promotions'] ?? [];

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
              child: _buildProductInfo(context, product, price, productId, quantity, appliedPromotions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context, Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => _onProductTap(product, context),
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

  Widget _buildProductImageContent(BuildContext context, Map<String, dynamic> product) {
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

  Widget _buildProductInfo(
    BuildContext context, 
    Map<String, dynamic> product, 
    double price, 
    int productId, 
    int quantity, 
    List<dynamic> appliedPromotions
  ) {
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
                onTap: () => _onProductTap(product, context),
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
            _buildDeleteButton(context, productId),
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
              onQuantityChanged: (productId, quantity) {
                context.read<CartBloc>().add(CartItemQuantityUpdated(productId, quantity));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context, int productId) {
    return IconButton(
      icon: const Icon(
        Icons.delete_outline,
        color: Colors.red,
        size: 22,
      ),
      onPressed: () => context.read<CartBloc>().add(CartItemRemoved(productId)),
      padding: const EdgeInsets.all(4),
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartState state) {
    final hasDiscount = state.originalTotalAmount > state.totalAmount;
    final totalSavings = state.originalTotalAmount - state.totalAmount;
    final isCreatingOrder = state.status == CartStatus.creatingOrder;

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
            
            Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              height: 1,
            ),
            const SizedBox(height: 16),
            
            Column(
              children: [
                if (hasDiscount) ...[
                  _buildSummaryRow(
                    context,
                    'Сумма товаров',
                    '${state.originalTotalAmount.toStringAsFixed(2)} ₽',
                    icon: Icons.shopping_cart_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    context,
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
                  context,
                  'Итого к оплате',
                  '${state.totalAmount.toStringAsFixed(2)} ₽',
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
                onPressed: isCreatingOrder ? null : () => _createOrder(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                ),
                child: isCreatingOrder
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
    BuildContext context,
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

  Widget _buildAddressSelector(BuildContext context, CartState state) {
    if (state.addressesStatus == CartStatus.loading) {
      return Card(
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
      );
    }

    if (state.addressesStatus == CartStatus.error) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.addressesError ?? 'Ошибка загрузки адресов',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.addresses.isEmpty) {
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
                  const SizedBox(width: 12),
                  Text(
                    'Адрес доставки',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Адрес не указан',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.push('/addresses'),
                child: const Text('Добавить адрес'),
              ),
            ],
          ),
        ),
      );
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
                context.read<CartBloc>().add(
                  AddressExpandedToggled(!state.isAddressExpanded),
                );
              },
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
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
                        if (state.selectedAddress != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            state.selectedAddress!['address_line'] ?? 'Адрес не указан',
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
                    state.isAddressExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),

            if (state.isAddressExpanded) ...[
              const SizedBox(height: 16),
              ...state.addresses.map((address) {
                final isSelected = state.selectedAddress?['id'] == address['id'];
                return _buildAddressItem(context, address, isSelected);
              }).toList(),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              TextButton.icon(
                onPressed: () => context.push('/addresses'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Добавить новый адрес'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressItem(BuildContext context, Map<String, dynamic> address, bool isSelected) {
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          context.read<CartBloc>().add(AddressSelected(address));
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}