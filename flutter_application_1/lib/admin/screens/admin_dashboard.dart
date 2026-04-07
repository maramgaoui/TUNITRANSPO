import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/controllers/notification_controller.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/screens/chat_screen.dart';
import 'package:tuni_transport/services/settings_service.dart';
import 'package:tuni_transport/theme/app_theme.dart';
import 'package:tuni_transport/utils/notification_l10n.dart';

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
      appBar: _selectedIndex == 1
          ? null
          : AppBar(
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
                    final role = Uri.encodeComponent(widget.role ?? '');
                    final matricule = Uri.encodeComponent(widget.matricule ?? '');
                    final name = Uri.encodeComponent(widget.adminName ?? '');
                    context.push('/admin/profile?role=$role&matricule=$matricule&name=$name');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = <_AdminAction>[
      _AdminAction(
        labelKey: (l) => l.manageUsers,
        icon: Icons.people_outline,
        onTap: (ctx) => ctx.push('/admin/manage-users'),
      ),
      _AdminAction(
        labelKey: (l) => l.manageJourneys,
        icon: Icons.route_outlined,
        onTap: (ctx) => ctx.push('/admin/manage-journeys'),
      ),
      _AdminAction(
        labelKey: (l) => l.manageStations,
        icon: Icons.train_outlined,
        onTap: (ctx) => ctx.push('/admin/manage-stations'),
      ),
      _AdminAction(
        labelKey: (l) => l.sendNotifications,
        icon: Icons.notifications_active_outlined,
        onTap: (ctx) => ctx.push('/admin/send-notifications'),
      ),
    ];

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
          ...actions.map((action) {
            final label = action.labelKey(l10n);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () => action.onTap(context),
                icon: Icon(action.icon),
                label: Text(label),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AdminAction {
  const _AdminAction({
    required this.labelKey,
    required this.icon,
    required this.onTap,
  });

  final String Function(AppLocalizations) labelKey;
  final IconData icon;
  final void Function(BuildContext) onTap;
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
                    title: Text(NotificationL10n.localizedTitle(l10n, item)),
                    subtitle: Text(NotificationL10n.localizedBody(l10n, item)),
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
              initialValue: _themeValue,
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
              initialValue: _languageValue,
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
