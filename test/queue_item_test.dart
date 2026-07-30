import 'package:flutter_test/flutter_test.dart';
import 'package:quran_premium/features/player/data/queue_item.dart';

void main() {
  group('QueueItem encode/decode', () {
    const item = QueueItem(
      reciterId: 12,
      reciterName: 'مشاري راشد العفاسي',
      moshafId: 34,
      moshafServer: 'https://server.example.com/quran/',
      surahNumber: 67,
    );

    test('decode(encode(item)) returns an equivalent item', () {
      final encoded = QueueItem.encode(item);
      final decoded = QueueItem.decode(encoded);

      expect(decoded, equals(item));
      expect(decoded.reciterName, item.reciterName);
      expect(decoded.surahNumber, item.surahNumber);
    });

    test('key is stable and unique per reciter+moshaf+surah', () {
      final other = QueueItem(
        reciterId: item.reciterId,
        reciterName: item.reciterName,
        moshafId: item.moshafId,
        moshafServer: item.moshafServer,
        surahNumber: 68,
      );
      expect(item.key, isNot(equals(other.key)));
    });

    test('surahArabicName resolves a real surah name', () {
      expect(item.surahArabicName, 'الملك');
    });

    test('equality is based on reciter+moshaf+surah, not reciterName', () {
      final renamed = QueueItem(
        reciterId: item.reciterId,
        reciterName: 'اسم مختلف',
        moshafId: item.moshafId,
        moshafServer: item.moshafServer,
        surahNumber: item.surahNumber,
      );
      expect(renamed, equals(item));
    });
  });
}
