import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class SavedFilterService {
  static const String _key = 'saved_filters';
  
  
  static Future<void> saveFilter(String name, Map<String, dynamic> filterParams) async {
    final prefs = await SharedPreferences.getInstance();
    final filters = await getFilters();
    
    
    final existingIndex = filters.indexWhere((f) => f['name'] == name);
    if (existingIndex >= 0) {
      
      filters[existingIndex] = {
        'name': name,
        'params': filterParams,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } else {
      
      filters.add({
        'name': name,
        'params': filterParams,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    
    await prefs.setString(_key, jsonEncode(filters));
  }
  
  
  static Future<List<Map<String, dynamic>>> getFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    
    if (data == null) return [];
    
    try {
      final List<dynamic> filters = jsonDecode(data);
      return filters.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
  
  
  static Future<void> deleteFilter(String name) async {
    final filters = await getFilters();
    filters.removeWhere((f) => f['name'] == name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(filters));
  }
  
  
  static Future<void> clearFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
  
  
  static Future<Map<String, dynamic>?> getFilter(String name) async {
    final filters = await getFilters();
    final index = filters.indexWhere((f) => f['name'] == name);
    return index >= 0 ? filters[index] : null;
  }
}
