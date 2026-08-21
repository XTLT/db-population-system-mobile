import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class SearchHistoryService {
  static const String _key = 'search_history';
  static const int _maxHistory = 10;
  
  
  static Future<void> saveSearch(Map<String, dynamic> searchParams) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    
    history.insert(0, {
      'params': searchParams,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }
    
    await prefs.setString(_key, jsonEncode(history));
  }
  
  
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    
    if (data == null) return [];
    
    try {
      final List<dynamic> history = jsonDecode(data);
      return history.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
  
  
  static Future<void> deleteHistoryItem(int index) async {
    final history = await getHistory();
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(history));
    }
  }
  
  
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
  
  
  static String formatSearchParams(Map<String, dynamic> params) {
    final parts = <String>[];
    
    if (params['name'] != null && params['name'].toString().isNotEmpty) {
      parts.add('姓名: ${params['name']}');
    }
    if (params['idCard'] != null && params['idCard'].toString().isNotEmpty) {
      parts.add('身份证: ${params['idCard']}');
    }
    if (params['huHao'] != null && params['huHao'].toString().isNotEmpty) {
      parts.add('户号: ${params['huHao']}');
    }
    if (params['address'] != null && params['address'].toString().isNotEmpty) {
      parts.add('地址: ${params['address']}');
    }
    if (params['ageMin'] != null || params['ageMax'] != null) {
      final min = params['ageMin'] ?? '';
      final max = params['ageMax'] ?? '';
      parts.add('年龄: $min-$max');
    }
    if (params['disability'] != null && params['disability'].toString().isNotEmpty) {
      parts.add('残疾: ${params['disability']}');
    }
    if (params['dibao'] != null && params['dibao'].toString().isNotEmpty) {
      parts.add('低保: ${params['dibao']}');
    }
    if (params['isDead'] != null && params['isDead'].toString().isNotEmpty) {
      parts.add('去世: ${params['isDead']}');
    }
    
    return parts.isEmpty ? '无条件' : parts.join(', ');
  }
}
