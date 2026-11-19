/// VYRO AI â€” Theme Provider
///
/// Simple theme brightness toggle. The app is dark by default (premium look).


import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider._();
  static final ThemeProvider instance = ThemeProvider._();

  bool _isDark = true;
  bool get isDark => _isDark;

  ThemeData get theme => _isDark ? _darkTheme : _lightTheme;

  static ThemeData _darkTheme = _buildDark();
  static ThemeData _lightTheme = _buildLight();

  static ThemeData _buildDark() {
    // Built in config/theme.dart via vyroTheme(); here we return a dark scaffold.
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      brightness: Brightness.dark,
    );
  }

  static ThemeData _buildLight() {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      brightness: Brightness.light,
    );
  }

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void setDark(bool value) {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
  }
}
