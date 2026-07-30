import 'package:flutter/material.dart';
import '../../features/player/data/queue_item.dart';
import '../../features/reciters/data/models/reciter_model.dart';
import '../../features/reciters/data/models/moshaf_model.dart';

/// أجواء الاستماع المقترحة - كل حالة ليها سور مناسبة لطبيعتها وأسلوب
/// تلاوة يناسبها (هادي للنوم، ثابت للمذاكرة/الشغل، بروح للجيم).
enum Mood { sleep, study, work, gym }

class MoodInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final List<int> surahNumbers;
  final List<String> preferredMoshafKeywords;

  const MoodInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.surahNumbers,
    required this.preferredMoshafKeywords,
  });
}

class MoodCatalog {
  MoodCatalog._();

  static const Map<Mood, MoodInfo> all = {
    Mood.sleep: MoodInfo(
      title: 'وقت النوم',
      subtitle: 'سور مأثورة يُستحب سماعها قبل النوم، بصوت هادئ ومطمئن',
      icon: Icons.nightlight_round,
      gradient: [Color(0xFF2B3A67), Color(0xFF13182B)],
      // الملك، الواقعة، الرحمن، يس، والمعوذتين + الإخلاص (سنة قبل النوم)
      surahNumbers: [67, 56, 55, 36, 112, 113, 114],
      preferredMoshafKeywords: ['ترتيل', 'مرتل'],
    ),
    Mood.study: MoodInfo(
      title: 'وقت المذاكرة',
      subtitle: 'تلاوة هادئة وثابتة تساعدك تركّز من غير ما تشتت بالك',
      icon: Icons.menu_book_rounded,
      gradient: [Color(0xFF1F4E44), Color(0xFF0E241F)],
      // جزء عمّ - سور قصيرة بتتكرر بسلاسة كخلفية هادية للمذاكرة
      surahNumbers: [78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90],
      preferredMoshafKeywords: ['ترتيل', 'مرتل'],
    ),
    Mood.work: MoodInfo(
      title: 'وقت الشغل',
      subtitle: 'سور متوسطة الطول تفضل شغالة في الخلفية بدون ما تحتاج تبدّلها كتير',
      icon: Icons.work_rounded,
      gradient: [Color(0xFF5B4425), Color(0xFF241C10)],
      surahNumbers: [18, 36, 55, 67, 76],
      preferredMoshafKeywords: ['ترتيل', 'مرتل'],
    ),
    Mood.gym: MoodInfo(
      title: 'وقت الجيم',
      subtitle: 'تلاوة بروح وسور فيها معاني الثبات والقوة، بأداء أسرع شوية',
      icon: Icons.fitness_center_rounded,
      gradient: [Color(0xFF7A2E2E), Color(0xFF2B1010)],
      // الصف، محمد، الأنفال، الأحزاب - سور فيها معاني الثبات والعزيمة
      surahNumbers: [61, 47, 8, 33],
      preferredMoshafKeywords: ['حدر', 'تجويد'],
    ),
  };
}

/// بيبني قائمة تشغيل مناسبة لكل "أجواء" من قائمة القراء المتاحة فعليًا،
/// بمحاولة اختيار الرواية (ترتيل/حدر..) الأقرب لطبيعة الأجواء، ولو مش
/// لاقي رواية بنفس الوصف بيكتفي بأي رواية متاحة للسورة عشان القائمة
/// متطلعش فاضية.
class MoodPlaylistBuilder {
  MoodPlaylistBuilder._();

  static List<QueueItem> build(Mood mood, List<ReciterModel> reciters) {
    final info = MoodCatalog.all[mood]!;
    final items = <QueueItem>[];

    for (final surahNumber in info.surahNumbers) {
      final match = _bestMatchFor(surahNumber, info.preferredMoshafKeywords, reciters);
      if (match != null) items.add(match);
    }
    return items;
  }

  static QueueItem? _bestMatchFor(
    int surahNumber,
    List<String> preferredKeywords,
    List<ReciterModel> reciters,
  ) {
    ReciterModel? fallbackReciter;
    MoshafModel? fallbackMoshaf;

    for (final reciter in reciters) {
      for (final moshaf in reciter.moshaf) {
        if (!moshaf.hasSurah(surahNumber)) continue;
        fallbackReciter ??= reciter;
        fallbackMoshaf ??= moshaf;

        final isPreferred = preferredKeywords.any((k) => moshaf.name.contains(k));
        if (isPreferred) {
          return QueueItem.fromReciter(reciter: reciter, moshaf: moshaf, surahNumber: surahNumber);
        }
      }
    }

    if (fallbackReciter != null && fallbackMoshaf != null) {
      return QueueItem.fromReciter(
        reciter: fallbackReciter,
        moshaf: fallbackMoshaf,
        surahNumber: surahNumber,
      );
    }
    return null;
  }
}
