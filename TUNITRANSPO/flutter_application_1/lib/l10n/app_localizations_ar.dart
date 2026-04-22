// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'توني ترانسبورت';

  @override
  String get splashSubtitle => 'مساعدك الذكي للنقل';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get favorites => 'المفضلة';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get journeys => 'الرحلات';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get home => 'الرئيسية';

  @override
  String get messages => 'الرسائل';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get loginAsAdmin => 'تسجيل الدخول كمسؤول';

  @override
  String get adminLogin => 'دخول المسؤول';

  @override
  String get adminDashboard => 'لوحة تحكم المسؤول';

  @override
  String get administratorAccess => 'وصول المسؤول';

  @override
  String get matricule => 'الرقم الوظيفي';

  @override
  String get role => 'الدور';

  @override
  String get backToUserLogin => 'العودة لتسجيل دخول المستخدم';

  @override
  String get manageUsers => 'إدارة المستخدمين';

  @override
  String get manageJourneys => 'إدارة الرحلات';

  @override
  String get manageStations => 'إدارة المحطات';

  @override
  String get sendNotifications => 'إرسال الإشعارات';

  @override
  String connectedRole(Object role) {
    return 'الدور المتصل: $role';
  }

  @override
  String get invalidAdminCredentials => 'الرقم الوظيفي أو كلمة المرور غير صحيحة.';

  @override
  String get requiredField => 'هذا الحقل مطلوب.';

  @override
  String get settings => 'الإعدادات';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get themeMode => 'وضع السمة';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get systemDefault => 'افتراضي النظام';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get savedJourneys => 'رحلاتك المحفوظة';

  @override
  String get planJourney => 'خطط لرحلتك';

  @override
  String get findBestOptions => 'اعثر على أفضل الخيارات';

  @override
  String get departurePoint => 'نقطة الانطلاق';

  @override
  String get arrivalPoint => 'نقطة الوصول';

  @override
  String get currentLocation => 'الموقع الحالي';

  @override
  String get useMyGpsPosition => 'استخدم موقعي عبر GPS';

  @override
  String get fetchingLocation => 'جارٍ تحديد موقعك...';

  @override
  String get locationServiceDisabled => 'خدمة الموقع متوقفة.';

  @override
  String get locationPermissionDenied => 'تم رفض إذن الموقع.';

  @override
  String get unableGetGps => 'تعذر الحصول على موقعك عبر GPS.';

  @override
  String get fillAllFields => 'يرجى ملء كل الحقول';

  @override
  String get searchJourney => 'ابحث عن رحلة';

  @override
  String get recentJourneys => 'الرحلات الأخيرة';

  @override
  String get community => 'المجتمع';

  @override
  String get publicDiscussion => 'نقاش عام';

  @override
  String get writeMessageHint => 'اكتب رسالة...';

  @override
  String get signInToParticipate => 'سجل الدخول للمشاركة';

  @override
  String get unableSendMessage => 'تعذر إرسال الرسالة.';

  @override
  String get send => 'إرسال';

  @override
  String get messagesLoadError => 'خطأ أثناء تحميل الرسائل';

  @override
  String get beFirstToWrite => 'كن أول من يكتب!';

  @override
  String replyToUser(Object username) {
    return 'رد على $username';
  }

  @override
  String get cancelReply => 'إلغاء الرد';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get firstName => 'الاسم';

  @override
  String get lastName => 'اللقب';

  @override
  String get city => 'المدينة';

  @override
  String get addCity => 'إضافة مدينة';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get enterCurrentPassword => 'يرجى إدخال كلمة المرور الحالية';

  @override
  String get enterNewPassword => 'يرجى إدخال كلمة المرور الجديدة';

  @override
  String get confirmNewPasswordPrompt => 'يرجى تأكيد كلمة المرور الجديدة';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordMinLength => 'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل';

  @override
  String get passwordChangedSuccessfully => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get chooseAvatar => 'اختر صورة رمزية';

  @override
  String get avatarUpdated => 'تم تحديث الصورة الرمزية';

  @override
  String get avatarUpdateFailed => 'فشل تحديث الصورة الرمزية';

  @override
  String get confirmSignOut => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get notSet => 'غير محدد';

  @override
  String get profileUpdatedSuccessfully => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get profileUpdateFailed => 'فشل تحديث الملف الشخصي';

  @override
  String get noFavoriteJourneysYet => 'لا توجد رحلات مفضلة حتى الآن';

  @override
  String get noNotificationsYet => 'لا توجد إشعارات';

  @override
  String get markAllAsRead => 'تحديد الكل كمقروء';

  @override
  String unreadCountLabel(int count) {
    return '$count غير مقروءة';
  }

  @override
  String get newNotificationTitle => 'إشعار جديد';

  @override
  String get receivedNotificationBody => 'لقد استلمت إشعارا';

  @override
  String get newMessageNotification => 'رسالة جديدة';

  @override
  String get newJourneyNotification => 'تم إنشاء رحلة جديدة';

  @override
  String get systemAnnouncementTitle => 'إعلان النظام';

  @override
  String get systemWelcomeBody => 'مرحبا بك في توني ترانسبورت. رحلة سعيدة!';

  @override
  String featureReadyToBeConnected(Object feature) {
    return 'ميزة $feature جاهزة للربط.';
  }

  @override
  String get authHeaderSubtitle => 'تسجيل الدخول وإنشاء حساب';

  @override
  String get welcomeTitle => 'مرحبا!';

  @override
  String get signInToContinue => 'سجل الدخول للمتابعة';

  @override
  String get createAccountTitle => 'إنشاء حساب';

  @override
  String get joinTuniTranspo => 'انضم إلى توني ترانسبورت';

  @override
  String get forgotPasswordShort => 'نسيت؟';

  @override
  String get orLabel => 'أو';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordPrompt => 'أدخل بريدك الإلكتروني لاستلام رابط إعادة التعيين';

  @override
  String get sendingResetLink => 'جارٍ إرسال رابط إعادة التعيين...';

  @override
  String get resetLinkSent => 'تحقق من بريدك الإلكتروني للحصول على رابط إعادة التعيين';

  @override
  String errorPrefix(Object message) {
    return 'خطأ: $message';
  }

  @override
  String get fixFormErrors => 'يرجى تصحيح أخطاء النموذج';

  @override
  String get fillAllFieldsCorrectly => 'يرجى ملء جميع الحقول بشكل صحيح';

  @override
  String get loginSuccess => 'تم تسجيل الدخول بنجاح!';

  @override
  String get signupSuccess => 'تم إنشاء الحساب بنجاح!';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get signupFailed => 'فشل إنشاء الحساب';

  @override
  String get googleSignInSuccess => 'تم تسجيل الدخول عبر Google!';

  @override
  String get googleSignInFailed => 'فشل تسجيل الدخول عبر Google';

  @override
  String get signInWithGoogle => 'تسجيل الدخول عبر Google';

  @override
  String get signUpWithGoogle => 'إنشاء حساب عبر Google';

  @override
  String get favoriteUpdateFailed => 'فشل تحديث المفضلة.';

  @override
  String get searchByNameOrEmail => 'البحث بالاسم أو البريد الإلكتروني…';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterActive => 'نشط';

  @override
  String get filterBanned => 'محظور مؤقت';

  @override
  String get filterBlocked => 'محظور دائم';

  @override
  String get noUsersFound => 'لا يوجد مستخدمون.';

  @override
  String get noUsersMatchFilter => 'لا يوجد مستخدمون يطابقون الفلتر الحالي.';

  @override
  String get statusActive => 'الحالة: نشط';

  @override
  String get statusBlocked => 'الحالة: محظور دائم';

  @override
  String statusBannedUntil(Object date) {
    return 'الحالة: محظور حتى $date';
  }

  @override
  String get statusBanned => 'الحالة: محظور مؤقت';

  @override
  String get adminActions => 'إجراءات الإدارة';

  @override
  String get adminActionsPrompt => 'اختر إجراءً لهذا المستخدم.';

  @override
  String get banFor3Days => 'حظر 3 أيام';

  @override
  String get banFor7Days => 'حظر 7 أيام';

  @override
  String get blockPermanently => 'حظر دائم';

  @override
  String get unblockUser => 'رفع الحظر';

  @override
  String userBannedDays(int days) {
    return 'تم حظر المستخدم لمدة $days أيام.';
  }

  @override
  String get userBlockedPermanently => 'تم الحظر الدائم للمستخدم.';

  @override
  String get userUnblocked => 'تم رفع الحظر بنجاح.';

  @override
  String get accountBlockedTitle => 'تم حظر الحساب';

  @override
  String get accountBlockedBody => 'تم حظر حسابك نهائيا بواسطة المسؤول.';

  @override
  String get accountBannedTitle => 'تم حظر الحساب مؤقتا';

  @override
  String accountBannedUntil(Object date) {
    return 'حسابك محظور حتى $date.';
  }

  @override
  String get accountBannedBody => 'تم حظر حسابك بواسطة المسؤول.';

  @override
  String get firestoreUpdateError => 'تعذر تحديث المستخدم. تحقق من أذونات Firestore.';

  @override
  String get journeyDetails => 'تفاصيل الرحلة';

  @override
  String get journeySteps => 'مراحل الرحلة';

  @override
  String get totalDuration => 'المدة الإجمالية';

  @override
  String get fare => 'السعر';

  @override
  String get journeyType => 'نوع الرحلة';

  @override
  String get transfers => 'المحطات التحويلية';

  @override
  String get direct => 'مباشر';

  @override
  String get interactiveMap => 'خريطة تفاعلية';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات';

  @override
  String get mode => 'الوضع';

  @override
  String get minimum6Characters => '6 أحرف على الأقل';

  @override
  String get uppercaseLetter => 'حرف كبير (A-Z)';

  @override
  String get lowercaseLetter => 'حرف صغير (a-z)';

  @override
  String get digit => 'رقم (0-9)';

  @override
  String get specialCharacter => 'رمز خاص (!@#...)';

  @override
  String get passwordTooWeak => 'كلمة المرور ضعيفة جدًا';

  @override
  String get passwordIsRequired => 'كلمة المرور مطلوبة';

  @override
  String get emailIsRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get invalidEmailFormat => 'صيغة البريد الإلكتروني غير صالحة';

  @override
  String fieldIsRequired(Object fieldName) {
    return 'الحقل $fieldName مطلوب';
  }

  @override
  String fieldMinLength(Object fieldName, int length) {
    return 'يجب أن يحتوي $fieldName على $length أحرف على الأقل';
  }

  @override
  String fieldMaxLength(Object fieldName, int length) {
    return 'يجب ألا يتجاوز $fieldName $length حرفًا';
  }

  @override
  String fieldCanOnlyContainLetters(Object fieldName) {
    return 'يمكن أن يحتوي $fieldName على أحرف فقط';
  }

  @override
  String get usernameIsRequired => 'اسم المستخدم مطلوب';

  @override
  String get usernameMinLength => 'يجب أن يحتوي اسم المستخدم على 3 أحرف على الأقل';

  @override
  String get usernameMaxLength => 'يجب ألا يتجاوز اسم المستخدم 20 حرفًا';

  @override
  String get edit => 'تعديل';

  @override
  String get add => 'إضافة';

  @override
  String get editJourneyTitle => 'تعديل الرحلة';

  @override
  String get addJourneyTitle => 'إضافة رحلة';

  @override
  String get journeyTypeField => 'النوع (حافلة، مترو، قطار)';

  @override
  String get departureTime => 'وقت الانطلاق';

  @override
  String get journeyUpdatedSuccess => 'تم تعديل الرحلة بنجاح';

  @override
  String get journeyAddedSuccess => 'تمت إضافة الرحلة بنجاح';

  @override
  String get journeysLoadError => 'تعذر تحميل الرحلات';

  @override
  String get noJourneysFound => 'لا توجد رحلات';

  @override
  String get editStationTitle => 'تعديل المحطة';

  @override
  String get addStationTitle => 'إضافة محطة';

  @override
  String get stationName => 'اسم المحطة';

  @override
  String get stationType => 'النوع (مترو، حافلة، قطار)';

  @override
  String get stationUpdatedSuccess => 'تم تعديل المحطة بنجاح';

  @override
  String get stationAddedSuccess => 'تمت إضافة المحطة بنجاح';

  @override
  String get stationsLoadError => 'تعذر تحميل المحطات';

  @override
  String get noStationsFound => 'لا توجد محطات';

  @override
  String get composeNotification => 'إنشاء إشعار';

  @override
  String get title => 'العنوان';

  @override
  String get content => 'المحتوى';

  @override
  String get recipients => 'المستلمون';

  @override
  String get allUsers => 'كل المستخدمين';

  @override
  String get appUsers => 'مستخدمو التطبيق';

  @override
  String get drivers => 'السائقون';

  @override
  String get sendingInProgress => 'جار الإرسال...';

  @override
  String get sendNotificationAction => 'إرسال الإشعار';

  @override
  String get notificationsHistory => 'سجل الإشعارات';

  @override
  String get notificationsLoadError => 'تعذر تحميل الإشعارات';

  @override
  String get noNotificationSentYet => 'لم يتم إرسال أي إشعار بعد';

  @override
  String notificationSavedForRecipients(int count) {
    return 'تم حفظ الإشعار لـ $count مستلم';
  }

  @override
  String recipientsCount(int count) {
    return '$count مستلم';
  }

  @override
  String get authErrorWeakPassword => 'كلمة المرور ضعيفة جدًا. يرجى استخدام كلمة مرور أقوى.';

  @override
  String get authErrorEmailAlreadyInUse => 'هذا البريد الإلكتروني مسجل بالفعل. يرجى تسجيل الدخول أو استخدام بريد إلكتروني آخر.';

  @override
  String get authErrorInvalidEmail => 'عنوان البريد الإلكتروني غير صالح. يرجى التحقق والمحاولة مرة أخرى.';

  @override
  String get authErrorUserDisabled => 'تم تعطيل حساب المستخدم هذا.';

  @override
  String get authErrorUserNotFound => 'لم يتم العثور على حساب بهذا البريد الإلكتروني.';

  @override
  String get authErrorWrongPassword => 'كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.';

  @override
  String get authErrorTooManyRequests => 'محاولات تسجيل دخول كثيرة جدًا. يرجى المحاولة لاحقًا.';

  @override
  String get authErrorGeneric => 'حدث خطأ في المصادقة. يرجى المحاولة مرة أخرى.';

  @override
  String get authErrorAccountCreationFailed => 'تعذر إنشاء حساب المستخدم.';

  @override
  String get authErrorPasswordResetFailed => 'تعذر إرسال البريد الإلكتروني. يرجى التحقق من عنوان بريدك الإلكتروني.';

  @override
  String get useCurrentLocationButton => 'استخدم موقعي الحالي';

  @override
  String get disableCurrentLocation => 'تعطيل الموقع الحالي';

  @override
  String get journeySearchResolutionFailed => 'تعذر إتمام البحث. يرجى التحقق من المحطات المدخلة.';

  @override
  String get unableResolveCurrentLocation => 'تعذر تحديد موقعك الحالي.';

  @override
  String get noNearbyStationFromLocation => 'لم يتم العثور على محطة قريبة من موقعك الحالي.';

  @override
  String stationNotFound(Object query) {
    return 'لم يتم العثور على محطة لـ \'$query\'.';
  }

  @override
  String stationNotFoundWithSuggestions(Object query, Object suggestions) {
    return 'لم يتم العثور على محطة لـ \'$query\'. أقرب المحطات هي: $suggestions';
  }

  @override
  String get results => 'النتائج';
}
