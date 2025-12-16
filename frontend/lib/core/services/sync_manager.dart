// sync_manager.dart - полностью рабочий
import 'package:injectable/injectable.dart';
import 'package:client/core/services/sync_service.dart';
import 'package:dartz/dartz.dart';

enum SyncType {
  cart,
  products,
  favorites,
  full,
}

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

@LazySingleton()
class SyncManager {
  final SyncService _syncService;
  
  SyncStatus _status = SyncStatus.idle;
  String? _lastError;
  DateTime? _lastSyncTime;
  SyncType? _lastSyncType;

  SyncManager(this._syncService);

  // Геттеры
  SyncStatus get status => _status;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  SyncType? get lastSyncType => _lastSyncType;
  bool get isSyncing => _status == SyncStatus.syncing;

  // Основной метод синхронизации
  Future<bool> sync({
    SyncType type = SyncType.full,
    bool force = false,
  }) async {
    if (_status == SyncStatus.syncing) {
      return false;
    }

    _status = SyncStatus.syncing;
    _lastError = null;
    _lastSyncType = type;

    try {
      switch (type) {
        case SyncType.cart:
          final result = await _syncService.syncCart();
          _handleResult(result);
          break;
          
        case SyncType.products:
          final result = await _syncService.syncProducts();
          _handleResult(result);
          break;
          
        case SyncType.favorites:
          final result = await _syncService.syncFavorites();
          _handleResult(result);
          break;
          
        case SyncType.full:
          // Сначала корзина
          final cartResult = await _syncService.syncCart();
          if (cartResult.isLeft()) {
            // Логируем, но продолжаем
            print('Ошибка синхронизации корзины: ${cartResult.fold((l) => l, (r) => null)}');
          }
          
          // Потом продукты
          final productsResult = await _syncService.syncProducts();
          _handleResult(productsResult);
          break;
      }

      _status = SyncStatus.success;
      _lastSyncTime = DateTime.now();
      return true;
      
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      return false;
    }
  }

  // Вспомогательный метод для обработки Either
  void _handleResult(Either<String, void> result) {
    result.fold(
      (error) => throw Exception(error),
      (_) => {},
    );
  }

  // Быстрая синхронизация корзины
  Future<bool> syncCart() => sync(type: SyncType.cart);

  // Синхронизация продуктов
  Future<bool> syncProducts() => sync(type: SyncType.products);

  // Проверка, нужно ли синхронизировать продукты
  Future<bool> shouldSyncProducts() async {
    try {
      return await _syncService.checkProductsUpdate();
    } catch (e) {
      return false;
    }
  }

  // Сброс статуса
  void reset() {
    _status = SyncStatus.idle;
    _lastError = null;
  }

  // Форматированное время последней синхронизации
  String? get formattedLastSyncTime {
    if (_lastSyncTime == null) return null;
    
    final now = DateTime.now();
    final diff = now.difference(_lastSyncTime!);
    
    if (diff.inSeconds < 60) {
      return 'только что';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин назад';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ч назад';
    } else {
      return '${diff.inDays} дн назад';
    }
  }

  // Информация для UI
  Map<String, dynamic> get syncInfo {
    return {
      'status': _status.name,
      'lastSync': formattedLastSyncTime,
      'lastType': _lastSyncType?.name,
      'hasError': _status == SyncStatus.error,
      'error': _lastError,
    };
  }
}