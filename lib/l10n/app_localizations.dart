import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const _localizedStrings = <String, Map<String, String>>{
    'en': {
      'app_title': 'Neo Catalog',
      'onboarding_title_1': 'Craft Your Space',
      'onboarding_body_1': 'Discover immersive furniture selections tailored to your mood.',
      'onboarding_title_2': 'Immersive Story',
      'onboarding_body_2': 'Swipe through cinematic stories with smooth animations.',
      'onboarding_title_3': 'Smart Comparison',
      'onboarding_body_3': 'Compare items instantly and explore AI assisted insights.',
      'get_started': 'Get Started',
      'login': 'Log In',
      'signup': 'Create Account',
      'guest': 'Continue as Guest',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'reset_password': 'Reset Password',
      'confirm_password': 'Confirm Password',
      'password_strength': 'Password strength',
      'strength_weak': 'Weak',
      'strength_medium': 'Medium',
      'strength_strong': 'Strong',
      'catalog': 'Catalog',
      'search_hint': 'Search everything...',
      'filters': 'Filters',
      'favorites_only': 'Favorites only',
      'compare': 'Compare',
      'ai_soon': 'AI insights coming soon',
      'refresh': 'Pull to refresh',
      'dark_mode': 'Dark Mode',
      'primary_color': 'Primary Color',
      'language': 'Language',
      'settings': 'Settings',
      'logout': 'Log out',
      'skip': 'Skip',
      'characters': 'characters',
      'uppercase': 'Uppercase letter',
      'numbers': 'Numbers',
      'symbols': 'Symbols',
    },
    'ar': {
      'app_title': 'كتالوج نيو',
      'onboarding_title_1': 'اصنع مساحتك',
      'onboarding_body_1': 'اكتشف مجموعات الأثاث الغامرة بحسب مزاجك.',
      'onboarding_title_2': 'قصة تفاعلية',
      'onboarding_body_2': 'تصفح القصص السينمائية مع انتقالات سلسة.',
      'onboarding_title_3': 'مقارنة ذكية',
      'onboarding_body_3': 'قارن العناصر فوراً واستكشف رؤى الذكاء الاصطناعي.',
      'get_started': 'ابدأ الآن',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'guest': 'الدخول كضيف',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgot_password': 'نسيت كلمة المرور؟',
      'reset_password': 'إعادة التعيين',
      'confirm_password': 'تأكيد كلمة المرور',
      'password_strength': 'قوة كلمة المرور',
      'strength_weak': 'ضعيفة',
      'strength_medium': 'متوسطة',
      'strength_strong': 'قوية',
      'catalog': 'الكتالوج',
      'search_hint': 'ابحث في كل شيء...',
      'filters': 'الفلاتر',
      'favorites_only': 'المفضلة فقط',
      'compare': 'مقارنة',
      'ai_soon': 'ميزة الذكاء الاصطناعي قريباً',
      'refresh': 'اسحب للتحديث',
      'dark_mode': 'الوضع الليلي',
      'primary_color': 'اللون الرئيسي',
      'language': 'اللغة',
      'settings': 'الإعدادات',
      'logout': 'تسجيل الخروج',
      'skip': 'تخطي',
      'characters': 'حروف',
      'uppercase': 'حرف كبير',
      'numbers': 'أرقام',
      'symbols': 'رموز',
    },
  };

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String translate(String key) {
    final languageCode = locale.languageCode;
    return _localizedStrings[languageCode]?[key] ??
        _localizedStrings['en']![key] ??
        key;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
