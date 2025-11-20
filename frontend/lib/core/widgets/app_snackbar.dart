import 'package:flutter/material.dart';

class AppSnackbar {
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showFloatingBanner(
      context: context,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.primary,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showFloatingBanner(
      context: context,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.error,
      icon: Icons.error,
      duration: duration,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showFloatingBanner(
      context: context,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      icon: Icons.warning,
      duration: duration,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showFloatingBanner(
      context: context,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      icon: Icons.info,
      duration: duration,
    );
  }

  static void _showFloatingBanner({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    final overlay = Overlay.of(context);
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: isWideScreen ? null : 16,
        right: 16,
        width: isWideScreen ? 400 : null,
        child: _FloatingMaterialBanner(
          message: message,
          backgroundColor: backgroundColor,
          icon: icon,
          onDismiss: () => overlayEntry.remove(),
          duration: duration,
          isWideScreen: isWideScreen,
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  static void showLoading(BuildContext context, {String message = 'Загрузка...'}) {
    _showFloatingBanner(
      context: context,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.primary,
      icon: Icons.hourglass_top,
      duration: const Duration(seconds: 30),
    );
  }

  static void hideCurrent(BuildContext context) {
    // Для Overlay нужно сохранять reference, но в этой реализации
    // уведомления удаляются автоматически по таймеру или кнопке закрытия
  }

  static void clearAll(BuildContext context) {
    // В этой реализации очистка не требуется, так как каждое уведомление
    // управляется самостоятельно через OverlayEntry
  }
}

class _FloatingMaterialBanner extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;
  final Duration duration;
  final bool isWideScreen;

  const _FloatingMaterialBanner({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
    required this.duration,
    required this.isWideScreen,
  });

  @override
  State<_FloatingMaterialBanner> createState() => _FloatingMaterialBannerState();
}

class _FloatingMaterialBannerState extends State<_FloatingMaterialBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            widget.isWideScreen ? _slideAnimation.value : 0,
            widget.isWideScreen ? 0 : _slideAnimation.value
          ),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: Material(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: widget.isWideScreen ? 400 : null,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                onPressed: () {
                  _controller.reverse().then((_) {
                    widget.onDismiss();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}