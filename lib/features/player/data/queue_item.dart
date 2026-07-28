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

  @override
  bool operator ==(Object other) =>
      other is QueueItem &&
      other.reciterId == reciterId &&
      other.moshafId == moshafId &&
      other.surahNumber == surahNumber;

  @override
  int get hashCode => Object.hash(reciterId, moshafId, surahNumber);
}
