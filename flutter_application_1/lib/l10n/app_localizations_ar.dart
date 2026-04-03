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
}
