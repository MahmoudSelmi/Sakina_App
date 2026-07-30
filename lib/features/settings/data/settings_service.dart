import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage.dart';
import '../../downloads/data/download_service.dart';

/// إعدادات التطبيق العامة: سرعة التشغيل الافتراضية، مؤقت النوم
/// الافتراضي، والتحميل على الواي فاي بس (توفير للنت).
class SettingsService {
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  final ValueNotifier<double> defaultSpeed = ValueNotifier<double>(1.0);
  final ValueNotifier<int?> defaultSleepMinutes = ValueNotifier<int?>(null);
  final ValueNotifier<bool> wifiOnlyDownload = ValueNotifier<bool>(false);

  void load() {
    defaultSpeed.value = LocalStorage.instance.getDouble(StorageKeys.defaultSpeed) ?? 1.0;
    defaultSleepMinutes.value = LocalStorage.instance.getInt(StorageKeys.defaultSleepMinutes);
    wifiOnlyDownload.value = LocalStorage.instance.getBool(StorageKeys.wifiOnlyDownload) ?? false;
  }

  Future<void> setDefaultSpeed(double speed) async {
    defaultSpeed.value = speed;
    await LocalStorage.instance.setDouble(StorageKeys.defaultSpeed, speed);
  }

  Future<void> setDefaultSleepMinutes(int? minutes) async {
    defaultSleepMinutes.value = minutes;
    if (minutes == null) {
      await LocalStorage.instance.remove(StorageKeys.defaultSleepMinutes);
    } else {
      await LocalStorage.instance.setInt(StorageKeys.defaultSleepMinutes, minutes);
    }
  }

  Future<void> setWifiOnlyDownload(bool value) async {
    wifiOnlyDownload.value = value;
    await LocalStorage.instance.setBool(StorageKeys.wifiOnlyDownload, value);
  }

  Future<void> clearAllDownloads() => DownloadService.instance.clearAll();

  /// بيتأكد إن التحميل مسموح دلوقتي حسب إعداد "واي فاي بس".
  Future<bool> canDownloadNow() async {
    if (!wifiOnlyDownload.value) return true;
    try {
      final result = await Connectivity().checkConnectivity();
      return result.contains(ConnectivityResult.wifi);
    } catch (_) {
      return true;
    }
  }
}
