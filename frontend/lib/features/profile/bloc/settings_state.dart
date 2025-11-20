part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final bool orderNotifications;
  final bool promoNotifications;
  final bool isDarkTheme;

  const SettingsLoaded({
    required this.orderNotifications,
    required this.promoNotifications,
    required this.isDarkTheme,
  });

  SettingsLoaded copyWith({
    bool? orderNotifications,
    bool? promoNotifications,
    bool? isDarkTheme,
  }) {
    return SettingsLoaded(
      orderNotifications: orderNotifications ?? this.orderNotifications,
      promoNotifications: promoNotifications ?? this.promoNotifications,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
    );
  }

  @override
  List<Object> get props => [orderNotifications, promoNotifications, isDarkTheme];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError({required this.message});

  @override
  List<Object> get props => [message];
}