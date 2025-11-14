import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  static LocalStorageService get instance => _instance;

  LocalStorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('LocalStorageService initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize LocalStorageService', e, stackTrace);
      rethrow;
    }
  }

  // String
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  // Int
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // Bool
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Double
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  // StringList
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  // Remove
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  // Clear all
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  // Check if key exists
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  // Get all keys
  Set<String> getKeys() {
    return _prefs.getKeys();
  }
}

// Storage Keys
class StorageKeys {
  static const String isFirstLaunch = 'is_first_launch';
  static const String language = 'language';
  static const String theme = 'theme';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String voiceEnabled = 'voice_enabled';
  static const String locationEnabled = 'location_enabled';
}
