import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage.dart';
import '../../player/data/queue_item.dart';

/// بيتتبع آخر سورة اتسمعت من كل قارئ، عشان قسم "استكمل الاستماع" في
/// الشاشة الرئيسية. آخر عنصر مُضاف بيظهر الأول.
class RecentlyPlayedService {
  RecentlyPlayedService._internal();
  static final RecentlyPlayedService instance = RecentlyPlayedService._internal();

  final ValueNotifier<List<QueueItem>> items = ValueNotifier<List<QueueItem>>(const []);

  void load() {
    final raw = LocalStorage.instance.getStringList(StorageKeys.recentlyPlayed);
    items.value = _decodeAll(raw);
  }

  List<QueueItem> _decodeAll(List<String> raw) {
    final result = <QueueItem>[];
    for (final e in raw) {
      try {
        result.add(QueueItem.decode(e));
      } catch (_) {
        // نتجاهل أي سطر تالف بدل ما نكسر الشاشة كلها
      }
    }
    return result;
  }

  Future<void> add(QueueItem item) async {
    final updated = List<QueueItem>.from(items.value);
    updated.removeWhere((e) => e.reciterId == item.reciterId);
    updated.insert(0, item);
    final trimmed = updated.take(30).toList();
    items.value = trimmed;
    await LocalStorage.instance.setStringList(
      StorageKeys.recentlyPlayed,
      trimmed.map(QueueItem.encode).toList(),
    );
  }
}
