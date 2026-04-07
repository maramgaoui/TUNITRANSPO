import 'package:flutter/material.dart';
import 'package:avatar_plus/avatar_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/controllers/auth_controller.dart';
import 'package:tuni_transport/constants/avatar_options.dart';
import 'package:tuni_transport/services/settings_service.dart';
import 'package:tuni_transport/utils/validation_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/validated_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.settingsService,
    this.onThemeChanged,
    this.onLanguageChanged,
  });

  final SettingsService? settingsService;
  final Function(ThemeMode)? onThemeChanged;
  final ValueChanged<String>? onLanguageChanged;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  String _selectedAvatarId = avatarOptions.first;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNomController = TextEditingController();
  final _signupPrenomController = TextEditingController();
  final _signupUsernameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  final _authController = AuthController.instance;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to password field changes to trigger confirm password revalidation
    _signupPasswordController.addListener(() {
      setState(() {
        // Trigger rebuild to revalidate confirm password
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNomController.dispose();
    _signupPrenomController.dispose();
    _signupUsernameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.resetPasswordTitle),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.resetPasswordPrompt,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    hintText: 'votre@email.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      ValidationUtils.validateEmail(value?.trim()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext);

                  // Show loading
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.sendingResetLink),
                      backgroundColor: AppTheme.primaryTeal,
                    ),
                  );

                  try {
                    await _authController.sendPasswordResetEmail(
                      emailController.text.trim(),
                    );

                    if (!mounted) {
                      return;
                    }

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.resetLinkSent),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) {
                      return;
                    }

                    final errorMsg = e.toString().replaceAll('Exception: ', '');
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorPrefix(errorMsg)),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: Text(
                l10n.send,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } finally {
      emailController.dispose();
    }
  }

  Future<void> _handleLogin() async {
    // Validate form first - triggers all validators
    final isFormValid = _loginFormKey.currentState!.validate();
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = isFormValid;
      if (!isFormValid) {
        _errorMessage = l10n.fixFormErrors;
      }
    });

    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillAllFieldsCorrectly),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _authController.signInWithEmail(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loginSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? l10n.loginFailed),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignUp() async {
    // Validate form first - triggers all validators
    final isFormValid = _signupFormKey.currentState!.validate();
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = isFormValid;
      if (!isFormValid) {
        _errorMessage = l10n.fixFormErrors;
      }
    });

    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillAllFieldsCorrectly),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _authController.signUpWithEmail(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text,
        firstName: _signupPrenomController.text.trim(),
        lastName: _signupNomController.text.trim(),
        username: _signupUsernameController.text.trim(),
        avatarId: _selectedAvatarId,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.signupSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? l10n.signupFailed),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authController.signInWithGoogle();

      // Give a moment for AuthGuard stream to detect the change
      await Future.delayed(const Duration(milliseconds: 500));

      // Auth state change triggers AuthGuard to rebuild and show HomeScreen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.googleSignInSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage ?? AppLocalizations.of(context)!.googleSignInFailed,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'TuniTransport',
              subtitle: l10n.authHeaderSubtitle,
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              trailing: const SizedBox(width: 60),
            ),
            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryTeal,
              unselectedLabelColor: AppTheme.mediumGrey,
              indicatorColor: AppTheme.primaryTeal,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Text(
                    l10n.login,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Tab(
                  child: Text(
                    l10n.register,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildLoginTab(), _buildSignupTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              l10n.welcomeTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.signInToContinue,
              style: TextStyle(fontSize: 14, color: AppTheme.mediumGrey),
            ),
            const SizedBox(height: 28),
            // Email field with real-time validation
            ValidatedTextField(
              controller: _loginEmailController,
              label: l10n.email,
              hintText: 'votre@email.com',
              prefixIcon: Icons.email_outlined,
              validationType: 'email',
            ),
            const SizedBox(height: 16),
            // Password field with real-time validation
            ValidatedTextField(
              controller: _loginPasswordController,
              label: l10n.password,
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline,
              validationType: 'password',
              obscureText: _obscureLoginPassword,
              isPasswordField: true,
              onVisibilityToggle: () {
                setState(() => _obscureLoginPassword = !_obscureLoginPassword);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                child: Text(l10n.forgotPasswordShort),
              ),
            ),
            const SizedBox(height: 24),
            // Login button - enabled only when both fields are valid
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.login),
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: AppTheme.lightGrey),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.orLabel,
                    style: TextStyle(color: AppTheme.mediumGrey),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: AppTheme.lightGrey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Social login buttons
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: const Icon(Icons.g_mobiledata),
                label: Text(l10n.signInWithGoogle),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        context.push('/admin/login');
                      },
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: Text(l10n.loginAsAdmin),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupTab() {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              l10n.createAccountTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.joinTuniTranspo,
              style: TextStyle(fontSize: 14, color: AppTheme.mediumGrey),
            ),
            const SizedBox(height: 28),
            // Nom field with real-time validation (letters only)
            ValidatedTextField(
              controller: _signupNomController,
              label: l10n.lastName,
              hintText: l10n.lastName,
              prefixIcon: Icons.person_outline,
              validationType: 'name',
              nameFieldType: l10n.lastName,
            ),
            const SizedBox(height: 16),
            // Prénom field with real-time validation (letters only)
            ValidatedTextField(
              controller: _signupPrenomController,
              label: l10n.firstName,
              hintText: l10n.firstName,
              prefixIcon: Icons.person_outline,
              validationType: 'name',
              nameFieldType: l10n.firstName,
            ),
            const SizedBox(height: 16),
            // Username field with real-time validation (letters and numbers)
            ValidatedTextField(
              controller: _signupUsernameController,
              label: l10n.username,
              hintText: l10n.username,
              prefixIcon: Icons.person_add_outlined,
              validationType: 'username',
            ),
            const SizedBox(height: 16),
            // Email field with real-time validation
            ValidatedTextField(
              controller: _signupEmailController,
              label: l10n.email,
              hintText: 'votre@email.com',
              prefixIcon: Icons.email_outlined,
              validationType: 'email',
            ),
            const SizedBox(height: 16),
            // Password field with real-time validation and strength indicator
            ValidatedTextField(
              controller: _signupPasswordController,
              label: l10n.password,
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline,
              validationType: 'password',
              obscureText: _obscureSignupPassword,
              isPasswordField: true,
              onVisibilityToggle: () {
                setState(
                  () => _obscureSignupPassword = !_obscureSignupPassword,
                );
              },
            ),
            const SizedBox(height: 16),
            // Confirm password field with real-time validation
            ValidatedTextField(
              controller: _signupConfirmPasswordController,
              label: l10n.confirmNewPassword,
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline,
              validationType: 'confirm_password',
              confirmPasswordValue: _signupPasswordController.text,
              obscureText: _obscureConfirmPassword,
              isPasswordField: true,
              onVisibilityToggle: () {
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              l10n.chooseAvatar,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 210,
              child: GridView.builder(
                itemCount: avatarOptions.length,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final avatarId = avatarOptions[index];
                  final isSelected = avatarId == _selectedAvatarId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatarId = avatarId),
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
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Signup button - validation handled by Form.validate() on submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.register),
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: AppTheme.lightGrey),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.orLabel,
                    style: TextStyle(color: AppTheme.mediumGrey),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: AppTheme.lightGrey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Social signup button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: const Icon(Icons.g_mobiledata),
                label: Text(l10n.signUpWithGoogle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
