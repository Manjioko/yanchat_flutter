import 'package:shared_preferences/shared_preferences.dart';

class Share {
  static final Share _instance = Share._internal();

  factory Share() => _instance;

  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  Share._internal();


  static Share get instance => _instance;

  Future<bool> setBool(String key, bool value) async {
    final p = await prefs;
    return p.setBool(key, value);
  }

  Future<bool> getBool(String key) async {
    final p = await prefs;
    return p.getBool(key) ?? false;
  }
  Future<bool> remove(String key) async {
    final p = await prefs;
    return p.remove(key);
  }

  Future<bool> setString(String key, String value) async {
    final p = await prefs;
    return p.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }
  Future<bool> setInt(String key, int value) async {
    final p = await prefs;
    return p.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final p = await prefs;
    return p.getInt(key);
  }
}