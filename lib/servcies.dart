import 'package:flutter/services.dart';

class SecureScreen {
  static const MethodChannel _channel =
  MethodChannel('secure_screen');

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enableSecure');
    } catch (_) {}
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disableSecure');
    } catch (_) {}
  }
}
