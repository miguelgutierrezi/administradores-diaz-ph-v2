import 'package:flutter/services.dart';

class AlarmPermissionHandler {
  static const MethodChannel _channel = MethodChannel('alarm_permission');

  // Método para verificar si el permiso ya está concedido
  static Future<bool> isExactAlarmPermissionGranted() async {
    final bool granted =
        await _channel.invokeMethod('isExactAlarmPermissionGranted');
    return granted;
  }

  // Método para solicitar el permiso solo si no está concedido
  static Future<bool> requestExactAlarmPermission() async {
    final bool alreadyGranted = await isExactAlarmPermissionGranted();
    if (alreadyGranted) {
      return true;
    } else {
      final bool granted =
          await _channel.invokeMethod('requestExactAlarmPermission');
      return granted;
    }
  }
}
