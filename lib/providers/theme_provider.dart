import 'package:flutter/material.dart';

/// Theme & Accessibility Provider
/// Manages Eye-Comfort Light mode (anti-glare soft white), Eye-Comfort Dark mode,
/// and Low-Vision High-Legibility Accessibility mode.
class ThemeProvider extends ChangeNotifier {
  // Default to Eye-Comfort Light Mode (glare-free soft white/slate) as requested by user
  bool _isDarkMode = false;
  bool _isHighContrast = false;

  bool get isDarkMode => _isDarkMode;
  bool get isHighContrast => _isHighContrast;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
    }
  }

  void toggleHighContrast() {
    _isHighContrast = !_isHighContrast;
    notifyListeners();
  }
}
