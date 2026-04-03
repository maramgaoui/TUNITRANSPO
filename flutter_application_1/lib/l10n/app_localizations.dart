import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TuniTransport'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @journeys.
  ///
  /// In en, this message translates to:
  /// **'Journeys'**
  String get journeys;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @loginAsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Login as Admin'**
  String get loginAsAdmin;

  /// No description provided for @adminLogin.
  ///
  /// In en, this message translates to:
  /// **'Admin Login'**
  String get adminLogin;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @administratorAccess.
  ///
  /// In en, this message translates to:
  /// **'Administrator Access'**
  String get administratorAccess;

  /// No description provided for @matricule.
  ///
  /// In en, this message translates to:
  /// **'Matricule'**
  String get matricule;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @backToUserLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to User Login'**
  String get backToUserLogin;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @manageJourneys.
  ///
  /// In en, this message translates to:
  /// **'Manage Journeys'**
  String get manageJourneys;

  /// No description provided for @manageStations.
  ///
  /// In en, this message translates to:
  /// **'Manage Stations'**
  String get manageStations;

  /// No description provided for @sendNotifications.
  ///
  /// In en, this message translates to:
  /// **'Send Notifications'**
  String get sendNotifications;

  /// No description provided for @connectedRole.
  ///
  /// In en, this message translates to:
  /// **'Connected role: {role}'**
  String connectedRole(Object role);

  /// No description provided for @invalidAdminCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid matricule or password.'**
  String get invalidAdminCredentials;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @savedJourneys.
  ///
  /// In en, this message translates to:
  /// **'Your saved journeys'**
  String get savedJourneys;

  /// No description provided for @planJourney.
  ///
  /// In en, this message translates to:
  /// **'Plan your journey'**
  String get planJourney;

  /// No description provided for @findBestOptions.
  ///
  /// In en, this message translates to:
  /// **'Find the best options'**
  String get findBestOptions;

  /// No description provided for @departurePoint.
  ///
  /// In en, this message translates to:
  /// **'Departure point'**
  String get departurePoint;

  /// No description provided for @arrivalPoint.
  ///
  /// In en, this message translates to:
  /// **'Arrival point'**
  String get arrivalPoint;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @useMyGpsPosition.
  ///
  /// In en, this message translates to:
  /// **'Use my GPS position'**
  String get useMyGpsPosition;

  /// No description provided for @fetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get fetchingLocation;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location service is disabled.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get locationPermissionDenied;

  /// No description provided for @unableGetGps.
  ///
  /// In en, this message translates to:
  /// **'Unable to get your GPS position.'**
  String get unableGetGps;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// No description provided for @searchJourney.
  ///
  /// In en, this message translates to:
  /// **'Search journey'**
  String get searchJourney;

  /// No description provided for @recentJourneys.
  ///
  /// In en, this message translates to:
  /// **'Recent journeys'**
  String get recentJourneys;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @publicDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Public discussion'**
  String get publicDiscussion;

  /// No description provided for @writeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get writeMessageHint;

  /// No description provided for @signInToParticipate.
  ///
  /// In en, this message translates to:
  /// **'Sign in to participate'**
  String get signInToParticipate;

  /// No description provided for @unableSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to send message.'**
  String get unableSendMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @messagesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading messages'**
  String get messagesLoadError;

  /// No description provided for @beFirstToWrite.
  ///
  /// In en, this message translates to:
  /// **'Be the first to write!'**
  String get beFirstToWrite;

  /// No description provided for @replyToUser.
  ///
  /// In en, this message translates to:
  /// **'Reply to {username}'**
  String replyToUser(Object username);

  /// No description provided for @cancelReply.
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get cancelReply;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @addCity.
  ///
  /// In en, this message translates to:
  /// **'Add a city'**
  String get addCity;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter the new password'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please confirm the new password'**
  String get confirmNewPasswordPrompt;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose an avatar'**
  String get chooseAvatar;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get avatarUpdated;

  /// No description provided for @avatarUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update avatar'**
  String get avatarUpdateFailed;

  /// No description provided for @confirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get confirmSignOut;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileUpdateFailed;

  /// No description provided for @noFavoriteJourneysYet.
  ///
  /// In en, this message translates to:
  /// **'No favorite journeys yet'**
  String get noFavoriteJourneysYet;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @unreadCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String unreadCountLabel(int count);

  /// No description provided for @newNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'New notification'**
  String get newNotificationTitle;

  /// No description provided for @receivedNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'You received a notification'**
  String get receivedNotificationBody;

  /// No description provided for @newMessageNotification.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessageNotification;

  /// No description provided for @newJourneyNotification.
  ///
  /// In en, this message translates to:
  /// **'New journey created'**
  String get newJourneyNotification;

  /// No description provided for @systemAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'System announcement'**
  String get systemAnnouncementTitle;

  /// No description provided for @systemWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TuniTranspo. Enjoy your trip!'**
  String get systemWelcomeBody;

  /// No description provided for @featureReadyToBeConnected.
  ///
  /// In en, this message translates to:
  /// **'{feature} feature is ready to be connected.'**
  String featureReadyToBeConnected(Object feature);

  /// No description provided for @searchByNameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get searchByNameOrEmail;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @filterBanned.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get filterBanned;

  /// No description provided for @filterBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get filterBlocked;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get noUsersFound;

  /// No description provided for @noUsersMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No users match the current filter.'**
  String get noUsersMatchFilter;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Status: Active'**
  String get statusActive;

  /// No description provided for @statusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Status: Blocked'**
  String get statusBlocked;

  /// No description provided for @statusBannedUntil.
  ///
  /// In en, this message translates to:
  /// **'Status: Banned until {date}'**
  String statusBannedUntil(Object date);

  /// No description provided for @statusBanned.
  ///
  /// In en, this message translates to:
  /// **'Status: Banned'**
  String get statusBanned;

  /// No description provided for @adminActions.
  ///
  /// In en, this message translates to:
  /// **'Admin Actions'**
  String get adminActions;

  /// No description provided for @adminActionsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select an action for this user.'**
  String get adminActionsPrompt;

  /// No description provided for @banFor3Days.
  ///
  /// In en, this message translates to:
  /// **'Ban for 3 days'**
  String get banFor3Days;

  /// No description provided for @banFor7Days.
  ///
  /// In en, this message translates to:
  /// **'Ban for 7 days'**
  String get banFor7Days;

  /// No description provided for @blockPermanently.
  ///
  /// In en, this message translates to:
  /// **'Block permanently'**
  String get blockPermanently;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock user'**
  String get unblockUser;

  /// No description provided for @userBannedDays.
  ///
  /// In en, this message translates to:
  /// **'User banned for {days} days.'**
  String userBannedDays(int days);

  /// No description provided for @userBlockedPermanently.
  ///
  /// In en, this message translates to:
  /// **'User blocked permanently.'**
  String get userBlockedPermanently;

  /// No description provided for @userUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User unblocked successfully.'**
  String get userUnblocked;

  /// No description provided for @accountBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Blocked'**
  String get accountBlockedTitle;

  /// No description provided for @accountBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account has been permanently blocked by an administrator.'**
  String get accountBlockedBody;

  /// No description provided for @accountBannedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Banned'**
  String get accountBannedTitle;

  /// No description provided for @accountBannedUntil.
  ///
  /// In en, this message translates to:
  /// **'Your account has been banned until {date}.'**
  String accountBannedUntil(Object date);

  /// No description provided for @accountBannedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account has been banned by an administrator.'**
  String get accountBannedBody;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
