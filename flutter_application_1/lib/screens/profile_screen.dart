import 'package:flutter/material.dart';
import 'package:avatar_plus/avatar_plus.dart';
import 'package:tuni_transport/constants/avatar_options.dart';
import 'package:tuni_transport/controllers/profile_controller.dart';
import 'package:tuni_transport/controllers/auth_controller.dart';
import 'package:tuni_transport/models/profile_model.dart';
import 'package:tuni_transport/services/settings_service.dart';
import 'package:tuni_transport/utils/validation_utils.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final SettingsService settingsService;
  final Function(ThemeMode) onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  
  const ProfileScreen({
    super.key,
    required this.settingsService,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileController _profileController;
  late AuthController _authController;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _lastSyncedProfileFingerprint;
  late String _selectedLanguage;
  late ThemeMode _themeMode;

  // Text controllers for editing
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _cityController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController();
    _authController = AuthController();
    
    // Load saved preferences
    _selectedLanguage = widget.settingsService.getLanguage();
    final themeSetting = widget.settingsService.getThemeMode();
    _themeMode = themeSetting == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _cityController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _loadProfileData(Profile profile) {
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _usernameController.text = profile.username ?? '';
    _cityController.text = profile.city ?? '';
  }

  String _profileFingerprint(Profile profile) {
    return [
      profile.uid,
      profile.email,
      profile.firstName ?? '',
      profile.lastName ?? '',
      profile.username ?? '',
      profile.city ?? '',
      profile.avatarId ?? '',
    ].join('|');
  }

  Future<void> _saveProfile(Profile profile) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final username = _usernameController.text.trim();
      final city = _cityController.text.trim();

      final updatedProfile = profile.copyWith(
        firstName: firstName,
        lastName: lastName,
        username: username,
        city: city.isEmpty ? null : city,
      );

      final success = await _profileController.updateProfile(updatedProfile);

      setState(() => _isLoading = false);

      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _authController.signOut();
    }
  }

  Future<void> _showAvatarPicker(Profile profile) async {
    String selectedAvatarId = profile.avatarId ?? avatarOptions.first;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Choisir un avatar'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: avatarOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final avatarId = avatarOptions[index];
                final isSelected = selectedAvatarId == avatarId;
                return GestureDetector(
                  onTap: () => setDialogState(() => selectedAvatarId = avatarId),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryTeal
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: AvatarPlus(
                        avatarId,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
              ),
              child: const Text(
                'Enregistrer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      final success = await _profileController.updateProfileFields({
        'avatarId': selectedAvatarId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Avatar mis à jour' : 'Échec de la mise à jour de l\'avatar',
          ),
          backgroundColor: success ? AppTheme.primaryTeal : Colors.red,
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscureCurrentPassword = !obscureCurrentPassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscureNewPassword = !obscureNewPassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                if (currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez entrer votre mot de passe actuel')),
                  );
                  return;
                }
                if (newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez entrer le nouveau mot de passe')),
                  );
                  return;
                }
                if (confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez confirmer le nouveau mot de passe')),
                  );
                  return;
                }
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
                  );
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le mot de passe doit contenir au moins 6 caractères')),
                  );
                  return;
                }

                final errorMessage = await _profileController.changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );

                if (mounted) {
                  if (errorMessage == null) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mot de passe changé avec succès'),
                        backgroundColor: AppTheme.primaryTeal,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Changer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Paramètres'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Mode Section
                const Text(
                  'Mode de thème',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.lightGrey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: const Text('Mode clair'),
                        value: ThemeMode.light,
                        groupValue: _themeMode,
                        onChanged: (value) {
                          setState(() {
                            _themeMode = value ?? ThemeMode.light;
                          });
                        },
                      ),
                      const Divider(height: 0),
                      RadioListTile<ThemeMode>(
                        title: const Text('Mode sombre'),
                        value: ThemeMode.dark,
                        groupValue: _themeMode,
                        onChanged: (value) {
                          setState(() {
                            _themeMode = value ?? ThemeMode.dark;
                          });
                        },
                      ),
                      const Divider(height: 0),
                      RadioListTile<ThemeMode>(
                        title: const Text('Par défaut du système'),
                        value: ThemeMode.system,
                        groupValue: _themeMode,
                        onChanged: (value) {
                          setState(() {
                            _themeMode = value ?? ThemeMode.system;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Language Section
                const Text(
                  'Langue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.lightGrey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Français'),
                        value: 'Français',
                        groupValue: _selectedLanguage,
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguage = value ?? 'Français';
                          });
                        },
                      ),
                      const Divider(height: 0),
                      RadioListTile<String>(
                        title: const Text('Anglais'),
                        value: 'English',
                        groupValue: _selectedLanguage,
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguage = value ?? 'English';
                          });
                        },
                      ),
                      const Divider(height: 0),
                      RadioListTile<String>(
                        title: const Text('العربية'),
                        value: 'العربية',
                        groupValue: _selectedLanguage,
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguage = value ?? 'العربية';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
              ),
              onPressed: () async {
                // Save language preference
                await widget.settingsService.setLanguage(_selectedLanguage);
                
                // Save and apply theme preference
                final themeString = _themeMode == ThemeMode.dark ? 'dark' : 
                                   _themeMode == ThemeMode.system ? 'system' : 'light';
                await widget.settingsService.setThemeMode(themeString);
                
                // Notify parent of theme change
                widget.onThemeChanged(_themeMode);
                widget.onLanguageChanged(_selectedLanguage);
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Paramètres enregistrés - Mode: ${_themeMode.name}, Langue: $_selectedLanguage',
                      ),
                      backgroundColor: AppTheme.primaryTeal,
                    ),
                  );
                }
              },
              child: const Text(
                'Enregistrer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check),
              onPressed: _isLoading
                  ? null
                  : () async {
                      final profile =
                          await _profileController.getCurrentProfile();
                      if (profile != null && mounted) {
                        await _saveProfile(profile);
                      }
                    },
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: StreamBuilder<Profile?>(
        stream: _profileController.profileStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const Center(
              child: Text('No profile data'),
            );
          }

          if (!_isEditing) {
            final fingerprint = _profileFingerprint(profile);
            if (_lastSyncedProfileFingerprint != fingerprint) {
              _loadProfileData(profile);
              _lastSyncedProfileFingerprint = fingerprint;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      // User avatar with avatar picker
                      Stack(
                        children: [
                          ClipOval(
                            child: AvatarPlus(
                              profile.avatarId ??
                                  (profile.username?.isNotEmpty == true
                                      ? profile.username!
                                      : profile.email),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () => _showAvatarPicker(profile),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Full Name
                      Text(
                        '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Username (if available)
                      if (profile.username != null && profile.username!.isNotEmpty)
                        Text(
                          '@${profile.username}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Email
                      Text(
                        profile.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Profile Form or Details
                if (_isEditing)
                  _buildEditForm()
                else
                  _buildProfileDetails(profile),
                const SizedBox(height: 32),
                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showChangePasswordDialog,
                    icon: const Icon(Icons.lock),
                    label: const Text('Changer le mot de passe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Déconnexion'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileDetails(Profile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Required fields - always show
        _buildDetailRow('Nom d\'utilisateur', profile.username ?? 'Non défini'),
        _buildDetailRow('Prénom', profile.firstName ?? 'Non défini'),
        _buildDetailRow('Nom', profile.lastName ?? 'Non défini'),
        _buildDetailRow('Email', profile.email),
        
        // City with add button if empty
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ville',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mediumGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (profile.city == null || profile.city!.isEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _cityController.clear();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une ville'),
                )
              else
                Text(
                  profile.city!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textDark,
                  ),
                ),
              const Divider(color: AppTheme.lightGrey),
            ],
          ),
        ),
        
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mediumGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textDark,
            ),
          ),
          const Divider(color: AppTheme.lightGrey),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextFormField(
            controller: _firstNameController,
            label: 'Prénom',
            hint: 'Entrez votre prénom',
            icon: Icons.person_outline,
            validator: (value) => ValidationUtils.validateName(
              value?.trim(),
              'Prénom',
            ),
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _lastNameController,
            label: 'Nom',
            hint: 'Entrez votre nom',
            icon: Icons.person_outline,
            validator: (value) => ValidationUtils.validateName(
              value?.trim(),
              'Nom',
            ),
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _usernameController,
            label: 'Nom d\'utilisateur',
            hint: 'Entrez votre nom d\'utilisateur',
            icon: Icons.person_add_outlined,
            validator: (value) => ValidationUtils.validateUsername(
              value?.trim(),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _cityController,
            label: 'Ville',
            hint: 'Entrez votre ville',
            icon: Icons.location_city_outlined,
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return null;
              return ValidationUtils.validateName(trimmed, 'Ville');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppTheme.primaryTeal,
            width: 2,
          ),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
