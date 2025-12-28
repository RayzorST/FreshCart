import 'package:client/domain/entities/cart_item_entity.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/features/main/screens/promotion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<CartBloc>();
      bloc.add(const CartLoaded());
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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

  void _navigateToPromotionScreen(List<Map<String, dynamic>> appliedPromotions, BuildContext context) {
    if (appliedPromotions.isEmpty) return;

    if (appliedPromotions.length > 1) {
      _showPromotionsDialog(appliedPromotions, 'Примененные акции');
    } else {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth > 600) {
        final promotion = appliedPromotions.first;
        ScreenToModal.show(context: context, child: PromotionScreen(promotionId: promotion['promotion_id']));
      } else {
        final promotion = appliedPromotions.first;
        context.push('/promotion/${promotion['promotion_id']}', extra: promotion);
      }
    }
  }

  void _showPromotionsDialog(List<Map<String, dynamic>> promotions, String title) {
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
              final promotion = promotions[index];
              return ListTile(
                leading: Icon(
                  Icons.local_offer_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(promotion['name'] ?? 'Акция'),
                subtitle: promotion['description'] != null 
                    ? Text(promotion['description'] as String)
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
    // TODO: Обновить для работы с адресами
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создание заказа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Добавьте примечание к заказу (необязательно):'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Примечание...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Создать заказ через API
              AppSnackbar.showSuccess(context: context, message: 'Заказ создан!');
            },
            child: const Text('Создать заказ'),
          ),
        ],
      ),
    );
  }

  void _onProductTap(ProductEntity product, BuildContext context) {
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
          if (state.status == CartStatus.error && state.error != null) {
            AppSnackbar.showError(context: context, message: state.error!);
          }
        },
        builder: (context, state) {
          return _buildBody(context, state);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CartState state) {
    // Показываем полную загрузку только при начальной загрузке
    if (state.status == CartStatus.initial) {
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
            onPressed: () => context.read<CartBloc>().add(const CartLoaded()),
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
          // Список товаров
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _buildProductsGrid(context, state),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Итого
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
        ...state.cartItems.map((item) {
          return Column(
            children: [
              _buildCartItem(context, item),
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
        return _buildCartItem(context, item);
      },
    );
  }

  Widget _buildCartItem(BuildContext context, CartItemEntity item) {
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
            _buildProductImage(context, item),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProductInfo(context, item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context, CartItemEntity item) {
    return GestureDetector(
      onTap: () => _onProductTap(item.product, context),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: _buildProductImageContent(context, item),
      ),
    );
  }

  Widget _buildProductImageContent(BuildContext context, CartItemEntity item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        item.product.imageUrl,
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
    CartItemEntity item,
  ) {
    final hasDiscount = item.hasDiscount;
    final originalPrice = item.discountPrice ?? item.product.price;
    final discountedPrice = item.product.price;
    final hasPromotions = item.appliedPromotions != null && item.appliedPromotions!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _onProductTap(item.product, context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (item.product.category != null)
                      Text(
                        item.product.category!.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasPromotions)
                  IconButton(
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_offer_outlined,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                    onPressed: () => _navigateToPromotionScreen(item.appliedPromotions!, context),
                    padding: const EdgeInsets.all(4),
                    tooltip: 'Примененные акции',
                  ),
                _buildDeleteButton(context, item.product.id),
              ],
            ),
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
                Row(
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
                // Отображение скидки если есть
                if (hasDiscount && hasPromotions && item.appliedPromotions != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_offer,
                          size: 12,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '-${item.discountAmount.toStringAsFixed(2)} ₽',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            QuantityControls(
              productId: item.product.id,
              quantity: item.quantity,
              onQuantityChanged: (productId, newQuantity) {
                final cartBloc = context.read<CartBloc>();

                if (newQuantity == 0) {
                  cartBloc.add(CartItemRemoved(productId));
                } else {
                  cartBloc.add(CartItemUpdated(productId, newQuantity));
                }
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
                    Text('${state.originalTotalAmount.toStringAsFixed(2)} ₽'),
                    icon: Icons.shopping_cart_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    context,
                    'Ваша скидка',
                    Text(
                      '-${totalSavings.toStringAsFixed(2)} ₽',
                      style: const TextStyle(color: Colors.green),
                    ),
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
                  Text(
                    '${state.totalAmount.toStringAsFixed(2)} ₽',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                  ),
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
                onPressed: () => _createOrder(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                ),
                child: Row(
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
    Widget value,
    {
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
        value,
      ],
    );
  }
}