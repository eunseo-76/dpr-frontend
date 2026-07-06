import 'package:flutter/services.dart';

class ScreenSecurityService {
  static const _channel = MethodChannel('dpr/screen_security');

  static Future<void> enable() async {
    await _channel.invokeMethod('enableScreenSecurity');
  }

  static Future<void> disable() async {
    await _channel.invokeMethod('disableScreenSecurity');
  }
}