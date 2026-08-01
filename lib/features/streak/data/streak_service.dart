import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage.dart';

/// بيتابع "سلسلة الأيام المتواصلة" اللي المستخدم سمع فيها القرآن، زي
/// تطبيقات تعلّم اللغات - عشان يخلي الاستماع عادة يومية حقيقية بدل ما
/// يبقى بس لما يتذكر التطبيق.
class StreakService {
  StreakService._internal();
  static final StreakService instance = StreakService._internal();

  final ValueNotifier<int> currentStreak = ValueNotifier<int>(0);
  final ValueNotifier<int> longestStreak = ValueNotifier<int>(0);

  String? _lastListenDate;

  void load() {
    _lastListenDate = LocalStorage.instance.getString(StorageKeys.streakLastDate);
    currentStreak.value = LocalStorage.instance.getInt(StorageKeys.streakCurrent) ?? 0;
    longestStreak.value = LocalStorage.instance.getInt(StorageKeys.streakLongest) ?? 0;

    // لو فات يوم من غير استماع، السلسلة بترجع صفر لما التطبيق يفتح
    // (مش بس لما يسمع)، عشان الرقم المعروض يبقى صادق مع الواقع.
    if (_lastListenDate != null && !_isToday(_lastListenDate!) && !_isYesterday(_lastListenDate!)) {
      currentStreak.value = 0;
      LocalStorage.instance.setInt(StorageKeys.streakCurrent, 0);
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  bool _isToday(String dateKey) => dateKey == _todayKey();

  bool _isYesterday(String dateKey) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateKey == '${yesterday.year}-${yesterday.month}-${yesterday.day}';
  }

  /// بيتنادى لما المستخدم يسمع فعليًا (مش بس يفتح التطبيق).
  Future<void> recordListen() async {
    final today = _todayKey();
    if (_lastListenDate == today) return; // اتسجل النهاردة بالفعل

    int newStreak;
    if (_lastListenDate != null && _isYesterday(_lastListenDate!)) {
      newStreak = currentStreak.value + 1;
    } else {
      newStreak = 1;
    }

    _lastListenDate = today;
    currentStreak.value = newStreak;
    if (newStreak > longestStreak.value) {
      longestStreak.value = newStreak;
      await LocalStorage.instance.setInt(StorageKeys.streakLongest, newStreak);
    }

    await LocalStorage.instance.setString(StorageKeys.streakLastDate, today);
    await LocalStorage.instance.setInt(StorageKeys.streakCurrent, newStreak);
  }
}
