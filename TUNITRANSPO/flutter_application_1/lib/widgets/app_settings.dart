import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// Provides [SettingsService] and theme/language callbacks
/// to the entire widget tree, eliminating prop-drilling through routes.
class AppSettings extends InheritedWidget {
  const AppSettings({
    super.key,
    required this.settingsService,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required super.child,
  });

  final SettingsService settingsService;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  static AppSettings of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppSettings>();
    assert(result != null, 'No AppSettings found in context');
    return result!;
  }

  static AppSettings? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppSettings>();
  }

  @override
  bool updateShouldNotify(AppSettings oldWidget) =>
      settingsService != oldWidget.settingsService;
}
