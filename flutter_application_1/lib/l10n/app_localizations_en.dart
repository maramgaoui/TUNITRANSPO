// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TuniTransport';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get favorites => 'Favorites';

  @override
  String get logout => 'Logout';

  @override
  String get journeys => 'Journeys';

  @override
  String get notifications => 'Notifications';

  @override
  String get home => 'Home';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profile';

  @override
  String get loginAsAdmin => 'Login as Admin';

  @override
  String get adminLogin => 'Admin Login';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get administratorAccess => 'Administrator Access';

  @override
  String get matricule => 'Matricule';

  @override
  String get role => 'Role';

  @override
  String get backToUserLogin => 'Back to User Login';

  @override
  String get manageUsers => 'Manage Users';

  @override
  String get manageJourneys => 'Manage Journeys';

  @override
  String get manageStations => 'Manage Stations';

  @override
  String get sendNotifications => 'Send Notifications';

  @override
  String connectedRole(Object role) {
    return 'Connected role: $role';
  }

  @override
  String get invalidAdminCredentials => 'Invalid matricule or password.';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get settings => 'Settings';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get systemDefault => 'System default';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get savedJourneys => 'Your saved journeys';

  @override
  String get planJourney => 'Plan your journey';

  @override
  String get findBestOptions => 'Find the best options';

  @override
  String get departurePoint => 'Departure point';

  @override
  String get arrivalPoint => 'Arrival point';

  @override
  String get currentLocation => 'Current location';

  @override
  String get useMyGpsPosition => 'Use my GPS position';

  @override
  String get fetchingLocation => 'Getting your location...';

  @override
  String get locationServiceDisabled => 'Location service is disabled.';

  @override
  String get locationPermissionDenied => 'Location permission denied.';

  @override
  String get unableGetGps => 'Unable to get your GPS position.';

  @override
  String get fillAllFields => 'Please fill in all fields';

  @override
  String get searchJourney => 'Search journey';

  @override
  String get recentJourneys => 'Recent journeys';

  @override
  String get community => 'Community';

  @override
  String get publicDiscussion => 'Public discussion';

  @override
  String get writeMessageHint => 'Write a message...';

  @override
  String get signInToParticipate => 'Sign in to participate';

  @override
  String get unableSendMessage => 'Unable to send message.';

  @override
  String get send => 'Send';

  @override
  String get messagesLoadError => 'Error loading messages';

  @override
  String get beFirstToWrite => 'Be the first to write!';

  @override
  String replyToUser(Object username) {
    return 'Reply to $username';
  }

  @override
  String get cancelReply => 'Cancel reply';

  @override
  String get username => 'Username';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get city => 'City';

  @override
  String get addCity => 'Add a city';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get enterCurrentPassword => 'Please enter your current password';

  @override
  String get enterNewPassword => 'Please enter the new password';

  @override
  String get confirmNewPasswordPrompt => 'Please confirm the new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordMinLength => 'Password must contain at least 6 characters';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get chooseAvatar => 'Choose an avatar';

  @override
  String get avatarUpdated => 'Avatar updated';

  @override
  String get avatarUpdateFailed => 'Failed to update avatar';

  @override
  String get confirmSignOut => 'Are you sure you want to sign out?';

  @override
  String get notSet => 'Not set';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get profileUpdateFailed => 'Failed to update profile';

  @override
  String get noFavoriteJourneysYet => 'No favorite journeys yet';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String unreadCountLabel(int count) {
    return '$count unread';
  }

  @override
  String get newNotificationTitle => 'New notification';

  @override
  String get receivedNotificationBody => 'You received a notification';

  @override
  String get newMessageNotification => 'New message';

  @override
  String get newJourneyNotification => 'New journey created';

  @override
  String get systemAnnouncementTitle => 'System announcement';

  @override
  String get systemWelcomeBody => 'Welcome to TuniTranspo. Enjoy your trip!';

  @override
  String featureReadyToBeConnected(Object feature) {
    return '$feature feature is ready to be connected.';
  }

  @override
  String get authHeaderSubtitle => 'Login & Register';

  @override
  String get welcomeTitle => 'Welcome!';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get createAccountTitle => 'Create an account';

  @override
  String get joinTuniTranspo => 'Join TuniTranspo';

  @override
  String get forgotPasswordShort => 'Forgot?';

  @override
  String get orLabel => 'or';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordPrompt =>
      'Enter your email address to receive a reset link';

  @override
  String get sendingResetLink => 'Sending reset link...';

  @override
  String get resetLinkSent => 'Check your email for the reset link';

  @override
  String errorPrefix(Object message) {
    return 'Error: $message';
  }

  @override
  String get fixFormErrors => 'Please fix the form errors';

  @override
  String get fillAllFieldsCorrectly => 'Please fill all fields correctly';

  @override
  String get loginSuccess => 'Login successful!';

  @override
  String get signupSuccess => 'Account created successfully!';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get signupFailed => 'Sign up failed';

  @override
  String get googleSignInSuccess => 'Signed in with Google!';

  @override
  String get googleSignInFailed => 'Google sign in failed';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get favoriteUpdateFailed => 'Failed to update favorites.';

  @override
  String get searchByNameOrEmail => 'Search by name or email...';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterBanned => 'Banned';

  @override
  String get filterBlocked => 'Blocked';

  @override
  String get noUsersFound => 'No users found.';

  @override
  String get noUsersMatchFilter => 'No users match the current filter.';

  @override
  String get statusActive => 'Status: Active';

  @override
  String get statusBlocked => 'Status: Blocked';

  @override
  String statusBannedUntil(Object date) {
    return 'Status: Banned until $date';
  }

  @override
  String get statusBanned => 'Status: Banned';

  @override
  String get adminActions => 'Admin Actions';

  @override
  String get adminActionsPrompt => 'Select an action for this user.';

  @override
  String get banFor3Days => 'Ban for 3 days';

  @override
  String get banFor7Days => 'Ban for 7 days';

  @override
  String get blockPermanently => 'Block permanently';

  @override
  String get unblockUser => 'Unblock user';

  @override
  String userBannedDays(int days) {
    return 'User banned for $days days.';
  }

  @override
  String get userBlockedPermanently => 'User blocked permanently.';

  @override
  String get userUnblocked => 'User unblocked successfully.';

  @override
  String get accountBlockedTitle => 'Account Blocked';

  @override
  String get accountBlockedBody =>
      'Your account has been permanently blocked by an administrator.';

  @override
  String get accountBannedTitle => 'Account Banned';

  @override
  String accountBannedUntil(Object date) {
    return 'Your account has been banned until $date.';
  }

  @override
  String get accountBannedBody =>
      'Your account has been banned by an administrator.';
}
