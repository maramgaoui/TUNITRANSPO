import 'package:flutter/material.dart';
import 'package:tuni_transport/controllers/profile_controller.dart';
import 'package:tuni_transport/controllers/auth_controller.dart';
import 'package:tuni_transport/models/profile_model.dart';
import 'package:tuni_transport/services/settings_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final SettingsService settingsService;
  final Function(ThemeMode) onThemeChanged;
  
  const ProfileScreen({
    super.key,
    required this.settingsService,
    required this.onThemeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileController _profileController;
  late AuthController _authController;
  bool _isEditing = false;
  bool _isLoading = false;
  late String _selectedLanguage;
  late ThemeMode _themeMode;

  // Text controllers for editing
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _bioController;

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
    _phoneNumberController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _countryController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadProfileData(Profile profile) {
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _usernameController.text = profile.username ?? '';
    _phoneNumberController.text = profile.phoneNumber ?? '';
    _addressController.text = profile.address ?? '';
    _cityController.text = profile.city ?? '';
    _countryController.text = profile.country ?? '';
    _bioController.text = profile.bio ?? '';
  }

  Future<void> _saveProfile(Profile profile) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final updatedProfile = profile.copyWith(
        firstName: _firstNameController.text.isEmpty
            ? null
            : _firstNameController.text,
        lastName: _lastNameController.text.isEmpty
            ? null
            : _lastNameController.text,
        username: _usernameController.text.isEmpty
            ? null
            : _usernameController.text,
        phoneNumber: _phoneNumberController.text.isEmpty
            ? null
            : _phoneNumberController.text,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        country:
            _countryController.text.isEmpty ? null : _countryController.text,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
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
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
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

                final success = await _profileController.changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mot de passe changé avec succès'),
                        backgroundColor: AppTheme.primaryTeal,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Échec du changement de mot de passe'),
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

          if (!_isEditing) _loadProfileData(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      // Profile Avatar
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.lightTeal,
                          shape: BoxShape.circle,
                          image: profile.photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(profile.photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: profile.photoUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                            : null,
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
        
        // Phone number with add button if empty
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Numéro de téléphone',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mediumGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (profile.phoneNumber == null || profile.phoneNumber!.isEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _phoneNumberController.clear();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un numéro de téléphone'),
                )
              else
                Text(
                  profile.phoneNumber!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textDark,
                  ),
                ),
              const Divider(color: AppTheme.lightGrey),
            ],
          ),
        ),
        
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
        
        // Optional fields - only show if not empty
        if (profile.address != null && profile.address!.isNotEmpty)
          _buildDetailRow('Adresse', profile.address!),
        if (profile.country != null && profile.country!.isNotEmpty)
          _buildDetailRow('Pays', profile.country!),
        if (profile.bio != null && profile.bio!.isNotEmpty)
          _buildDetailRow('Bio', profile.bio!),
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
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _lastNameController,
            label: 'Nom',
            hint: 'Entrez votre nom',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _usernameController,
            label: 'Nom d\'utilisateur',
            hint: 'Entrez votre nom d\'utilisateur',
            icon: Icons.person_add_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _phoneNumberController,
            label: 'Numéro de téléphone',
            hint: 'Entrez votre numéro de téléphone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _addressController,
            label: 'Adresse',
            hint: 'Entrez votre adresse',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _cityController,
            label: 'Ville',
            hint: 'Entrez votre ville',
            icon: Icons.location_city_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _countryController,
            label: 'Pays',
            hint: 'Entrez votre pays',
            icon: Icons.public_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _bioController,
            label: 'Bio',
            hint: 'Parlez-nous de vous',
            icon: Icons.description_outlined,
            maxLines: 3,
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
      validator: (value) {
        // Add custom validation if needed
        return null;
      },
    );
  }
}
