import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage.dart';

/// مفضلة على مستوى الآية الواحدة (مش السورة كلها) - عشان تحفظ آية معينة
/// عجبتك وترجعلها بسرعة.
class AyahFavoritesService {
  AyahFavoritesService._internal();
  static final AyahFavoritesService instance = AyahFavoritesService._internal();

  /// كل عنصر بالشكل "رقم السورة:رقم الآية".
  final ValueNotifier<Set<String>> favorites = ValueNotifier<Set<String>>({});

  void load() {
    favorites.value = LocalStorage.instance.getStringList(StorageKeys.favoriteAyahs).toSet();
  }

  String _key(int surah, int ayah) => '$surah:$ayah';

  bool isFavorite(int surah, int ayah) => favorites.value.contains(_key(surah, ayah));

  Future<void> toggle(int surah, int ayah) async {
    final key = _key(surah, ayah);
    final updated = Set<String>.from(favorites.value);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    favorites.value = updated;
    await LocalStorage.instance.setStringList(StorageKeys.favoriteAyahs, updated.toList());
  }
}
