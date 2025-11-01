import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuantityControls extends ConsumerWidget {
  final int productId;
  final int quantity;
  final Function(int, int) onQuantityChanged;
  final Color? primaryColor;
  final Color? disabledColor;
  final double iconSize;
  final double controlSize;
  final bool fullWidth;

  const QuantityControls({
    super.key,
    required this.productId,
    required this.quantity,
    required this.onQuantityChanged,
    this.primaryColor,
    this.disabledColor,
    this.iconSize = 18,
    this.controlSize = 32,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final effectivePrimaryColor = primaryColor ?? theme.colorScheme.primary;
    final effectiveDisabledColor = disabledColor ?? theme.colorScheme.onSurface.withOpacity(0.3);

    return Container(
      width: fullWidth ? double.infinity : 120, // 👈 Условная ширина
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min, // 👈 Здесь
        children: [
          IconButton(
            icon: Icon(
              Icons.remove,
              size: iconSize,
              color: quantity > 0 ? effectivePrimaryColor : effectiveDisabledColor,
            ),
            onPressed: quantity > 0 ? () {
              onQuantityChanged(productId, quantity - 1);
            } : null,
            padding: const EdgeInsets.all(6),
            constraints: BoxConstraints(
              minWidth: controlSize,
              minHeight: controlSize,
            ),
          ),
          
          Expanded( // 👈 Добавь Expanded если fullWidth
            child: Container(
              alignment: Alignment.center,
              child: Text(
                quantity.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          IconButton(
            icon: Icon(
              Icons.add,
              size: iconSize,
              color: effectivePrimaryColor,
            ),
            onPressed: () {
              onQuantityChanged(productId, quantity + 1);
            },
            padding: const EdgeInsets.all(6),
            constraints: BoxConstraints(
              minWidth: controlSize,
              minHeight: controlSize,
            ),
          ),
        ],
      ),
    );
  }
}