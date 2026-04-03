import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import '../services/settings_service.dart';
import 'journey_input_screen.dart';
import 'favorites_screen.dart';
import 'notification_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final SettingsService settingsService;
  final Function(ThemeMode) onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  
  const HomeScreen({
    super.key,
    required this.settingsService,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndexFromLocation(String path) {
    if (path.startsWith('/home/favorites')) return 1;
    if (path.startsWith('/home/notifications')) return 2;
    if (path.startsWith('/home/chat')) return 3;
    if (path.startsWith('/home/profile')) return 4;
    return 0;
  }

  String _pathForIndex(int index) {
    switch (index) {
      case 1:
        return '/home/favorites';
      case 2:
        return '/home/notifications';
      case 3:
        return '/home/chat';
      case 4:
        return '/home/profile';
      case 0:
      default:
        return '/home/journey-input';
    }
  }

  List<Widget> _buildScreens() {
    return [
      const JourneyInputScreen(),
      const FavoritesScreen(),
      const NotificationScreen(),
      const ChatScreen(),
      ProfileScreen(
        settingsService: widget.settingsService,
        onThemeChanged: widget.onThemeChanged,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screens = _buildScreens();
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _tabIndexFromLocation(path);

    // Wrap the shell in inherited text direction to keep RTL/LTR behavior consistent.
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        body: screens[selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: (index) => context.go(_pathForIndex(index)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: l10n.journeys,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: l10n.favorites,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none),
              activeIcon: Icon(Icons.notifications),
              label: l10n.notifications,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: l10n.messages,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}
