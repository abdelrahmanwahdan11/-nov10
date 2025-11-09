import 'package:flutter/material.dart';

import '../core/controllers/auth_controller.dart';
import '../core/controllers/catalog_controller.dart';
import '../core/controllers/theme_controller.dart';
import '../core/services/app_preferences.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required super.child,
    required this.themeController,
    required this.authController,
    required this.catalogController,
    required this.preferences,
    required this.localeNotifier,
  });

  final ThemeController themeController;
  final AuthController authController;
  final CatalogController catalogController;
  final AppPreferences preferences;
  final ValueNotifier<Locale> localeNotifier;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) => false;
}
