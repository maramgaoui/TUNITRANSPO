// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'TuniTransport';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'Inscription';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get favorites => 'Favoris';

  @override
  String get logout => 'Déconnexion';

  @override
  String get journeys => 'Trajets';

  @override
  String get notifications => 'Notifications';

  @override
  String get home => 'Accueil';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profil';

  @override
  String get loginAsAdmin => 'Connexion Admin';

  @override
  String get adminLogin => 'Connexion Admin';

  @override
  String get adminDashboard => 'Tableau de bord Admin';

  @override
  String get administratorAccess => 'Accès administrateur';

  @override
  String get matricule => 'Matricule';

  @override
  String get role => 'Rôle';

  @override
  String get backToUserLogin => 'Retour à la connexion utilisateur';

  @override
  String get manageUsers => 'Gérer les utilisateurs';

  @override
  String get manageJourneys => 'Gérer les trajets';

  @override
  String get manageStations => 'Gérer les stations';

  @override
  String get sendNotifications => 'Envoyer des notifications';

  @override
  String connectedRole(Object role) {
    return 'Rôle connecté : $role';
  }

  @override
  String get invalidAdminCredentials => 'Matricule ou mot de passe invalide.';

  @override
  String get requiredField => 'Ce champ est obligatoire.';

  @override
  String get settings => 'Paramètres';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get themeMode => 'Mode de thème';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get systemDefault => 'Par défaut du système';

  @override
  String get language => 'Langue';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get savedJourneys => 'Vos trajets enregistrés';

  @override
  String get planJourney => 'Planifier votre trajet';

  @override
  String get findBestOptions => 'Trouvez les meilleures options';

  @override
  String get departurePoint => 'Point de départ';

  @override
  String get arrivalPoint => 'Point d\'arrivée';

  @override
  String get currentLocation => 'Localisation actuelle';

  @override
  String get useMyGpsPosition => 'Utiliser ma position GPS';

  @override
  String get fetchingLocation => 'Récupération de votre position...';

  @override
  String get locationServiceDisabled => 'Le service de localisation est désactivé.';

  @override
  String get locationPermissionDenied => 'Permission de localisation refusée.';

  @override
  String get unableGetGps => 'Impossible d\'obtenir votre position GPS.';

  @override
  String get fillAllFields => 'Veuillez remplir tous les champs';

  @override
  String get searchJourney => 'Rechercher un trajet';

  @override
  String get recentJourneys => 'Trajets récents';

  @override
  String get community => 'Communauté';

  @override
  String get publicDiscussion => 'Discussion publique';

  @override
  String get writeMessageHint => 'Écrire un message...';

  @override
  String get signInToParticipate => 'Connectez-vous pour participer';

  @override
  String get unableSendMessage => 'Impossible d\'envoyer le message.';

  @override
  String get send => 'Envoyer';

  @override
  String get messagesLoadError => 'Erreur de chargement des messages';

  @override
  String get beFirstToWrite => 'Soyez le premier à écrire!';

  @override
  String replyToUser(Object username) {
    return 'Réponse à $username';
  }

  @override
  String get cancelReply => 'Annuler la réponse';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get city => 'Ville';

  @override
  String get addCity => 'Ajouter une ville';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get enterCurrentPassword => 'Veuillez entrer votre mot de passe actuel';

  @override
  String get enterNewPassword => 'Veuillez entrer le nouveau mot de passe';

  @override
  String get confirmNewPasswordPrompt => 'Veuillez confirmer le nouveau mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordMinLength => 'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get passwordChangedSuccessfully => 'Mot de passe changé avec succès';

  @override
  String get chooseAvatar => 'Choisir un avatar';

  @override
  String get avatarUpdated => 'Avatar mis à jour';

  @override
  String get avatarUpdateFailed => 'Échec de la mise à jour de l\'avatar';

  @override
  String get confirmSignOut => 'Êtes-vous sûr de vouloir vous déconnecter?';

  @override
  String get notSet => 'Non défini';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get profileUpdateFailed => 'Failed to update profile';

  @override
  String get noFavoriteJourneysYet => 'Aucun trajet favori pour le moment';

  @override
  String get noNotificationsYet => 'Aucune notification';

  @override
  String get markAllAsRead => 'Tout marquer comme lu';

  @override
  String unreadCountLabel(int count) {
    return '$count non lues';
  }

  @override
  String get newNotificationTitle => 'Nouvelle notification';

  @override
  String get receivedNotificationBody => 'Vous avez reçu une notification';

  @override
  String get newMessageNotification => 'Nouveau message';

  @override
  String get newJourneyNotification => 'Nouveau trajet créé';

  @override
  String get systemAnnouncementTitle => 'Annonce système';

  @override
  String get systemWelcomeBody => 'Bienvenue sur TuniTranspo. Bonne navigation!';

  @override
  String featureReadyToBeConnected(Object feature) {
    return 'La fonctionnalité $feature est prête à être connectée.';
  }
}
