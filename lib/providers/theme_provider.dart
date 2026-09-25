import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.blue;
  double _textScaleFactor = 1.0;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  double get textScaleFactor => _textScaleFactor;

  ThemeProvider() {
    _loadPreferences();
  }

  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    
    final modeString = prefs.getString(_themeModeKey) ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == modeString,
      orElse: () => ThemeMode.system,
    );
    
    
    final seedColorValue = prefs.getInt('seed_color');
    if (seedColorValue != null) {
      _seedColor = Color(seedColorValue);
    }
    
    
    _textScaleFactor = prefs.getDouble('text_scale_factor') ?? 1.0;
    
    notifyListeners();
  }

  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  
  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seed_color', color.value);
  }

  
  Future<void> setTextScaleFactor(double factor) async {
    _textScaleFactor = factor;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_scale_factor', factor);
  }

  
  Future<void> reset() async {
    _themeMode = ThemeMode.system;
    _seedColor = Colors.blue;
    _textScaleFactor = 1.0;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeModeKey);
    await prefs.remove('seed_color');
    await prefs.remove('text_scale_factor');
  }
}
