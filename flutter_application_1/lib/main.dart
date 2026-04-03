import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'admin/screens/admin_dashboard.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  const MyApp({super.key, required this.settingsService});

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
  late final FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _firestore = FirebaseFirestore.instance;
  }

  Future<_ResolvedSession> _resolveSession() async {
    final current = _authController.currentUser;
    if (current == null) {
      return const _ResolvedSession.guest();
    }

    final email = current.email.trim();
    QuerySnapshot<Map<String, dynamic>> adminSnapshot;

    if (email.isNotEmpty) {
      adminSnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
    } else {
      adminSnapshot = await _firestore
          .collection('admins')
          .where('uid', isEqualTo: current.uid)
          .limit(1)
          .get();
    }

    if (adminSnapshot.docs.isNotEmpty) {
      final adminData = adminSnapshot.docs.first.data();
      return _ResolvedSession.admin(
        role: adminData['role'] as String?,
        matricule: (adminData['matricule'] ?? '').toString(),
        name: adminData['name'] as String?,
      );
    }

    return const _ResolvedSession.user();
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

        // Authenticated session: route based on role source in Firestore.
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<_ResolvedSession>(
            future: _resolveSession(),
            builder: (context, resolvedSnapshot) {
              if (resolvedSnapshot.connectionState != ConnectionState.done) {
                return const SplashScreen();
              }

              final resolved = resolvedSnapshot.data;

              if (resolved?.isAdmin == true) {
                return AdminDashboard(
                  role: resolved!.adminRole,
                  matricule: resolved.adminMatricule,
                  adminName: resolved.adminName,
                  settingsService: widget.settingsService,
                  onThemeChanged: widget.onThemeChanged,
                  onLanguageChanged: widget.onLanguageChanged,
                );
              }

              return _BanWatcher(
                uid: snapshot.data!.uid,
                child: HomeScreen(
                  settingsService: widget.settingsService,
                  onThemeChanged: widget.onThemeChanged,
                  onLanguageChanged: widget.onLanguageChanged,
                ),
              );
            },
          );
        }

        // User is logged out
        return AuthScreen(
          settingsService: widget.settingsService,
          onThemeChanged: widget.onThemeChanged,
          onLanguageChanged: widget.onLanguageChanged,
        );
      },
    );
  }
}

class _ResolvedSession {
  const _ResolvedSession._({
    required this.isAuthenticated,
    required this.isAdmin,
    this.adminRole,
    this.adminMatricule,
    this.adminName,
  });

  const _ResolvedSession.guest()
    : this._(isAuthenticated: false, isAdmin: false);

  const _ResolvedSession.user() : this._(isAuthenticated: true, isAdmin: false);

  const _ResolvedSession.admin({String? role, String? matricule, String? name})
    : this._(
        isAuthenticated: true,
        isAdmin: true,
        adminRole: role,
        adminMatricule: matricule,
        adminName: name,
      );

  final bool isAuthenticated;
  final bool isAdmin;
  final String? adminRole;
  final String? adminMatricule;
  final String? adminName;
}

/// Watches the signed-in user's Firestore document in real-time.
/// Shows a dialog and signs the user out if an admin bans or blocks them
/// while they are actively using the app.
class _BanWatcher extends StatefulWidget {
  final String uid;
  final Widget child;

  const _BanWatcher({required this.uid, required this.child});

  @override
  State<_BanWatcher> createState() => _BanWatcherState();
}

class _BanWatcherState extends State<_BanWatcher> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  String? _lastStatus;
  bool _dialogActive = false;

  @override
  void initState() {
    super.initState();
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .snapshots()
        .listen(_onUserDoc);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onUserDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists || !mounted) return;
    final data = snap.data()!;
    final status = (data['status'] ?? 'active').toString();

    // First snapshot — record baseline only, no dialog.
    if (_lastStatus == null) {
      _lastStatus = status;
      return;
    }

    // Trigger only on active → banned/blocked transition.
    if (!_dialogActive &&
        _lastStatus == 'active' &&
        (status == 'banned' || status == 'blocked')) {
      _lastStatus = status;
      _showBanDialog(status, data['banUntil']);
    } else {
      _lastStatus = status;
    }
  }

  Future<void> _showBanDialog(String status, dynamic banUntilRaw) async {
    _dialogActive = true;

    final String title;
    final String message;

    if (status == 'blocked') {
      title = 'Account Blocked';
      message =
          'Your account has been permanently blocked by an administrator.';
    } else {
      title = 'Account Banned';
      DateTime? banUntil;
      if (banUntilRaw is Timestamp) banUntil = banUntilRaw.toDate();
      if (banUntil != null) {
        final y = banUntil.year.toString().padLeft(4, '0');
        final mo = banUntil.month.toString().padLeft(2, '0');
        final d = banUntil.day.toString().padLeft(2, '0');
        final h = banUntil.hour.toString().padLeft(2, '0');
        final mi = banUntil.minute.toString().padLeft(2, '0');
        message = 'Your account has been banned until $y-$mo-$d $h:$mi.';
      } else {
        message = 'Your account has been banned by an administrator.';
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    _dialogActive = false;
    // Sign out after the user dismisses the dialog.
    await fb_auth.FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
