import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _key = 'is_dark_mode';
  final SharedPreferences _prefs;
  bool _isDarkMode;

  ThemeProvider(this._prefs) : _isDarkMode = _prefs.getBool(_key) ?? false;

  bool get isDarkMode => _isDarkMode;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_key, _isDarkMode);
    notifyListeners();
  }

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  static final lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.red,
      brightness: Brightness.light,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
    useMaterial3: true,
  );

  static final darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.red,
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[850],
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
    ),
    useMaterial3: true,
  );
}