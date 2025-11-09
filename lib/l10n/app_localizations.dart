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
      'experience': 'Experience',
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
      'favorites_active': 'Showing favorites',
      'showroom': 'Showroom',
      'showroom_moods': 'Immersive moods',
      'mood_all': 'All moods',
      'start_auto_cycle': 'Start auto cycle',
      'stop_auto_cycle': 'Stop auto cycle',
      'scene_story_title': 'Scene narrative',
      'featured_items': 'Featured items',
      'view_scene_items': 'View items',
      'experience_pin_prompt': 'Pin an experience journey to keep it in focus.',
      'experience_pin_description':
          'Choose any blueprint below to anchor its phases and sync with catalog insights.',
      'unpin': 'Unpin',
      'pinned': 'Pinned',
      'pin': 'Pin',
      'experience_preview': 'Preview items',
      'experience_phases': 'Experience phases',
      'experience_mark': 'Mark progress',
      'minutes_short': 'min',
      'experience_timeline_empty': 'No pulses yet, start by adding favorites.',
      'experience_focus_start': 'Focus phase',
      'experience_focus_release': 'Release focus',
      'experience_focus_empty': 'Activate focus on a phase to unlock deep insights.',
      'experience_focus_elapsed': 'Focused for',
      'experience_chronicle_title': 'Experience chronicle',
      'experience_chronicle_empty': 'Complete phases or trigger pulses to populate the chronicle.',
      'experience_moment_pulse': 'Pulse insight',
      'experience_moment_progress': 'Progress marker',
      'experience_moment_focus': 'Focus locked',
      'experience_moment_reflection': 'Reflection',
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
      'experience': 'التجربة',
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
      'favorites_active': 'عرض العناصر المفضلة',
      'showroom': 'صالة العرض',
      'showroom_moods': 'مزاجات العرض الغامرة',
      'mood_all': 'كل المزاجات',
      'start_auto_cycle': 'بدء العرض التلقائي',
      'stop_auto_cycle': 'إيقاف العرض التلقائي',
      'scene_story_title': 'حكاية المشهد',
      'featured_items': 'عناصر مميزة',
      'view_scene_items': 'استعراض العناصر',
      'experience_pin_prompt': 'ثبّت رحلة التجربة لتحافظ عليها في الواجهة.',
      'experience_pin_description':
          'اختر أي مخطط أدناه لربط مراحله ومزامنته مع رؤى الكتالوج.',
      'unpin': 'إلغاء التثبيت',
      'pinned': 'مُثبّت',
      'pin': 'تثبيت',
      'experience_preview': 'معاينة العناصر',
      'experience_phases': 'مراحل التجربة',
      'experience_mark': 'تحديث التقدم',
      'minutes_short': 'دقيقة',
      'experience_timeline_empty': 'لا توجد تحديثات بعد، ابدأ بإضافة عناصر مفضلة.',
      'experience_focus_start': 'تركيز المرحلة',
      'experience_focus_release': 'إنهاء التركيز',
      'experience_focus_empty': 'فعّل التركيز على مرحلة لتحصل على رؤى أعمق.',
      'experience_focus_elapsed': 'مدة التركيز',
      'experience_chronicle_title': 'سجل التجربة',
      'experience_chronicle_empty': 'أكمل المراحل أو فعّل النبضات لتمتلئ السجلات.',
      'experience_moment_pulse': 'نبضة ملهمة',
      'experience_moment_progress': 'علامة تقدم',
      'experience_moment_focus': 'تركيز مثبت',
      'experience_moment_reflection': 'لحظة تأمل',
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
