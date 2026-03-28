// lib/services/websocket_service.dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart';
import '../api/client.dart';
import '../services/local_notification_service.dart';
import 'package:client/domain/entities/notification_entity.dart';

class WebSocketService {
  static WebSocketService? _instance;
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  WebSocketService._();

  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }

  Future<void> connect() async {
    if (_channel != null || _isConnecting) return;

    final token = ApiClient.token;
    print('🔌 WebSocket connecting with token: ${token?.substring(0, 20)}...');
    
    if (token == null || token.isEmpty) {
      print('❌ No token available for WebSocket');
      return;
    }

    String wsUrl;
    if (kIsWeb) {
      wsUrl = 'ws://localhost:8000/ws/notifications?token=$token';
    } else {
      wsUrl = 'ws://freshcart-api.cloudpub.ru/ws/notifications?token=$token';
      // Или если у вас есть SSL:
      // wsUrl = 'wss://freshcart-api.cloudpub.ru/ws/notifications?token=$token';
    }
    
    print('🔌 WebSocket URL: $wsUrl');
    
    _isConnecting = true;
    
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (message) {
          print('📨 WebSocket message received: $message');
          _handleMessage(message);
          _reconnectAttempts = 0;
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _reconnect();
        },
        onDone: () {
          print('🔌 WebSocket closed');
          _reconnect();
        },
      );
      
      print('✅ WebSocket connected successfully');
    } catch (e) {
      print('❌ Failed to connect WebSocket: $e');
      _reconnect();
    } finally {
      _isConnecting = false;
    }
  }
    
  void _reconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached');
      return;
    }
    
    Future.delayed(_reconnectDelay, () {
      _reconnectAttempts++;
      debugPrint('Reconnecting WebSocket (attempt $_reconnectAttempts/$_maxReconnectAttempts)');
      connect();
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String);
      
      if (data['type'] == 'initial') {
        print('📊 Unread count: ${data['unread_count']}');
        return;
      }
      
      final notification = NotificationEntity.fromJson(data);
      
      // Показываем локальное уведомление
      final payload = notification.data?.map((k, v) => MapEntry(k.toString(), v.toString()));
      
      LocalNotificationService.showNotification(
        id: notification.id,
        title: notification.title,
        body: notification.message,
        payload: payload,
      );
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  void _showLocalNotification(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final title = data['title'] as String? ?? 'FreshCart';
    final message = data['message'] as String? ?? '';
    final notificationData = data['data'] as Map<String, dynamic>?;
    
    switch (type) {
      case 'order_status':
        if (notificationData != null) {
          final orderId = notificationData['order_id'] as int?;
          final newStatus = notificationData['new_status'] as String?;
          
          String statusText;
          switch (newStatus) {
            case 'confirmed':
              statusText = 'подтвержден';
              break;
            case 'shipped':
              statusText = 'отправлен';
              break;
            case 'delivered':
              statusText = 'доставлен';
              break;
            case 'cancelled':
              statusText = 'отменен';
              break;
            default:
              statusText = newStatus ?? 'изменен';
          }
          
          final payload = <String, String>{};
          if (orderId != null) {
            payload['order_id'] = orderId.toString();
          }
          
          LocalNotificationService.showNotification(
            id: DateTime.now().millisecond,
            title: 'Статус заказа #$orderId',
            body: 'Заказ $statusText',
            payload: payload.isNotEmpty ? payload : null,
          );
        }
        break;
        
      case 'new_promotion':
        final payload = <String, String>{};
        if (notificationData != null && notificationData['promotion_id'] != null) {
          payload['promotion_id'] = notificationData['promotion_id'].toString();
        }
        
        LocalNotificationService.showNotification(
          id: DateTime.now().millisecond,
          title: '🎉 Новая акция',
          body: title,
          payload: payload.isNotEmpty ? payload : null,
        );
        break;
        
      default:
        LocalNotificationService.showNotification(
          id: DateTime.now().millisecond,
          title: title,
          body: message,
        );
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnecting = false;
  }
}