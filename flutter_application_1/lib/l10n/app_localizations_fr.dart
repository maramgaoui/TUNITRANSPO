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
  String get splashSubtitle => 'Votre assistant de transport intelligent';

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
  String get profileUpdatedSuccessfully => 'Profil mis à jour avec succès';

  @override
  String get profileUpdateFailed => 'Échec de la mise à jour du profil';

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

  @override
  String get authHeaderSubtitle => 'Connexion & Inscription';

  @override
  String get welcomeTitle => 'Bienvenue!';

  @override
  String get signInToContinue => 'Connectez-vous pour continuer';

  @override
  String get createAccountTitle => 'Créer un compte';

  @override
  String get joinTuniTranspo => 'Rejoignez TuniTranspo';

  @override
  String get forgotPasswordShort => 'Oublié?';

  @override
  String get orLabel => 'ou';

  @override
  String get resetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get resetPasswordPrompt => 'Entrez votre adresse email pour recevoir un lien de réinitialisation';

  @override
  String get sendingResetLink => 'Envoi du lien de réinitialisation...';

  @override
  String get resetLinkSent => 'Vérifiez votre email pour le lien de réinitialisation';

  @override
  String errorPrefix(Object message) {
    return 'Erreur : $message';
  }

  @override
  String get fixFormErrors => 'Veuillez corriger les erreurs du formulaire';

  @override
  String get fillAllFieldsCorrectly => 'Veuillez remplir tous les champs correctement';

  @override
  String get loginSuccess => 'Connexion réussie!';

  @override
  String get signupSuccess => 'Compte créé avec succès!';

  @override
  String get loginFailed => 'Connexion échouée';

  @override
  String get signupFailed => 'Inscription échouée';

  @override
  String get googleSignInSuccess => 'Connecté avec Google!';

  @override
  String get googleSignInFailed => 'Connexion Google échouée';

  @override
  String get signInWithGoogle => 'Connexion avec Google';

  @override
  String get signUpWithGoogle => 'S\'inscrire avec Google';

  @override
  String get favoriteUpdateFailed => 'Échec de la mise à jour des favoris.';

  @override
  String get searchByNameOrEmail => 'Rechercher par nom ou email…';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterActive => 'Actif';

  @override
  String get filterBanned => 'Banni';

  @override
  String get filterBlocked => 'Bloqué';

  @override
  String get noUsersFound => 'Aucun utilisateur trouvé.';

  @override
  String get noUsersMatchFilter => 'Aucun utilisateur ne correspond au filtre actuel.';

  @override
  String get statusActive => 'Statut : Actif';

  @override
  String get statusBlocked => 'Statut : Bloqué';

  @override
  String statusBannedUntil(Object date) {
    return 'Statut : Banni jusqu\'au $date';
  }

  @override
  String get statusBanned => 'Statut : Banni';

  @override
  String get adminActions => 'Actions admin';

  @override
  String get adminActionsPrompt => 'Sélectionnez une action pour cet utilisateur.';

  @override
  String get banFor3Days => 'Bannir 3 jours';

  @override
  String get banFor7Days => 'Bannir 7 jours';

  @override
  String get blockPermanently => 'Bloquer définitivement';

  @override
  String get unblockUser => 'Débloquer l\'utilisateur';

  @override
  String userBannedDays(int days) {
    return 'Utilisateur banni pour $days jours.';
  }

  @override
  String get userBlockedPermanently => 'Utilisateur bloqué définitivement.';

  @override
  String get userUnblocked => 'Utilisateur débloqué avec succès.';

  @override
  String get accountBlockedTitle => 'Compte bloqué';

  @override
  String get accountBlockedBody => 'Votre compte a été bloqué définitivement par un administrateur.';

  @override
  String get accountBannedTitle => 'Compte banni';

  @override
  String accountBannedUntil(Object date) {
    return 'Votre compte est banni jusqu\'au $date.';
  }

  @override
  String get accountBannedBody => 'Votre compte a été interdit par un administrateur.';

  @override
  String get firestoreUpdateError => 'Impossible de mettre à jour l\'utilisateur. Vérifiez les permissions Firestore.';

  @override
  String get journeyDetails => 'Détails du trajet';

  @override
  String get journeySteps => 'Étapes du trajet';

  @override
  String get totalDuration => 'Durée totale';

  @override
  String get fare => 'Tarif';

  @override
  String get journeyType => 'Type de trajet';

  @override
  String get transfers => 'Correspondances';

  @override
  String get direct => 'Direct';

  @override
  String get interactiveMap => 'Carte interactive';

  @override
  String get settingsSaved => 'Paramètres enregistrés';

  @override
  String get mode => 'Mode';

  @override
  String get minimum6Characters => 'Au moins 6 caractères';

  @override
  String get uppercaseLetter => 'Lettre majuscule (A-Z)';

  @override
  String get lowercaseLetter => 'Lettre minuscule (a-z)';

  @override
  String get digit => 'Chiffre (0-9)';

  @override
  String get specialCharacter => 'Caractère spécial (!@#...)';

  @override
  String get passwordTooWeak => 'Le mot de passe est trop faible';

  @override
  String get passwordIsRequired => 'Le mot de passe est requis';

  @override
  String get emailIsRequired => 'Email est requis';

  @override
  String get invalidEmailFormat => 'Format d\'email invalide';

  @override
  String fieldIsRequired(Object fieldName) {
    return '$fieldName est requis';
  }

  @override
  String fieldMinLength(Object fieldName, int length) {
    return '$fieldName doit contenir au moins $length caractères';
  }

  @override
  String fieldMaxLength(Object fieldName, int length) {
    return '$fieldName doit contenir au maximum $length caractères';
  }

  @override
  String fieldCanOnlyContainLetters(Object fieldName) {
    return '$fieldName ne peut contenir que des lettres';
  }

  @override
  String get usernameIsRequired => 'Le nom d\'utilisateur est requis';

  @override
  String get usernameMinLength => 'Le nom d\'utilisateur doit contenir au moins 3 caractères';

  @override
  String get usernameMaxLength => 'Le nom d\'utilisateur doit contenir au maximum 20 caractères';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get editJourneyTitle => 'Modifier le trajet';

  @override
  String get addJourneyTitle => 'Ajouter un trajet';

  @override
  String get journeyTypeField => 'Type (Bus, Metro, Train)';

  @override
  String get departureTime => 'Heure de départ';

  @override
  String get journeyUpdatedSuccess => 'Trajet modifié avec succès';

  @override
  String get journeyAddedSuccess => 'Trajet ajouté avec succès';

  @override
  String get journeysLoadError => 'Erreur de chargement des trajets';

  @override
  String get noJourneysFound => 'Aucun trajet';

  @override
  String get editStationTitle => 'Modifier la station';

  @override
  String get addStationTitle => 'Ajouter une station';

  @override
  String get stationName => 'Nom de la station';

  @override
  String get stationType => 'Type (Metro, Bus, Train)';

  @override
  String get stationUpdatedSuccess => 'Station modifiée avec succès';

  @override
  String get stationAddedSuccess => 'Station ajoutée avec succès';

  @override
  String get stationsLoadError => 'Erreur de chargement des stations';

  @override
  String get noStationsFound => 'Aucune station';

  @override
  String get composeNotification => 'Composer une notification';

  @override
  String get title => 'Titre';

  @override
  String get content => 'Contenu';

  @override
  String get recipients => 'Destinataires';

  @override
  String get allUsers => 'Tous les utilisateurs';

  @override
  String get appUsers => 'Utilisateurs app';

  @override
  String get drivers => 'Conducteurs';

  @override
  String get sendingInProgress => 'Envoi en cours...';

  @override
  String get sendNotificationAction => 'Envoyer la notification';

  @override
  String get notificationsHistory => 'Historique des notifications';

  @override
  String get notificationsLoadError => 'Erreur de chargement des notifications';

  @override
  String get noNotificationSentYet => 'Aucune notification envoyée';

  @override
  String notificationSavedForRecipients(int count) {
    return 'Notification enregistrée pour $count destinataires';
  }

  @override
  String recipientsCount(int count) {
    return '$count destinataires';
  }
}
