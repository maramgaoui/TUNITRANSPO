import 'package:flutter/material.dart';
import 'package:tuni_transport/admin/screens/manage_users_screen.dart';
import 'package:tuni_transport/admin/screens/admin_profile_screen.dart';
import 'package:tuni_transport/controllers/notification_controller.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/models/notification_model.dart';
import 'package:tuni_transport/screens/chat_screen.dart';
import 'package:tuni_transport/services/settings_service.dart';
import 'package:tuni_transport/theme/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    super.key,
    this.role,
    this.matricule,
    this.adminName,
    this.settingsService,
    this.onThemeChanged,
    this.onLanguageChanged,
  });

  final String? role;
  final String? matricule;
  final String? adminName;
  final SettingsService? settingsService;
  final Function(ThemeMode)? onThemeChanged;
  final ValueChanged<String>? onLanguageChanged;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pages = <Widget>[
      _DashboardTab(role: widget.role),
      ChatScreen(
        isAdminMode: true,
        adminMatricule: widget.matricule,
        adminName: widget.adminName,
        adminRole: widget.role,
      ),
      const _AdminNotificationsTab(),
      _AdminEditTab(
        settingsService: widget.settingsService,
        onThemeChanged: widget.onThemeChanged,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_selectedIndex) {
          0 => l10n.adminDashboard,
          1 => l10n.messages,
          2 => l10n.notifications,
          _ => l10n.settings,
        }),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminProfileScreen(
                    matricule: widget.matricule,
                    role: widget.role,
                    adminName: widget.adminName,
                    settingsService: widget.settingsService,
                    onThemeChanged: widget.onThemeChanged,
                    onLanguageChanged: widget.onLanguageChanged,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            NotificationController.instance.markAllChatAsRead();
          }
          setState(() => _selectedIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: l10n.adminDashboard,
          ),
          BottomNavigationBarItem(
            icon: ListenableBuilder(
              listenable: NotificationController.instance,
              builder: (context, _) {
                final unread = NotificationController.instance.unreadChatCount;
                if (unread == 0) {
                  return const Icon(Icons.chat_bubble_outline);
                }
                return Badge(
                  label: Text(unread > 99 ? '99+' : unread.toString()),
                  child: const Icon(Icons.chat_bubble_outline),
                );
              },
            ),
            activeIcon: const Icon(Icons.chat_bubble),
            label: l10n.messages,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_none),
            activeIcon: const Icon(Icons.notifications),
            label: l10n.notifications,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.edit_outlined),
            activeIcon: const Icon(Icons.edit),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({this.role});

  final String? role;

  static const int _actionManageUsers = 0;
  static const int _actionManageJourneys = 1;
  static const int _actionManageStations = 2;
  static const int _actionSendNotifications = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (role != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                l10n.connectedRole(role!),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          _buildActionButton(
            context,
            label: l10n.manageUsers,
            icon: Icons.people_outline,
            actionId: _actionManageUsers,
          ),
          _buildActionButton(
            context,
            label: l10n.manageJourneys,
            icon: Icons.route_outlined,
            actionId: _actionManageJourneys,
          ),
          _buildActionButton(
            context,
            label: l10n.manageStations,
            icon: Icons.train_outlined,
            actionId: _actionManageStations,
          ),
          _buildActionButton(
            context,
            label: l10n.sendNotifications,
            icon: Icons.notifications_active_outlined,
            actionId: _actionSendNotifications,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required int actionId,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: () {
          if (actionId == _actionManageUsers) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.featureReadyToBeConnected(label))),
          );
        },
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _AdminEditTab extends StatefulWidget {
  const _AdminEditTab({
    required this.settingsService,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  final SettingsService? settingsService;
  final Function(ThemeMode)? onThemeChanged;
  final ValueChanged<String>? onLanguageChanged;

  @override
  State<_AdminEditTab> createState() => _AdminEditTabState();
}

class _AdminNotificationsTab extends StatelessWidget {
  const _AdminNotificationsTab();

  static const String _l10nPrefix = 'l10n:';

  String _resolveL10nToken(AppLocalizations l10n, String value) {
    if (!value.startsWith(_l10nPrefix)) {
      return value;
    }

    final key = value.substring(_l10nPrefix.length);
    switch (key) {
      case 'newNotificationTitle':
        return l10n.newNotificationTitle;
      case 'receivedNotificationBody':
        return l10n.receivedNotificationBody;
      case 'newMessageNotification':
        return l10n.newMessageNotification;
      case 'newJourneyNotification':
        return l10n.newJourneyNotification;
      case 'systemAnnouncementTitle':
        return l10n.systemAnnouncementTitle;
      case 'systemWelcomeBody':
        return l10n.systemWelcomeBody;
      default:
        return value;
    }
  }

  String _localizedTitle(AppLocalizations l10n, NotificationModel item) {
    final tokenResolved = _resolveL10nToken(l10n, item.title);
    if (tokenResolved != item.title) {
      return tokenResolved;
    }

    switch (item.title) {
      case 'Nouveau message':
      case 'New message':
        return l10n.newMessageNotification;
      case 'Nouveau trajet cree':
      case 'Nouveau trajet créé':
      case 'New journey created':
        return l10n.newJourneyNotification;
      case 'Annonce systeme':
      case 'Annonce système':
      case 'System announcement':
        return l10n.systemAnnouncementTitle;
      case 'Nouvelle notification':
      case 'New notification':
        return l10n.newNotificationTitle;
      default:
        return item.title;
    }
  }

  String _localizedBody(AppLocalizations l10n, NotificationModel item) {
    final tokenResolved = _resolveL10nToken(l10n, item.body);
    if (tokenResolved != item.body) {
      return tokenResolved;
    }

    switch (item.body) {
      case 'Vous avez recu une notification':
      case 'Vous avez reçu une notification':
      case 'You received a notification':
        return l10n.receivedNotificationBody;
      case 'Bienvenue sur TuniTranspo. Bonne navigation!':
      case 'Welcome to TuniTranspo. Enjoy your trip!':
        return l10n.systemWelcomeBody;
      default:
        return item.body;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = NotificationController.instance;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final items = controller.notifications;

        if (items.isEmpty) {
          return Center(
            child: Text(
              l10n.noNotificationsYet,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    l10n.notifications,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: controller.unreadCount == 0
                        ? null
                        : controller.markAllAsRead,
                    icon: const Icon(Icons.done_all),
                    label: Text(l10n.markAllAsRead),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: Icon(
                      item.isRead
                          ? Icons.notifications_outlined
                          : Icons.notifications_active,
                    ),
                    title: Text(_localizedTitle(l10n, item)),
                    subtitle: Text(_localizedBody(l10n, item)),
                    trailing: Text(
                      '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                    onTap: () => controller.markAsRead(item.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminEditTabState extends State<_AdminEditTab> {
  late final SettingsService _settingsService;
  bool _isReady = false;
  String _themeValue = 'light';
  String _languageValue = 'fr';

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService ?? SettingsService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (widget.settingsService == null) {
      await _settingsService.init();
    }

    if (!mounted) return;

    setState(() {
      _themeValue = _settingsService.getThemeMode();
      _languageValue = _settingsService.getLanguage();
      _isReady = true;
    });
  }

  Future<void> _changeTheme(String value) async {
    await _settingsService.setThemeMode(value);

    final themeMode = switch (value) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };

    widget.onThemeChanged?.call(themeMode);

    if (!mounted) return;
    setState(() => _themeValue = value);
  }

  Future<void> _changeLanguage(String value) async {
    await _settingsService.setLanguage(value);
    widget.onLanguageChanged?.call(value);

    if (!mounted) return;
    setState(() => _languageValue = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.settings,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _themeValue,
              decoration: InputDecoration(
                labelText: l10n.themeMode,
                prefixIcon: const Icon(Icons.palette_outlined),
              ),
              items: [
                DropdownMenuItem(value: 'light', child: Text(l10n.lightMode)),
                DropdownMenuItem(value: 'dark', child: Text(l10n.darkMode)),
                DropdownMenuItem(
                  value: 'system',
                  child: Text(l10n.systemDefault),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _changeTheme(value);
                }
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _languageValue,
              decoration: InputDecoration(
                labelText: l10n.language,
                prefixIcon: const Icon(Icons.language_outlined),
              ),
              items: [
                DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
                DropdownMenuItem(value: 'ar', child: Text(l10n.arabic)),
              ],
              onChanged: (value) {
                if (value != null) {
                  _changeLanguage(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
