import 'package:shared_preferences/shared_preferences.dart';


class TooltipService {
  static const String _key = 'shown_tooltips';

  
  static Future<bool> hasShown(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getStringList(_key) ?? [];
    return shown.contains(featureId);
  }

  
  static Future<void> markShown(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getStringList(_key) ?? [];
    if (!shown.contains(featureId)) {
      shown.add(featureId);
      await prefs.setStringList(_key, shown);
    }
  }

  
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  
  static Future<void> reset(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getStringList(_key) ?? [];
    shown.remove(featureId);
    await prefs.setStringList(_key, shown);
  }
}
