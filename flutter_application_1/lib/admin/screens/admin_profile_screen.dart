import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/admin/controllers/admin_auth_controller.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/services/settings_service.dart';
import 'package:tuni_transport/theme/app_theme.dart';
import 'package:tuni_transport/utils/validation_utils.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({
    super.key,
    this.matricule,
    this.role,
    this.adminName,
    this.settingsService,
    this.onThemeChanged,
    this.onLanguageChanged,
  });

  final String? matricule;
  final String? role;
  final String? adminName;
  final SettingsService? settingsService;
  final Function(ThemeMode)? onThemeChanged;
  final ValueChanged<String>? onLanguageChanged;

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminAuthController _adminAuthController = AdminAuthController();

  bool _isLoading = true;
  bool _isSigningOut = false;
  String? _errorMessage;
  String? _name;
  String? _matricule;
  String? _role;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    // We prioritize Firestore data so profile values stay up to date.
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot;

      if (widget.matricule != null && widget.matricule!.trim().isNotEmpty) {
        querySnapshot = await _firestore
            .collection('admins')
            .where('matricule', isEqualTo: widget.matricule!.trim())
            .limit(1)
            .get();
      } else {
        querySnapshot = await _firestore.collection('admins').limit(1).get();
      }

      if (!mounted) {
        return;
      }

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _name = widget.adminName;
          _matricule = widget.matricule;
          _role = widget.role;
          _errorMessage = 'Admin profile not found in Firestore.';
          _isLoading = false;
        });
        return;
      }

      final adminData = querySnapshot.docs.first.data();
      setState(() {
        _name = (adminData['name'] as String?)?.trim().isNotEmpty == true
            ? adminData['name'] as String
            : widget.adminName;
        _matricule = adminData['matricule']?.toString() ?? widget.matricule;
        _role = (adminData['role'] as String?) ?? widget.role;
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _name = widget.adminName;
        _matricule = widget.matricule;
        _role = widget.role;
        _errorMessage = e.message ?? 'Failed to load admin profile.';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _name = widget.adminName;
        _matricule = widget.matricule;
        _role = widget.role;
        _errorMessage = 'Unexpected error while loading admin profile.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.confirmSignOut),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false) || !mounted) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      // Clear Firebase auth session (if any) then reset navigation stack.
      await _adminAuthController.signOut();

      if (!mounted) {
        return;
      }

      context.go('/auth');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSigningOut = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to logout. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleChangePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) => AlertDialog(
            title: Row(
              children: [
                const Expanded(
                  child: Text('Changer le mot de passe'),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    FocusScope.of(dialogContext).unfocus();
                    Navigator.of(dialogContext).pop(false);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe actuel',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureCurrent = !obscureCurrent;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le mot de passe actuel est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                      validator: ValidationUtils.validatePassword,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le nouveau mot de passe',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                      validator: (value) => ValidationUtils
                          .validateConfirmPassword(
                            value,
                            newPasswordController.text,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  FocusScope.of(dialogContext).unfocus();
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    FocusScope.of(dialogContext).unfocus();
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                child: const Text('Mettre à jour'),
              ),
            ],
          ),
        );
      },
    );

    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (shouldSubmit != true || !mounted) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      await _adminAuthController.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        matricule: _matricule,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe mis a jour avec succes.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppTheme.primaryTeal.withValues(
                              alpha: 0.14,
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 44,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _name?.isNotEmpty == true ? _name! : 'Admin',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _InfoTile(
                            label: l10n.matricule,
                            value: _matricule?.isNotEmpty == true
                                ? _matricule!
                                : '-',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 10),
                          _InfoTile(
                            label: l10n.role,
                            value: _role?.isNotEmpty == true ? _role! : '-',
                            icon: Icons.workspace_premium_outlined,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: _isChangingPassword
                                ? null
                                : _handleChangePassword,
                            icon: _isChangingPassword
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.lock_reset_outlined),
                            label: const Text('Changer le mot de passe'),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isSigningOut ? null : _handleLogout,
                            icon: _isSigningOut
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.logout),
                            label: Text(l10n.logout),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.primaryTeal.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
