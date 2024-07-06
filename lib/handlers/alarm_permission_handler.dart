import 'package:flutter/services.dart';

class AlarmPermissionHandler {
  static const MethodChannel _channel = MethodChannel('alarm_permission');

  static Future<bool> requestExactAlarmPermission() async {
    final bool granted =
        await _channel.invokeMethod('requestExactAlarmPermission');
    return granted;
  }
}
