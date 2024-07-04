import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  Future<void> storeDynamicList(String name, List<dynamic> dynamicList) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList =
        dynamicList.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList(name, jsonList);
  }

  Future<List<String>> getDynamicList(String name) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList(name);
    if (jsonList != null) {
      // Procesar cada elemento para quitar las comillas adicionales
      return jsonList
          .map((jsonString) => jsonString.replaceAll('"', ''))
          .toList();
    } else {
      return [];
    }
  }

  Future<void> clearPrefs() async {
    final fcm = FirebaseMessaging.instance;
    final prefs = await SharedPreferences.getInstance();
    String? newsTopic = prefs.getString('newsTopic');
    String? messagesTopic = prefs.getString('messagesTopic');

    if (newsTopic != null && newsTopic.isNotEmpty) {
      await fcm.unsubscribeFromTopic(newsTopic);
    }

    if (messagesTopic != null && messagesTopic.isNotEmpty) {
      await fcm.unsubscribeFromTopic(messagesTopic);
    }

    await prefs.clear();
  }

  Future<void> printAllPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      var value = prefs.get(key);
      print('$key: $value (Type: ${value.runtimeType})');
    }
  }
}
