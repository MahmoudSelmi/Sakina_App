import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage.dart';
import '../../player/data/queue_item.dart';
import 'playlist_model.dart';

/// إدارة قوائم التشغيل المخصّصة: إنشاء، حذف، إضافة/شيل سورة، كل حاجة
/// بتتحفظ محليًا وتفضل موجودة حتى لو قفلت التطبيق.
class PlaylistsService {
  PlaylistsService._internal();
  static final PlaylistsService instance = PlaylistsService._internal();

  final ValueNotifier<List<Playlist>> playlists =
      ValueNotifier<List<Playlist>>(const []);

  void load() {
    final raw = LocalStorage.instance.getString(StorageKeys.playlists);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List;
      playlists.value = decoded
          .map((e) => Playlist.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      playlists.value = const [];
    }
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(playlists.value.map((p) => p.toJson()).toList());
    await LocalStorage.instance.setString(StorageKeys.playlists, encoded);
  }

  Future<Playlist> createPlaylist(String name) async {
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'قائمتي' : name.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      items: const [],
    );
    playlists.value = [...playlists.value, playlist];
    await _persist();
    return playlist;
  }

  Future<void> renamePlaylist(String id, String newName) async {
    playlists.value = playlists.value
        .map((p) => p.id == id ? p.copyWith(name: newName) : p)
        .toList();
    await _persist();
  }

  Future<void> deletePlaylist(String id) async {
    playlists.value = playlists.value.where((p) => p.id != id).toList();
    await _persist();
  }

  bool contains(String playlistId, QueueItem item) {
    final playlist = playlists.value.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => const Playlist(id: '', name: '', createdAt: 0, items: []),
    );
    return playlist.items.contains(item);
  }

  Future<void> addItem(String playlistId, QueueItem item) async {
    playlists.value = playlists.value.map((p) {
      if (p.id != playlistId) return p;
      if (p.items.contains(item)) return p;
      return p.copyWith(items: [...p.items, item]);
    }).toList();
    await _persist();
  }

  Future<void> removeItem(String playlistId, QueueItem item) async {
    playlists.value = playlists.value.map((p) {
      if (p.id != playlistId) return p;
      return p.copyWith(items: p.items.where((e) => e != item).toList());
    }).toList();
    await _persist();
  }

  /// بيعيد ترتيب سور قائمة تشغيل معينة (بيتستخدم مع السحب والإفلات).
  Future<void> reorderItems(
      String playlistId, int oldIndex, int newIndex) async {
    playlists.value = playlists.value.map((p) {
      if (p.id != playlistId) return p;
      final items = List<QueueItem>.from(p.items);
      var target = newIndex;
      if (oldIndex < target) target -= 1;
      final moved = items.removeAt(oldIndex);
      items.insert(target, moved);
      return p.copyWith(items: items);
    }).toList();
    await _persist();
  }
}
