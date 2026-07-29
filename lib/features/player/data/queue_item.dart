import '../../reciters/data/models/reciter_model.dart';
import '../../reciters/data/models/moshaf_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/surah_data.dart';

class QueueItem {
  final int reciterId;
  final String reciterName;
  final int moshafId;
  final String moshafServer;
  final int surahNumber;

  const QueueItem({
    required this.reciterId,
    required this.reciterName,
    required this.moshafId,
    required this.moshafServer,
    required this.surahNumber,
  });

  factory QueueItem.fromReciter({
    required ReciterModel reciter,
    required MoshafModel moshaf,
    required int surahNumber,
  }) {
    return QueueItem(
      reciterId: reciter.id,
      reciterName: reciter.name,
      moshafId: moshaf.id,
      moshafServer: moshaf.server,
      surahNumber: surahNumber,
    );
  }

  String get surahArabicName => SurahData.byNumber(surahNumber).arabicName;

  String get audioUrl => ApiConstants.surahAudioUrl(moshafServer, surahNumber);

  /// مفتاح ثابت لكل (قارئ + رواية + سورة)، بنستخدمه في تتبع التحميلات.
  String get key => '${reciterId}_${moshafId}_$surahNumber';

  Map<String, dynamic> toJson() => {
        'reciterId': reciterId,
        'reciterName': reciterName,
        'moshafId': moshafId,
        'moshafServer': moshafServer,
        'surahNumber': surahNumber,
      };

  factory QueueItem.fromJson(Map<String, dynamic> json) => QueueItem(
        reciterId: json['reciterId'] as int,
        reciterName: json['reciterName'] as String,
        moshafId: json['moshafId'] as int,
        moshafServer: json['moshafServer'] as String,
        surahNumber: json['surahNumber'] as int,
      );

  /// ترميز نصي مضغوط (يُستخدم في التخزين المحلي لقوائم مثل "آخر استماع"
  /// و"السور المفضلة" و"قائمة الانتظار المحفوظة").
  static String encode(QueueItem item) =>
      '${item.reciterId}|${item.reciterName}|${item.moshafId}|${item.moshafServer}|${item.surahNumber}';

  static QueueItem decode(String raw) {
    final parts = raw.split('|');
    return QueueItem(
      reciterId: int.parse(parts[0]),
      reciterName: parts[1],
      moshafId: int.parse(parts[2]),
      moshafServer: parts[3],
      surahNumber: int.parse(parts[4]),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QueueItem &&
      other.reciterId == reciterId &&
      other.moshafId == moshafId &&
      other.surahNumber == surahNumber;

  @override
  int get hashCode => Object.hash(reciterId, moshafId, surahNumber);
}
