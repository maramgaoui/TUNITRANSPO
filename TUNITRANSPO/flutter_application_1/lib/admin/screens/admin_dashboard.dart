import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/controllers/auth_controller.dart';
import 'package:tuni_transport/models/session_result.dart';
import 'package:tuni_transport/controllers/notification_controller.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/screens/chat_screen.dart';
import 'package:tuni_transport/theme/app_theme.dart';
import 'package:tuni_transport/utils/notification_l10n.dart';
import 'package:tuni_transport/widgets/app_settings.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  SessionResult? _session;

  @override
  void initState() {
    super.initState();
    _resolveTrustedSession();
  }

  Future<void> _resolveTrustedSession() async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      context.go('/admin/login');
      return;
    }

    try {
      final session = await AuthController.instance.resolveSession(currentUser);

      if (!mounted) return;

      if (session.isGuest) {
        context.go('/admin/login');
        return;
      }

      setState(() {
        _session = session;
      });
    } catch (_) {
      if (!mounted) return;
      context.go('/admin/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;
    final trustedRole = _session?.adminRole;

    final pages = <Widget>[
      _DashboardTab(role: trustedRole),
      ChatScreen(
        isAdminMode: true,
        adminMatricule: _session?.adminMatricule,
        adminName: _session?.adminName,
        adminRole: trustedRole,
      ),
      const _AdminNotificationsTab(),
      const _AdminEditTab(),
    ];

    return Scaffold(
      key: const Key('admin_dashboard_screen'),
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
                    context.push('/admin/profile');
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
  const _AdminEditTab();

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
                separatorBuilder: (_, __) => const Divider(height: 1),
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
  bool _isReady = false;
  String _themeValue = 'light';
  String _languageValue = 'fr';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isReady) {
      final settings = AppSettings.of(context);
      _themeValue = settings.settingsService.getThemeMode();
      _languageValue = settings.settingsService.getLanguage();
      _isReady = true;
    }
  }

  Future<void> _changeTheme(String value) async {
    final settings = AppSettings.of(context);
    await settings.settingsService.setThemeMode(value);

    final themeMode = switch (value) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };

    settings.onThemeChanged(themeMode);

    if (!mounted) return;
    setState(() => _themeValue = value);
  }

  Future<void> _changeLanguage(String value) async {
    final settings = AppSettings.of(context);
    await settings.settingsService.setLanguage(value);
    settings.onLanguageChanged(value);

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
