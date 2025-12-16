// app_sync_handler.dart
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:client/core/services/sync_service.dart';
import 'package:client/core/services/sync_manager.dart';

@LazySingleton()
class AppSyncHandler {
  final SyncService _syncService;
  final SyncManager? _syncManager; // Может быть null, если не используется

  AppSyncHandler(this._syncService, [this._syncManager]);

  void initialize() {
    // Синхронизация при запуске приложения
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialSync();
    });

    // Слушатель изменения фокуса приложения
    _setupAppLifecycleListener();
  }

  Future<void> _initialSync() async {
    // Ждем немного, чтобы приложение успело инициализироваться
    await Future.delayed(const Duration(seconds: 2));
    
    // Проверяем обновления продуктов
    final needsUpdate = await _syncService.checkProductsUpdate();
    if (needsUpdate) {
      await _syncService.syncProducts();
    }
    
    // Синхронизируем корзину, если пользователь авторизован
    await _syncService.syncCart();
  }

  void _setupAppLifecycleListener() {
    // Отслеживаем возврат приложения в foreground
    WidgetsBinding.instance.addObserver(
      _AppLifecycleObserver(
        onResume: () => _onAppResumed(),
      ),
    );
  }

  Future<void> _onAppResumed() async {
    // Быстрая синхронизация при возвращении в приложение
    await _syncService.syncCart();
    
    // Проверяем обновления продуктов раз в час
    final now = DateTime.now();
    final lastProductSync = await _getLastProductSync();
    if (lastProductSync == null || 
        now.difference(lastProductSync) > const Duration(hours: 1)) {
      await _syncService.syncProducts();
      await _saveLastProductSync(now);
    }
  }

  // Простые методы для хранения времени последней синхронизации
  Future<DateTime?> _getLastProductSync() async {
    // Используем SharedPreferences или другую простую хранилку
    // В этом примере - просто заглушка
    return null;
  }

  Future<void> _saveLastProductSync(DateTime time) async {
    // Заглушка - в реальности сохраняем в SharedPreferences
  }

  // Метод для ручной синхронизации из UI
  Future<void> manualSync() async {
    await _syncService.syncCart();
    await _syncService.syncProducts();
  }
}

// Простой observer для жизненного цикла приложения
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;

  _AppLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }
}