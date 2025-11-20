import 'package:bloc/bloc.dart';
import 'package:client/api/client.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const String _themeKey = 'dark_theme';

  SettingsBloc() : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<LoadThemeSettings>(_onLoadThemeSettings); // Новое событие
    on<LoadNotificationSettings>(_onLoadNotificationSettings); // Новое событие
    on<UpdateNotificationSettings>(_onUpdateNotificationSettings);
    on<UpdateThemeSettings>(_onUpdateThemeSettings);
    on<ToggleTheme>(_onToggleTheme);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      // Сначала загружаем только тему (не требует аутентификации)
      final prefs = await SharedPreferences.getInstance();
      final isDarkTheme = prefs.getBool(_themeKey) ?? false;
      
      // Если требуется аутентификация для уведомлений, загружаем их отдельно
      // Пока используем значения по умолчанию
      emit(SettingsLoaded(
        orderNotifications: true, // значение по умолчанию
        promoNotifications: true, // значение по умолчанию
        isDarkTheme: isDarkTheme,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Ошибка загрузки настроек: $e'));
    }
  }

  // Новый метод для загрузки только темы
  Future<void> _onLoadThemeSettings(
    LoadThemeSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkTheme = prefs.getBool(_themeKey) ?? false;
      
      if (state is SettingsLoaded) {
        final currentState = state as SettingsLoaded;
        emit(currentState.copyWith(isDarkTheme: isDarkTheme));
      } else {
        emit(SettingsLoaded(
          orderNotifications: true,
          promoNotifications: true,
          isDarkTheme: isDarkTheme,
        ));
      }
    } catch (e) {
      print('Ошибка загрузки темы: $e');
    }
  }

  // Новый метод для загрузки уведомлений (только после аутентификации)
  Future<void> _onLoadNotificationSettings(
    LoadNotificationSettings event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;
    
    final currentState = state as SettingsLoaded;
    
    try {
      final settings = await ApiClient.getNotificationSettings();
      
      emit(currentState.copyWith(
        orderNotifications: settings['order_notifications'] ?? true,
        promoNotifications: settings['promo_notifications'] ?? true,
      ));
    } catch (e) {
      print('Ошибка загрузки уведомлений: $e');
      // Не эмитим ошибку, оставляем текущее состояние
    }
  }

  // Остальные методы без изменений
  Future<void> _onUpdateNotificationSettings(
    UpdateNotificationSettings event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;
    
    final currentState = state as SettingsLoaded;
    
    try {
      await ApiClient.updateNotificationSettings({
        'order_notifications': event.orderNotifications,
        'promo_notifications': event.promoNotifications,
      });
      
      emit(currentState.copyWith(
        orderNotifications: event.orderNotifications,
        promoNotifications: event.promoNotifications,
      ));
    } catch (e) {
      emit(SettingsError(message: e.toString()));
      emit(currentState);
    }
  }

  Future<void> _onUpdateThemeSettings(
    UpdateThemeSettings event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;
    
    final currentState = state as SettingsLoaded;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, event.isDarkTheme);
      
      emit(currentState.copyWith(isDarkTheme: event.isDarkTheme));
    } catch (e) {
      emit(SettingsError(message: 'Ошибка сохранения темы: $e'));
      emit(currentState);
    }
  }

  Future<void> _onToggleTheme(
    ToggleTheme event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;
    
    final currentState = state as SettingsLoaded;
    final newThemeValue = !currentState.isDarkTheme;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, newThemeValue);
      
      emit(currentState.copyWith(isDarkTheme: newThemeValue));
    } catch (e) {
      emit(SettingsError(message: 'Ошибка переключения темы: $e'));
      emit(currentState);
    }
  }
}