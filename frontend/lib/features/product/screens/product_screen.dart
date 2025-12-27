import 'package:client/domain/entities/product_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/core/widgets/app_snackbar.dart';
import 'package:client/features/product/bloc/product_bloc.dart';
import 'package:client/core/di/di.dart';
import 'package:client/domain/repositories/cart_repository.dart';
import 'package:client/domain/repositories/favorite_repository.dart';
import 'package:client/features/main/bloc/cart_bloc.dart';
import 'package:client/features/main/bloc/favorites_bloc.dart';

class ProductScreen extends StatelessWidget {
  final ProductEntity product;
  
  const ProductScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 1. ProductBloc для текущего продукта
        BlocProvider(
          create: (context) => ProductBloc(
            product: product,
            cartRepository: getIt<CartRepository>(),
            favoriteRepository: getIt<FavoriteRepository>(),
            cartBloc: context.read<CartBloc>()
          ),
        ),
        // 2. Глобальный CartBloc через GetIt
        BlocProvider.value(value: getIt<CartBloc>()),
        // 3. Глобальный FavoritesBloc через GetIt
        BlocProvider.value(value: getIt<FavoritesBloc>()),
      ],
      child: _ProductScreenContent(product: product),
    );
  }
}

class _ProductScreenContent extends StatefulWidget {
  final ProductEntity product;

  const _ProductScreenContent({required this.product});

  @override
  State<_ProductScreenContent> createState() => __ProductScreenContentState();
}

class __ProductScreenContentState extends State<_ProductScreenContent> {
  @override
  void initState() {
    super.initState();
    // Загружаем начальное состояние
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<ProductBloc>();
      bloc.add(ProductLoadFavoriteStatus());
      bloc.add(ProductLoadCartQuantity());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем состояние при каждом возвращении на экран
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<ProductBloc>();
      bloc.add(ProductLoadFavoriteStatus());
      bloc.add(ProductLoadCartQuantity());
    });
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.product.price;
    final stockQuantity = widget.product.stockQuantity ?? 0;
    final isAvailable = stockQuantity > 0;
    final maxQuantity = stockQuantity;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Детали товара',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppSnackbar.showError(context: context, message: state.errorMessage!);
            context.read<ProductBloc>().add(ProductLoadFavoriteStatus());
            context.read<ProductBloc>().add(ProductLoadCartQuantity());
          }
        },
        child: Column(
          children: [
            _buildProductCard(context),
            
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [ 
                      _buildHeaderSection(context),
                      
                      const SizedBox(height: 24),
                      
                      _buildPriceRatingSection(context, price),
                      
                      const SizedBox(height: 8),
                             
                      _buildStockInfo(isAvailable, stockQuantity),
                      
                      const SizedBox(height: 32),
                              
                      _buildDescriptionSection(context),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomPanel(context, isAvailable, maxQuantity),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.15),
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              widget.product.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.food_bank,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.product.category != null )
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    widget.product.category!.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            return IconButton(
              onPressed: state.isLoadingFavorite ? null : () {
                context.read<ProductBloc>().add(ProductToggleFavorite());
                final message = state.isFavorite 
                    ? '${widget.product.name} удален из избранного'
                    : '${widget.product.name} добавлен в избранное';
                AppSnackbar.showInfo(context: context, message: message);
              },
              icon: state.isLoadingFavorite
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        state.isFavorite ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(state.isFavorite),
                        color: state.isFavorite 
                            ? Colors.red 
                            : Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceRatingSection(BuildContext context, double price) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$price ₽',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildStockInfo(bool isAvailable, int stockQuantity) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isAvailable ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isAvailable 
              ? 'В наличии • $stockQuantity шт.' 
              : 'Нет в наличии',
          style: TextStyle(
            color: isAvailable ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Описание',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            widget.product.description?.isNotEmpty == true 
                ? widget.product.description! 
                : 'Описание отсутствует',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(BuildContext context, bool isAvailable, int maxQuantity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            return Container(
              decoration: BoxDecoration(
                color: state.quantity > 0 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: state.quantity > 0
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: state.isLoadingCart || state.quantity == 0 ? null : () {
                      context.read<ProductBloc>().add(
                        ProductUpdateCartQuantity(state.quantity - 1)
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: state.quantity > 0
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 20,
                        color: state.quantity > 0
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ),
                  state.isLoadingCart
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.quantity > 0 ? '${_getQuantityText(state.quantity)}' : 'Добавить',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: state.quantity > 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            if (state.quantity > 0)
                              Text(
                                'в корзине',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                          ],
                        ),      
                  IconButton(
                    onPressed: state.isLoadingCart || !isAvailable || state.quantity >= maxQuantity ? null : () {
                      context.read<ProductBloc>().add(
                        ProductUpdateCartQuantity(state.quantity + 1)
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isAvailable && state.quantity < maxQuantity
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 20,
                        color: isAvailable && state.quantity < maxQuantity
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getQuantityText(int quantity) {
    if (quantity == 1) return '1 товар';
    if (quantity >= 2 && quantity <= 4) return '$quantity товара';
    return '$quantity товаров';
  }
}