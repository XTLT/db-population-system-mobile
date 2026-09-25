


import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityUtils {
  
  
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  
  
  static String hashPasswordWithSalt(String password, String salt) {
    final combined = salt + password;
    return hashPassword(combined);
  }
}
