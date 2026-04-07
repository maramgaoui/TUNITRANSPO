import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/notification_controller.dart';
import 'router/app_router.dart';
import 'services/notification_service.dart';
import 'services/active_journey_service.dart';
import 'theme/app_theme.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initialize();
  await NotificationController.instance.initialize();
  await ActiveJourneyService.instance.init();

  // Initialize settings service to load saved preferences
  final settingsService = SettingsService();
  await settingsService.init();

  runApp(MyApp(settingsService: settingsService));
}

class MyApp extends StatefulWidget {
  final SettingsService settingsService;

  const MyApp({super.key, required this.settingsService});

  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {
  late final AuthController _authController;
  late final GoRouter _router;
  late ThemeMode _themeMode;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _authController = AuthController.instance;
    // Load saved theme preference
    final themeSetting = widget.settingsService.getThemeMode();
    _themeMode = switch (themeSetting) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };

    final languageSetting = widget.settingsService.getLanguage();
    _locale = _localeFromLanguage(languageSetting);

    _router = AppRouter.create(
      authController: _authController,
      settingsService: widget.settingsService,
      onThemeChanged: _updateThemeMode,
      onLanguageChanged: _updateLanguage,
    );
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
    return MaterialApp.router(
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
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
