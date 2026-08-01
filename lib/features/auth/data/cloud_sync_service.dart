import 'package:cloud_firestore/cloud_firestore.dart';
import '../../favorites/data/favorites_service.dart';
import '../../favorites/data/surah_favorites_service.dart';
import '../../khatma/data/khatma_service.dart';
import '../../playlists/data/playlist_model.dart';
import '../../playlists/data/playlists_service.dart';
import '../../streak/data/streak_service.dart';
import 'auth_service.dart';

/// مزامنة اختيارية للبيانات مع Firestore - بتشتغل بس لو المستخدم مسجّل
/// دخول فعليًا. بترفع نسخة من مفضلاتك وقوائمك وتقدّم ختمتك، وبترجعها لو
/// دخلت من جهاز تاني بنفس الحساب.
class CloudSyncService {
  CloudSyncService._internal();
  static final CloudSyncService instance = CloudSyncService._internal();

  DocumentReference<Map<String, dynamic>>? _userDoc() {
    final user = AuthService.instance.currentUser.value;
    if (user == null || !AuthService.instance.isAvailable) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  /// بيرفع الوضع الحالي لكل البيانات المهمة لفايربيز.
  Future<void> pushLocalData() async {
    final doc = _userDoc();
    if (doc == null) return;

    await doc.set({
      'favoriteReciters': FavoritesService.instance.favorites.value.toList(),
      'favoriteSurahs':
          SurahFavoritesService.instance.favorites.value.values.map((e) => e.key).toList(),
      'playlists': PlaylistsService.instance.playlists.value.map((p) => p.toJson()).toList(),
      'khatmaCompletedSurahs': KhatmaService.instance.completedSurahs.value.toList(),
      'khatmaCount': KhatmaService.instance.khatmaCount.value,
      'streakCurrent': StreakService.instance.currentStreak.value,
      'streakLongest': StreakService.instance.longestStreak.value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// بيجيب آخر نسخة محفوظة من فايربيز لما تسجّل دخول من جهاز جديد.
  /// (استرجاع القوائم بالكامل - المفضلة بتتظبط منفصل حسب النوع)
  Future<List<Playlist>> pullPlaylists() async {
    final doc = _userDoc();
    if (doc == null) return [];
    final snapshot = await doc.get();
    final data = snapshot.data();
    if (data == null || data['playlists'] == null) return [];
    final list = data['playlists'] as List;
    return list
        .map((e) => Playlist.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
