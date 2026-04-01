import 'package:flutter/material.dart';
import 'package:tuni_transport/controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/validated_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

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

  // Validation state tracking
  bool _isLoginEmailValid = false;
  bool _isLoginPasswordValid = false;
  bool _isSignupNomValid = false;
  bool _isSignupPrenomValid = false;
  bool _isSignupUsernameValid = false;
  bool _isSignupEmailValid = false;
  bool _isSignupPasswordValid = false;
  bool _isSignupConfirmPasswordValid = false;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNomController = TextEditingController();
  final _signupPrenomController = TextEditingController();
  final _signupUsernameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  final _authController = AuthController();
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
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Entrez votre adresse email pour recevoir un lien de réinitialisation',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'votre@email.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
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
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Envoi du lien de réinitialisation...'),
                    backgroundColor: AppTheme.primaryTeal,
                  ),
                );

                try {
                  await _authController.sendPasswordResetEmail(
                    emailController.text.trim(),
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vérifiez votre email pour le lien de réinitialisation'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    final errorMsg = e.toString().replaceAll('Exception: ', '');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $errorMsg'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text(
              'Envoyer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Validate form first - triggers all validators
    final isFormValid = _loginFormKey.currentState!.validate();
    
    setState(() {
      _isLoading = isFormValid;
      if (!isFormValid) {
        _errorMessage = 'Veuillez corriger les erreurs du formulaire';
      }
    });

    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs correctement'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Double-check validation state flags
    if (!_isLoginEmailValid || !_isLoginPasswordValid) {
      setState(() {
        _errorMessage = 'Veuillez corriger toutes les erreurs de validation';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email ou mot de passe invalide'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
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
          const SnackBar(
            content: Text('Connexion réussie!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
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
            content: Text(_errorMessage ?? 'Connexion échouée'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleSignUp() async {
    // Validate form first - triggers all validators
    final isFormValid = _signupFormKey.currentState!.validate();
    
    setState(() {
      _isLoading = isFormValid;
      if (!isFormValid) {
        _errorMessage = 'Veuillez corriger les erreurs du formulaire';
      }
    });

    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs correctement'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Double-check all validation state flags
    if (!_isSignupNomValid ||
        !_isSignupPrenomValid ||
        !_isSignupUsernameValid ||
        !_isSignupEmailValid ||
        !_isSignupPasswordValid ||
        !_isSignupConfirmPasswordValid) {
      setState(() {
        _errorMessage = 'Veuillez corriger toutes les erreurs de validation';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tous les champs doivent être valides'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await _authController.signUpWithEmail(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text,
        firstName: _signupPrenomController.text.trim(),
        lastName: _signupNomController.text.trim(),
        username: _signupUsernameController.text.trim(),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
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
            content: Text(_errorMessage ?? 'Inscription échouée'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
          const SnackBar(
            content: Text('Signed in with Google!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
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
            content: Text(_errorMessage ?? 'Google sign in failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 80, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryTeal,
                    AppTheme.lightTeal,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Logo
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.directions_bus,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TuniTransport',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Connexion & Inscription',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryTeal,
              unselectedLabelColor: AppTheme.mediumGrey,
              indicatorColor: AppTheme.primaryTeal,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  child: Text(
                    'Connexion',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Tab(
                  child: Text(
                    'S\'inscrire',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(),
                  _buildSignupTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Bienvenue!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connectez-vous pour continuer',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mediumGrey,
              ),
            ),
            const SizedBox(height: 28),
            // Email field with real-time validation
            ValidatedTextField(
              controller: _loginEmailController,
              label: 'Email',
              hintText: 'votre@email.com',
              prefixIcon: Icons.email_outlined,
              validationType: 'email',
              onValidationChanged: (isValid) {
                setState(() => _isLoginEmailValid = isValid);
              },
            ),
            const SizedBox(height: 16),
            // Password field with real-time validation
            ValidatedTextField(
              controller: _loginPasswordController,
              label: 'Mot de passe',
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline,
              validationType: 'password',
              obscureText: _obscureLoginPassword,
              isPasswordField: true,
              onVisibilityToggle: () {
                setState(() => _obscureLoginPassword = !_obscureLoginPassword);
              },
              onValidationChanged: (isValid) {
                setState(() => _isLoginPasswordValid = isValid);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                child: const Text('Oublié?'),
              ),
            ),
            const SizedBox(height: 24),
            // Login button - enabled only when both fields are valid
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || !_isLoginEmailValid || !_isLoginPasswordValid)
                    ? null
                    : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Connexion'),
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppTheme.lightGrey,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou',
                    style: TextStyle(color: AppTheme.mediumGrey),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppTheme.lightGrey,
                  ),
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
                label: const Text('Connexion avec Google'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Créer un compte',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rejoignez TuniTranspo',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mediumGrey,
              ),
            ),
            const SizedBox(height: 28),
            // Nom field with real-time validation (letters only)
            ValidatedTextField(
              controller: _signupNomController,
              label: 'Nom',
              hintText: 'Votre nom',
              prefixIcon: Icons.person_outline,
              validationType: 'name',
              nameFieldType: 'Nom',
              onValidationChanged: (isValid) {
                setState(() => _isSignupNomValid = isValid);
              },
            ),
            const SizedBox(height: 16),
            // Prénom field with real-time validation (letters only)
            ValidatedTextField(
              controller: _signupPrenomController,
              label: 'Prénom',
              hintText: 'Votre prénom',
              prefixIcon: Icons.person_outline,
              validationType: 'name',
              nameFieldType: 'Prénom',
              onValidationChanged: (isValid) {
                setState(() => _isSignupPrenomValid = isValid);
              },
            ),
            const SizedBox(height: 16),
            // Username field with real-time validation (letters and numbers)
            ValidatedTextField(
              controller: _signupUsernameController,
              label: 'Nom d\'utilisateur',
              hintText: 'Choisir un nom d\'utilisateur',
              prefixIcon: Icons.person_add_outlined,
              validationType: 'username',
              onValidationChanged: (isValid) {
                setState(() => _isSignupUsernameValid = isValid);
              },
            ),
            const SizedBox(height: 16),
            // Email field with real-time validation
            ValidatedTextField(
              controller: _signupEmailController,
              label: 'Email',
              hintText: 'votre@email.com',
              prefixIcon: Icons.email_outlined,
              validationType: 'email',
              onValidationChanged: (isValid) {
                setState(() => _isSignupEmailValid = isValid);
              },
            ),
            const SizedBox(height: 16),
            // Password field with real-time validation and strength indicator
            ValidatedTextField(
              controller: _signupPasswordController,
              label: 'Mot de passe',
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline,
              validationType: 'password',
              obscureText: _obscureSignupPassword,
              isPasswordField: true,
              onVisibilityToggle: () {
                setState(() => _obscureSignupPassword = !_obscureSignupPassword);
              },
              onValidationChanged: (isValid) {
                setState(() => _isSignupPasswordValid = isValid);
              },
            ),
            const SizedBox(height: 16),
            // Confirm password field with real-time validation
            ValidatedTextField(
              controller: _signupConfirmPasswordController,
              label: 'Confirmer le mot de passe',
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline,
              validationType: 'confirm_password',
              confirmPasswordValue: _signupPasswordController.text,
              obscureText: _obscureConfirmPassword,
              isPasswordField: true,
              onVisibilityToggle: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
              onValidationChanged: (isValid) {
                setState(() => _isSignupConfirmPasswordValid = isValid);
              },
            ),
            const SizedBox(height: 24),
            // Signup button - enabled only when all fields are valid
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading ||
                        !_isSignupNomValid ||
                        !_isSignupPrenomValid ||
                        !_isSignupUsernameValid ||
                        !_isSignupEmailValid ||
                        !_isSignupPasswordValid ||
                        !_isSignupConfirmPasswordValid)
                    ? null
                    : _handleSignUp,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Créer un compte'),
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppTheme.lightGrey,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou',
                    style: TextStyle(color: AppTheme.mediumGrey),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppTheme.lightGrey,
                  ),
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
                label: const Text('S\'inscrire avec Google'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
