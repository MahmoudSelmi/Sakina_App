import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._internal();
  static final LocalStorage instance = LocalStorage._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('LocalStorage.init() لازم يتنادى قبل الاستخدام');
    }
    return prefs;
  }

  Future<void> setString(String key, String value) => _p.setString(key, value);
  String? getString(String key) => _p.getString(key);

  Future<void> setInt(String key, int value) => _p.setInt(key, value);
  int? getInt(String key) => _p.getInt(key);

  Future<void> setDouble(String key, double value) => _p.setDouble(key, value);
  double? getDouble(String key) => _p.getDouble(key);

  Future<void> setBool(String key, bool value) => _p.setBool(key, value);
  bool? getBool(String key) => _p.getBool(key);

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      _p.setString(key, jsonEncode(value));

  Map<String, dynamic>? getJson(String key) {
    final raw = _p.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setStringList(String key, List<String> value) =>
      _p.setStringList(key, value);
  List<String> getStringList(String key) => _p.getStringList(key) ?? [];

  Future<void> remove(String key) => _p.remove(key);
}

class StorageKeys {
  StorageKeys._();
  static const String lastReciterId = 'last_reciter_id';
  static const String lastMoshafId = 'last_moshaf_id';
  static const String lastSurahNumber = 'last_surah_number';
  static const String lastPositionMs = 'last_position_ms';
  static const String playQueue = 'play_queue';
  static const String favoriteReciters = 'favorite_reciters';
  static const String favoriteSurahs = 'favorite_surahs';
  static const String recentlyPlayed = 'recently_played';
  static const String downloadedSurahs = 'downloaded_surahs';
  static const String playlists = 'playlists';
  static const String themeMode = 'theme_mode';
  static const String defaultSpeed = 'default_speed';
  static const String defaultSleepMinutes = 'default_sleep_minutes';
  static const String wifiOnlyDownload = 'wifi_only_download';
  static const String volumeBoosts = 'volume_boosts';
  static const String khatmaProgress = 'khatma_progress';
  static const String khatmaCount = 'khatma_count';
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String favoriteAyahs = 'favorite_ayahs';
  static const String streakLastDate = 'streak_last_date';
  static const String streakCurrent = 'streak_current';
  static const String streakLongest = 'streak_longest';
  static const String ambientSound = 'ambient_sound';
  static const String ambientVolume = 'ambient_volume';
}
