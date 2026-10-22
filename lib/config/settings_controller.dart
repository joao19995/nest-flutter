import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences that survive app restarts.
class SettingsController extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Reads the persisted preferences. Safe to call more than once.
  Future<void> load() async {
    if (_isLoaded || _disposed) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    if (_disposed) {
      return;
    }
    final stored = preferences.getString(_themeModeKey);
    _themeMode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _isLoaded = true;
    notifyListeners();
  }

  /// Persists the chosen theme mode and applies it immediately.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}
