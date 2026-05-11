import 'package:flutter/services.dart';

class HWSecureSaver {
  static const MethodChannel _channel = MethodChannel('token_saver');

  /// Save specific key using native secure hardware (StrongBox / KeyStore)
  static Future<void> save(String key, String value) async {
    await _channel.invokeMethod('saveToken', {
      'key': key,
      'value': value,
    });
  }

  /// Get specific key
  static Future<String?> get(String key) async {
    return await _channel.invokeMethod('getToken', {
      'key': key,
    });
  }

  /// Delete specific key
  static Future<void> delete(String key) async {
    await _channel.invokeMethod('deleteToken', {
      'key': key,
    });
  }

  /// Rotate token securely (creates new AES key and overwrites)
  static Future<void> rotate(String key, String newValue) async {
    await _channel.invokeMethod('rotateKey', {
      'key': key,
      'value': newValue,
    });
  }
}
