import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({required Color initialSeedColor, required ThemeMode initialMode})
      : _seedColor = initialSeedColor,
        _mode = initialMode;

  Color _seedColor;
  ThemeMode _mode;

  Color get seedColor => _seedColor;
  ThemeMode get mode => _mode;

  void updateSeedColor(Color color) {
    if (_seedColor == color) return;
    _seedColor = color;
    notifyListeners();
  }

  void toggleMode() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}
