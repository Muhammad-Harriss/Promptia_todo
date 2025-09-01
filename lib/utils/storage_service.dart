import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static const String authKey = 'authkey';

  static Future<void> saveSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(authKey, jsonEncode(session.toJson()));
  }

  static Future<String?> getRawSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(authKey);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(authKey);
  }
}
