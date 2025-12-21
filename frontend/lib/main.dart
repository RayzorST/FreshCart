import 'package:flutter/material.dart';
import 'package:client/app.dart';
import 'package:client/core/di/di.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const FreshCartApp());
}