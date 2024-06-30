import 'dart:convert';

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
      return jsonList
          .map((jsonString) => jsonEncode(jsonDecode(jsonString)))
          .toList();
    } else {
      return [];
    }
  }

  Future<void> clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
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
