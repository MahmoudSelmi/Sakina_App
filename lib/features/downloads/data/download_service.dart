import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/storage/local_storage.dart';

enum DownloadStatus { none, downloading, done, error }

@immutable
class DownloadState {
  final DownloadStatus status;
  final double progress;

  const DownloadState({this.status = DownloadStatus.none, this.progress = 0});

  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isDone => status == DownloadStatus.done;
}

/// خدمة تحميل السور للاستماع الأوفلاين. بتحفظ ملفات الـ mp3 في مجلد التطبيق
/// وبتحتفظ بخريطة (مفتاح السورة -> مسار الملف) في التخزين المحلي عشان
/// تفضل موجودة حتى بعد إغلاق التطبيق.
class DownloadService {
  DownloadService._internal();
  static final DownloadService instance = DownloadService._internal();

  final Dio _dio = Dio();
  Map<String, String> _paths = {};

  /// حالة كل تحميل (جاري / تم / فشل) عشان الواجهة تتحدث لحظيًا.
  final ValueNotifier<Map<String, DownloadState>> states =
      ValueNotifier<Map<String, DownloadState>>({});

  void load() {
    final saved = LocalStorage.instance.getJson(StorageKeys.downloadedSurahs) ?? {};
    _paths = saved.map((key, value) => MapEntry(key, value.toString()));
  }

  bool isDownloaded(String key) => _paths.containsKey(key);

  String? localPath(String key) => _paths[key];

  DownloadState stateFor(String key) => states.value[key] ?? const DownloadState();

  Future<void> download(String key, String url) async {
    if (isDownloaded(key) || stateFor(key).isDownloading) return;

    _emit(key, const DownloadState(status: DownloadStatus.downloading, progress: 0));

    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/quran_downloads');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      final filePath = '${folder.path}/$key.mp3';

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _emit(key, DownloadState(status: DownloadStatus.downloading, progress: received / total));
          }
        },
      );

      _paths[key] = filePath;
      await _persist();
      _emit(key, const DownloadState(status: DownloadStatus.done, progress: 1));
    } catch (_) {
      _emit(key, const DownloadState(status: DownloadStatus.error, progress: 0));
    }
  }

  Future<void> deleteDownload(String key) async {
    final path = _paths[key];
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      _paths.remove(key);
      await _persist();
    }
    _emit(key, const DownloadState());
  }

  Future<void> _persist() async {
    await LocalStorage.instance.setJson(StorageKeys.downloadedSurahs, _paths);
  }

  void _emit(String key, DownloadState state) {
    final updated = Map<String, DownloadState>.from(states.value);
    updated[key] = state;
    states.value = updated;
  }
}
