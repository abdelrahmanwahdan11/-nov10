import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/controllers/auth_controller.dart';
import '../core/controllers/catalog_controller.dart';
import '../core/controllers/experience_controller.dart';
import '../core/controllers/showroom_controller.dart';
import '../core/controllers/theme_controller.dart';
import '../core/services/app_preferences.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'app_scope.dart';
class NeoCatalogApp extends StatefulWidget {
  const NeoCatalogApp({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  State<NeoCatalogApp> createState() => _NeoCatalogAppState();
}

class _NeoCatalogAppState extends State<NeoCatalogApp> {
  late final ThemeController _themeController;
  late final AuthController _authController;
  late final CatalogController _catalogController;
  late final ShowroomController _showroomController;
  late final ExperienceController _experienceController;
  late final ValueNotifier<Locale> _localeNotifier;
  late bool _showOnboarding;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final seed = widget.preferences.primaryColor;
    final mode = widget.preferences.themeMode;
    _themeController = ThemeController(initialSeedColor: seed, initialMode: mode);
    _authController = AuthController();
    _catalogController = CatalogController(preferences: widget.preferences);
    _showroomController = ShowroomController(
      catalogController: _catalogController,
      preferences: widget.preferences,
    );
    _experienceController = ExperienceController(
      catalogController: _catalogController,
      showroomController: _showroomController,
      preferences: widget.preferences,
    );
    _localeNotifier = ValueNotifier<Locale>(widget.preferences.locale)
      ..addListener(() {
        unawaited(widget.preferences.setLocale(_localeNotifier.value));
      });
    _showOnboarding = !widget.preferences.hasSeenOnboarding;
  }

  @override
  void dispose() {
    _themeController.dispose();
    _authController.dispose();
    _catalogController.dispose();
    _showroomController.dispose();
    _experienceController.dispose();
    _localeNotifier.dispose();
    super.dispose();
  }

  void _completeOnboarding() {
    setState(() {
      _showOnboarding = false;
    });
    widget.preferences.setHasSeenOnboarding(true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: _localeNotifier,
          builder: (context, locale, __) {
            return Directionality(
              textDirection: locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: AppScope(
                themeController: _themeController,
                authController: _authController,
                catalogController: _catalogController,
                showroomController: _showroomController,
                experienceController: _experienceController,
                preferences: widget.preferences,
                localeNotifier: _localeNotifier,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  navigatorKey: _navigatorKey,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  theme: AppTheme.light(_themeController.seedColor),
                  darkTheme: AppTheme.dark(_themeController.seedColor),
                  themeMode: _themeController.mode,
                  home: _showOnboarding
                      ? OnboardingScreen(onCompleted: _completeOnboarding)
                      : _authController.isAuthenticated
                          ? HomeScreen(onSignOut: () {
                              setState(() {});
                            })
                          : LoginScreen(onGuest: () async {
                              await _authController.signInAsGuest();
                              setState(() {});
                            }, onLoginSuccess: () {
                              setState(() {});
                            }, onSignUpTap: () {
                              _navigatorKey.currentState?.push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SignupScreen(
                                    onLoginTap: () => _navigatorKey.currentState?.pop(),
                                    onSuccess: () {
                                      _navigatorKey.currentState?.pop();
                                      setState(() {});
                                    },
                                  ),
                                ),
                              );
                            }, onForgotTap: () {
                              _navigatorKey.currentState?.push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            }),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
