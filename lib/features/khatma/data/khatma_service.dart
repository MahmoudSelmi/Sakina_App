import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage.dart';

/// "ختمتي" - بيتابع أي سور استمعتلها كاملة كجزء من دورة قراءة/استماع
/// واحدة (ختمة)، وبيحتفل بيك لما تخلّص الـ 114 سورة كلهم، وبعدين يبدأ
/// دورة جديدة من الصفر ويزوّد عداد "عدد الختمات" بتاعتك.
class KhatmaService {
  KhatmaService._internal();
  static final KhatmaService instance = KhatmaService._internal();

  static const int totalSurahs = 114;

  final ValueNotifier<Set<int>> completedSurahs = ValueNotifier<Set<int>>({});
  final ValueNotifier<int> khatmaCount = ValueNotifier<int>(0);

  /// بيتنادى مرة واحدة بس لما ختمة جديدة تكتمل، عشان الواجهة تعرض احتفال.
  void Function(int khatmaNumber)? onKhatmaCompleted;

  void load() {
    final raw = LocalStorage.instance.getString(StorageKeys.khatmaProgress);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        completedSurahs.value = decoded.map((e) => e as int).toSet();
      } catch (_) {
        completedSurahs.value = {};
      }
    }
    khatmaCount.value = LocalStorage.instance.getInt(StorageKeys.khatmaCount) ?? 0;
  }

  double get progress => completedSurahs.value.length / totalSurahs;

  Future<void> markSurahCompleted(int surahNumber) async {
    if (completedSurahs.value.contains(surahNumber)) return;

    final updated = Set<int>.from(completedSurahs.value)..add(surahNumber);
    completedSurahs.value = updated;
    await _persistProgress();

    if (updated.length >= totalSurahs) {
      await _completeKhatma();
    }
  }

  Future<void> _completeKhatma() async {
    final newCount = khatmaCount.value + 1;
    khatmaCount.value = newCount;
    await LocalStorage.instance.setInt(StorageKeys.khatmaCount, newCount);

    // نبدأ دورة جديدة من الصفر.
    completedSurahs.value = {};
    await _persistProgress();

    onKhatmaCompleted?.call(newCount);
  }

  Future<void> _persistProgress() async {
    await LocalStorage.instance.setString(
      StorageKeys.khatmaProgress,
      jsonEncode(completedSurahs.value.toList()),
    );
  }
}
