import 'package:flutter_test/flutter_test.dart';
import 'package:tuni_transport/models/journey_model.dart';
import 'package:tuni_transport/models/session_result.dart';
import 'package:tuni_transport/models/user_model.dart';
import 'package:tuni_transport/utils/validation_utils.dart';

void main() {
  group('Validation metier', () {
    test('email: accepte format valide et rejette format invalide', () {
      expect(ValidationUtils.validateEmail('user@tuni.tn'), isNull);
      expect(ValidationUtils.validateEmail('invalid-email'), 'Format d\'email invalide');
    });

    test('mot de passe: verifie force et confirmation', () {
      expect(ValidationUtils.validatePasswordStrength('abc'), PasswordStrength.weak);
      expect(ValidationUtils.validatePasswordStrength('Abc123!xyz'), PasswordStrength.strong);
      expect(ValidationUtils.validateConfirmPassword('Abc123!xyz', 'Abc123!xyz'), isNull);
      expect(
        ValidationUtils.validateConfirmPassword('wrong', 'Abc123!xyz'),
        'Les mots de passe ne correspondent pas',
      );
    });
  });

  group('Session et roles', () {
    test('session admin expose correctement les flags', () {
      const adminSession = SessionResult(
        role: SessionRole.admin,
        adminRole: 'super_admin',
        adminMatricule: 'A001',
      );

      expect(adminSession.isAdmin, isTrue);
      expect(adminSession.isGuest, isFalse);
      expect(adminSession.adminRole, 'super_admin');
    });

    test('session guest force un etat non admin', () {
      const guestSession = SessionResult(role: SessionRole.guest);

      expect(guestSession.isGuest, isTrue);
      expect(guestSession.isAdmin, isFalse);
    });
  });

  group('Modeles de transport et utilisateur', () {
    test('Journey.fromJson: parse compatibilite et aliases', () {
      final journey = Journey.fromJson({
        'id': 'j1',
        'departureStation': 'Tunis',
        'arrivalStation': 'Ariana',
        'departure': '08:10',
        'arrival': '08:40',
        'price': '1.20',
        'transfers': '2',
        'isFavorite': true,
      });

      expect(journey.id, 'j1');
      expect(journey.departureTime, '08:10');
      expect(journey.arrival, '08:40');
      expect(journey.transfers, 2);
      expect(journey.isFavorite, isTrue);
    });

    test('User fullName: fallback coherent quand infos partielles', () {
      final userWithName = User(
        uid: 'u1',
        email: 'user@tuni.tn',
        firstName: 'Sami',
        lastName: 'Trabelsi',
      );
      final userWithoutName = User(uid: 'u2', email: 'anon@tuni.tn');

      expect(userWithName.fullName, 'Sami Trabelsi');
      expect(userWithoutName.fullName, 'anon@tuni.tn');
    });
  });
}
