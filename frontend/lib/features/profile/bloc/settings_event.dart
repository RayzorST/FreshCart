part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadSettings extends SettingsEvent {}

class LoadThemeSettings extends SettingsEvent {} // Новое событие

class LoadNotificationSettings extends SettingsEvent {} // Новое событие

class UpdateNotificationSettings extends SettingsEvent {
  final bool orderNotifications;
  final bool promoNotifications;

  const UpdateNotificationSettings({
    required this.orderNotifications,
    required this.promoNotifications,
  });

  @override
  List<Object> get props => [orderNotifications, promoNotifications];
}

class UpdateThemeSettings extends SettingsEvent {
  final bool isDarkTheme;

  const UpdateThemeSettings({required this.isDarkTheme});

  @override
  List<Object> get props => [isDarkTheme];
}

class ToggleTheme extends SettingsEvent {}