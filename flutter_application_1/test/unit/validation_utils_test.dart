import 'package:flutter_test/flutter_test.dart';
import 'package:tuni_transport/utils/validation_utils.dart';

void main() {
  group('ValidationUtils', () {
    test('validateEmail rejette les formats invalides', () {
      expect(
        ValidationUtils.validateEmail('not-an-email'),
        'Format d\'email invalide',
      );
      expect(
        ValidationUtils.validateEmail('missing-at.com'),
        'Format d\'email invalide',
      );
    });

    test('validatePassword rejette les mots de passe trop courts', () {
      expect(
        ValidationUtils.validatePassword('123'),
        'Le mot de passe doit contenir au moins 6 caractères',
      );
      expect(
        ValidationUtils.validatePassword('abc'),
        'Le mot de passe doit contenir au moins 6 caractères',
      );
    });
  });
}
