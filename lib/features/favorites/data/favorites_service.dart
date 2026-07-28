import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage.dart';

/// خدمة بسيطة لإدارة القراء المفضلين، متخزنة محليًا وبتتحدث كل الشاشة
/// اللي بتسمعها عن طريق [favorites] (ValueNotifier).
class FavoritesService {
  FavoritesService._internal();
  static final FavoritesService instance = FavoritesService._internal();

  final ValueNotifier<Set<int>> favorites = ValueNotifier<Set<int>>(<int>{});

  void load() {
    final saved = LocalStorage.instance.getStringList(StorageKeys.favoriteReciters);
    favorites.value = saved.map((e) => int.tryParse(e)).whereType<int>().toSet();
  }

  bool isFavorite(int reciterId) => favorites.value.contains(reciterId);

  Future<void> toggle(int reciterId) async {
    final updated = Set<int>.from(favorites.value);
    if (!updated.remove(reciterId)) {
      updated.add(reciterId);
    }
    favorites.value = updated;
    await LocalStorage.instance.setStringList(
      StorageKeys.favoriteReciters,
      updated.map((e) => e.toString()).toList(),
    );
  }
}
