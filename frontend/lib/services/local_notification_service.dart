// lib/services/local_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings();
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings: initSettings);
    print('✅ Notifications initialized');
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'freshcart_channel',
      'FreshCart',
      channelDescription: 'FreshCart notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload != null ? Uri(queryParameters: payload).query : null,
    );
    
    print('✅ Notification shown: $title');
  }
}