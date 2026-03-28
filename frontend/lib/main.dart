import 'package:flutter/material.dart';
import 'package:client/app.dart';
import 'package:client/core/di/di.dart';
import 'package:client/services/local_notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  LocalNotificationService.initialize();
  requestPermissions();
  runApp(const FreshCartApp());
}