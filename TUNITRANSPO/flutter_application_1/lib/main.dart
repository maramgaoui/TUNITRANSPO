import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_runtime_options.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/notification_controller.dart';
import 'router/app_router.dart';
import 'service_locator.dart';
import 'services/notification_service.dart';
import 'services/active_journey_service.dart';
import 'package:tuni_transport/services/settings_service.dart';
import 'services/firestore_initialization_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_settings.dart';

String _maskApiKey(String key) {
  if (key.length <= 8) return '***';
  return '${key.substring(0, 6)}...${key.substring(key.length - 4)}';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final activeOptions = FirebaseRuntimeOptions.currentPlatform;
  if (kDebugMode) {
    final defaultOptions = DefaultFirebaseOptions.currentPlatform;
    debugPrint(
      'Firebase config => integrationTestMode=${FirebaseRuntimeOptions.integrationTestMode}, hasTestOverride=${FirebaseRuntimeOptions.hasTestOverride}',
    );
    debugPrint(
      'Firebase default config => appId=${defaultOptions.appId}, apiKey=${_maskApiKey(defaultOptions.apiKey)}',
    );
    debugPrint(
      'Firebase runtime config => appId=${activeOptions.appId}, apiKey=${_maskApiKey(activeOptions.apiKey)}',
    );
  }
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(options: activeOptions);
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app' && e.code != 'core/duplicate-app') {
        rethrow;
      }
    }
  }

  if (!FirebaseRuntimeOptions.integrationTestMode) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService.instance.initialize();
    await NotificationController.instance.initialize();
  }
  await ActiveJourneyService.instance.init();

  // Initialize Firestore with TRANSTU data
  try {
    await FirestoreInitializationService().initialize();
  } catch (e) {
    debugPrint('Warning: Firestore initialization failed: $e');
    // Continue anyway - data may already exist
  }

  // Initialize settings service to load saved preferences
  final settingsService = SettingsService();
  await settingsService.init();

  // Register singletons for dependency injection
  setupServiceLocator(settingsService: settingsService);

  // Global error handlers (#26)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // TODO: forward to Crashlytics when integrated
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Uncaught platform error: $error\n$stack');
    // TODO: forward to Crashlytics when integrated
    return true; // prevents the runtime from terminating
  };

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
    return AppSettings(
      settingsService: widget.settingsService,
      onThemeChanged: _updateThemeMode,
      onLanguageChanged: _updateLanguage,
      child: MaterialApp.router(
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
      ),
    );
  }
}
