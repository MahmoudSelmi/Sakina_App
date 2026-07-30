import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/storage/local_storage.dart';
import '../../player/data/queue_item.dart';

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
/// وبتحتفظ ببيانات كل سورة محمّلة (المسار + اسم القارئ/السورة) في التخزين
/// المحلي، عشان شاشة "التحميلات" تقدر تعرضها حتى بعد إغلاق التطبيق.
class DownloadService {
  DownloadService._internal();
  static final DownloadService instance = DownloadService._internal();

  final Dio _dio = Dio();

  /// key -> {'path': ..., 'item': encoded QueueItem}
  Map<String, Map<String, String>> _entries = {};

  /// قائمة كل السور المحمّلة، بتتحدث تلقائيًا عشان شاشة التحميلات تعرضها.
  final ValueNotifier<List<QueueItem>> downloadedItems =
      ValueNotifier<List<QueueItem>>(const []);

  /// حالة كل تحميل (جاري / تم / فشل) عشان الواجهة تتحدث لحظيًا.
  final ValueNotifier<Map<String, DownloadState>> states =
      ValueNotifier<Map<String, DownloadState>>({});

  void load() {
    final raw = LocalStorage.instance.getString(StorageKeys.downloadedSurahs);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _entries = decoded.map(
        (key, value) => MapEntry(key, Map<String, String>.from(value as Map)),
      );
      _refreshItemsList();
    } catch (_) {
      _entries = {};
    }
  }

  void _refreshItemsList() {
    final items = <QueueItem>[];
    for (final entry in _entries.values) {
      final encoded = entry['item'];
      if (encoded == null) continue;
      try {
        items.add(QueueItem.decode(encoded));
      } catch (_) {
        // نتجاهل أي سطر تالف
      }
    }
    downloadedItems.value = items;
  }

  bool isDownloaded(String key) => _entries.containsKey(key);

  String? localPath(String key) => _entries[key]?['path'];

  DownloadState stateFor(String key) => states.value[key] ?? const DownloadState();

  Future<void> download(QueueItem item) async {
    final key = item.key;
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
        item.audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _emit(key, DownloadState(status: DownloadStatus.downloading, progress: received / total));
          }
        },
      );

      _entries[key] = {'path': filePath, 'item': QueueItem.encode(item)};
      await _persist();
      _refreshItemsList();
      _emit(key, const DownloadState(status: DownloadStatus.done, progress: 1));
    } catch (_) {
      _emit(key, const DownloadState(status: DownloadStatus.error, progress: 0));
    }
  }

  Future<void> deleteDownload(String key) async {
    final path = _entries[key]?['path'];
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      _entries.remove(key);
      await _persist();
      _refreshItemsList();
    }
    _emit(key, const DownloadState());
  }

  /// بيمسح كل التحميلات دفعة واحدة (بيتستخدم من شاشة الإعدادات).
  Future<void> clearAll() async {
    for (final entry in _entries.values) {
      final path = entry['path'];
      if (path == null) continue;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _entries = {};
    states.value = {};
    await _persist();
    _refreshItemsList();
  }

  Future<void> _persist() async {
    await LocalStorage.instance.setString(
      StorageKeys.downloadedSurahs,
      jsonEncode(_entries),
    );
  }

  void _emit(String key, DownloadState state) {
    final updated = Map<String, DownloadState>.from(states.value);
    updated[key] = state;
    states.value = updated;
  }
}
