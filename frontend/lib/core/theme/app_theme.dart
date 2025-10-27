import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4CAF50);      // Светло-зелёный
  static const primaryLight = Color(0xFF81C784); // Очень светлый зелёный
  static const primaryDark = Color(0xFF388E3C);  // Тёмно-зелёный для текста
  static const background = Color(0xFFFAFAFA);   // Очень светлый фон
  static const surface = Color(0xFFFFFFFF);      // Белый для карточек
  static const accent = Color(0xFF2196F3);       // Синий для акцентов
}

class AppTheme {
  static final lightTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      background: AppColors.background,
      onBackground: Color(0xFF212121),
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    useMaterial3: true,
  );

  static final darkTheme = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: Colors.black,
      primaryContainer: Color(0xFF1B5E20),
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      onBackground: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
    ),
    useMaterial3: true,
  );
}