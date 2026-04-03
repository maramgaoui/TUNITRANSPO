import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings (theme, language, etc)
/// Persists settings to local storage so they survive app restarts
class SettingsService {
  static const String _themeKey = 'app_theme_mode';
  static const String _languageKey = 'app_language';

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize SharedPreferences
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Get saved theme mode (light/dark)
  /// Default: light
  String getThemeMode() {
    _ensureInitialized();
    return _prefs.getString(_themeKey) ?? 'light';
  }

  /// Save theme mode preference
  Future<void> setThemeMode(String mode) async {
    _ensureInitialized();
    await _prefs.setString(_themeKey, mode);
  }

  /// Get saved language preference
  /// Default: fr
  String getLanguage() {
    _ensureInitialized();
    final savedLanguage = _prefs.getString(_languageKey);
    if (savedLanguage == null) {
      return 'fr';
    }

    // Backward compatibility with old display-name values.
    switch (savedLanguage) {
      case 'English':
        return 'en';
      case 'العربية':
        return 'ar';
      case 'Français':
        return 'fr';
      default:
        return savedLanguage;
    }
  }

  /// Save language preference
  Future<void> setLanguage(String language) async {
    _ensureInitialized();
    await _prefs.setString(_languageKey, language);
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('SettingsService not initialized. Call init() first.');
    }
  }
}
