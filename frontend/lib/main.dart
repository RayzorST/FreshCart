import 'package:flutter/material.dart';
import 'package:client/app.dart';
import 'package:client/core/di/di.dart';
import 'package:client/core/app_sync_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  getIt<AppSyncHandler>().initialize();
  runApp(const FreshCartApp());
}