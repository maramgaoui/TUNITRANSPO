import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/notification_controller.dart';
import 'models/user_model.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initialize();
  await NotificationController.instance.initialize();
  
  // Initialize settings service to load saved preferences
  final settingsService = SettingsService();
  await settingsService.init();
  
  runApp(MyApp(settingsService: settingsService));
}

class MyApp extends StatefulWidget {
  final SettingsService settingsService;
  
  const MyApp({
    super.key,
    required this.settingsService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    // Load saved theme preference
    final themeSetting = widget.settingsService.getThemeMode();
    _themeMode = themeSetting == 'dark' ? ThemeMode.dark : ThemeMode.light;

    final languageSetting = widget.settingsService.getLanguage();
    _locale = _localeFromLanguage(languageSetting);
  }

  void _updateThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void _updateLanguage(String language) {
    setState(() => _locale = _localeFromLanguage(language));
  }

  Locale _localeFromLanguage(String language) {
    // Store locale as language code (en/fr/ar), while supporting old saved labels.
    switch (language) {
      case 'en':
      case 'English':
        return const Locale('en');
      case 'ar':
      case 'العربية':
        return const Locale('ar');
      case 'fr':
      case 'Français':
      default:
        return const Locale('fr');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AuthGuard(
        settingsService: widget.settingsService,
        onThemeChanged: _updateThemeMode,
        onLanguageChanged: _updateLanguage,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Auth guard that monitors auth state and routes accordingly
class AuthGuard extends StatefulWidget {
  final SettingsService settingsService;
  final Function(ThemeMode) onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  
  const AuthGuard({
    super.key,
    required this.settingsService,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authController.authStateChanges,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen(
            settingsService: widget.settingsService,
            onThemeChanged: widget.onThemeChanged,
            onLanguageChanged: widget.onLanguageChanged,
          );
        }

        // User is logged out
        return const AuthScreen();
      },
    );
  }
}
