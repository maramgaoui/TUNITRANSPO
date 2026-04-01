import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/validation_utils.dart';

class ValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final String validationType; // 'email', 'name', 'username', 'password', 'confirm_password'
  final String? confirmPasswordValue; // For confirm password validation
  final bool obscureText;
  final VoidCallback? onVisibilityToggle;
  final bool isPasswordField;
  final ValueChanged<bool>? onValidationChanged;
  final String? nameFieldType; // 'nom' or 'prenom'

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.validationType,
    this.confirmPasswordValue,
    this.obscureText = false,
    this.onVisibilityToggle,
    this.isPasswordField = false,
    this.onValidationChanged,
    this.nameFieldType,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  String? _errorMessage;
  bool _isValid = false;

  void _validateField(String value) {
    String? error;
    bool isValid = false;

    switch (widget.validationType) {
      case 'email':
        error = ValidationUtils.validateEmail(value);
        isValid = ValidationUtils.isEmailValid(value);
        break;
      case 'name':
        error = ValidationUtils.validateName(value, widget.nameFieldType ?? 'Name');
        isValid = ValidationUtils.isNameValid(value);
        break;
      case 'username':
        error = ValidationUtils.validateUsername(value);
        isValid = ValidationUtils.isUsernameValid(value);
        break;
      case 'password':
        error = ValidationUtils.validatePassword(value);
        isValid = error == null && value.isNotEmpty;
        break;
      case 'confirm_password':
        if (widget.confirmPasswordValue != null) {
          error = ValidationUtils.validateConfirmPassword(value, widget.confirmPasswordValue!);
          isValid = ValidationUtils.doesPasswordMatch(value, widget.confirmPasswordValue!);
        }
        break;
    }

    setState(() {
      _errorMessage = error;
      _isValid = isValid;
    });

    widget.onValidationChanged?.call(isValid);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: _getKeyboardType(),
          onChanged: _validateField,
          validator: (value) => _getFormValidator(value),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: _buildSuffixIcon(),
            errorText: _errorMessage,
            errorMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _getBorderColor(),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _getBorderColor(),
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _getBorderColor(),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
          ),
        ),
        // Show password strength indicator for password fields
        if (widget.validationType == 'password' && widget.controller.text.isNotEmpty)
          _buildPasswordStrengthIndicator(),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPasswordField) {
      return IconButton(
        icon: Icon(
          widget.obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
        onPressed: widget.onVisibilityToggle,
      );
    } else if (widget.controller.text.isEmpty) {
      return null;
    } else {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(
          _isValid ? Icons.check_circle : Icons.error_outline,
          color: _isValid ? Colors.green : Colors.red,
          size: 20,
        ),
      );
    }
  }

  Color _getBorderColor() {
    if (widget.controller.text.isEmpty) {
      return Colors.grey.shade300;
    }
    if (_errorMessage != null) {
      return Colors.red;
    }
    if (_isValid) {
      return Colors.green;
    }
    return Colors.grey.shade300;
  }

  TextInputType _getKeyboardType() {
    switch (widget.validationType) {
      case 'email':
        return TextInputType.emailAddress;
      case 'username':
        return TextInputType.text;
      default:
        return TextInputType.text;
    }
  }

  String? _getFormValidator(String? value) {
    switch (widget.validationType) {
      case 'email':
        return ValidationUtils.validateEmail(value);
      case 'name':
        return ValidationUtils.validateName(value, widget.nameFieldType ?? 'Name');
      case 'username':
        return ValidationUtils.validateUsername(value);
      case 'password':
        return ValidationUtils.validatePassword(value);
      case 'confirm_password':
        if (widget.confirmPasswordValue != null) {
          return ValidationUtils.validateConfirmPassword(value, widget.confirmPasswordValue!);
        }
        return null;
      default:
        return null;
    }
  }

  Widget _buildPasswordStrengthIndicator() {
    final strength = ValidationUtils.validatePasswordStrength(widget.controller.text);
    final percentage = strength.percentage / 100;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strength.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: strength.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPasswordRequirements(),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    final password = widget.controller.text;
    final hasMinLength = password.length >= 6;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirement('Au moins 6 caractères', hasMinLength),
        _buildRequirement('Lettre majuscule (A-Z)', hasUppercase),
        _buildRequirement('Lettre minuscule (a-z)', hasLowercase),
        _buildRequirement('Chiffre (0-9)', hasNumber),
        _buildRequirement('Caractère spécial (!@#...)', hasSpecial),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
