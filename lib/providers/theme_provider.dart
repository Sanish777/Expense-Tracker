import 'package:flutter/material.dart';
import '../services/hive_service.dart';

class ThemeProvider with ChangeNotifier {
  final HiveService _hiveService;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider(this._hiveService) {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadThemeMode() {
    final mode = _hiveService.getThemeMode();
    switch (mode) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      default:
        modeString = 'system';
    }
    await _hiveService.saveThemeMode(modeString);
  }
}
