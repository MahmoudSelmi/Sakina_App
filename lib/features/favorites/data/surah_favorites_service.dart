import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage.dart';
import '../../player/data/queue_item.dart';

/// خدمة "السور المفضلة" - مختلفة عن مفضلة القراء: هنا المستخدم بيحفظ سورة
/// معينة بصوت قارئ معين (مثلًا سورة الكهف بصوت الشيخ الحصري) عشان يرجعلها
/// بسرعة من غير ما يدور تاني.
class SurahFavoritesService {
  SurahFavoritesService._internal();
  static final SurahFavoritesService instance = SurahFavoritesService._internal();

  final ValueNotifier<Map<String, QueueItem>> favorites =
      ValueNotifier<Map<String, QueueItem>>(const {});

  void load() {
    final raw = LocalStorage.instance.getStringList(StorageKeys.favoriteSurahs);
    final map = <String, QueueItem>{};
    for (final e in raw) {
      try {
        final item = QueueItem.decode(e);
        map[item.key] = item;
      } catch (_) {
        // نتجاهل أي سطر تالف
      }
    }
    favorites.value = map;
  }

  bool isFavorite(String key) => favorites.value.containsKey(key);

  Future<void> toggle(QueueItem item) async {
    final updated = Map<String, QueueItem>.from(favorites.value);
    if (!updated.containsKey(item.key)) {
      updated[item.key] = item;
    } else {
      updated.remove(item.key);
    }
    favorites.value = updated;
    await LocalStorage.instance.setStringList(
      StorageKeys.favoriteSurahs,
      updated.values.map(QueueItem.encode).toList(),
    );
  }
}
