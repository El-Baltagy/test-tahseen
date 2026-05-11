import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

 class BaseLocalRepo {
  
  /// Persist a map to local storage.
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      // Log error or handle as needed
    }
  }

  /// Remove data from local storage by key.
  Future<void> clearData(String key) async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove(key);
    } catch (e) {
      // Log error or handle as needed
    }
  }

  /// Read data from local storage by key and return as Map.
  Future<Map<String, dynamic>?> readData(String key) async {
    try {
      return null;
      // final prefs = await SharedPreferences.getInstance();
      // final raw = prefs.getString(key);
      // if (raw == null) return null;
      // return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}


