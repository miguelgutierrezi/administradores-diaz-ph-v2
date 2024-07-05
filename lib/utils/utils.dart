import 'package:flutter/foundation.dart';

class Utils {
  static void debugPrint(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
}
