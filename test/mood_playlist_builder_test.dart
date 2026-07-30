import 'package:flutter_test/flutter_test.dart';
import 'package:quran_premium/core/utils/mood_playlist_builder.dart';
import 'package:quran_premium/features/reciters/data/models/moshaf_model.dart';
import 'package:quran_premium/features/reciters/data/models/reciter_model.dart';

ReciterModel _reciter({
  required int id,
  required String name,
  required List<MoshafModel> moshaf,
}) {
  return ReciterModel(id: id, name: name, letter: name.substring(0, 1), moshaf: moshaf);
}

MoshafModel _moshaf({
  required int id,
  required String name,
  required List<int> surahList,
}) {
  return MoshafModel(
    id: id,
    name: name,
    rewayaId: 1,
    server: 'https://example.com/$id/',
    surahTotal: surahList.length,
    moshafType: 0,
    surahList: surahList,
  );
}

void main() {
  group('MoodPlaylistBuilder.build', () {
    test('prefers ترتيل moshaf for sleep mode when available', () {
      final reciters = [
        _reciter(id: 1, name: 'قارئ الحدر', moshaf: [
          _moshaf(id: 10, name: 'حدر', surahList: [67, 56, 55, 36, 112, 113, 114]),
        ]),
        _reciter(id: 2, name: 'قارئ الترتيل', moshaf: [
          _moshaf(id: 20, name: 'ترتيل', surahList: [67, 56, 55, 36, 112, 113, 114]),
        ]),
      ];

      final queue = MoodPlaylistBuilder.build(Mood.sleep, reciters);

      expect(queue, isNotEmpty);
      for (final item in queue) {
        expect(item.reciterId, 2, reason: 'should prefer the ترتيل reciter for sleep mode');
      }
    });

    test('falls back to any available moshaf when no preferred keyword matches', () {
      final reciters = [
        _reciter(id: 5, name: 'قارئ حدر فقط', moshaf: [
          _moshaf(id: 50, name: 'حدر', surahList: [67]),
        ]),
      ];

      final queue = MoodPlaylistBuilder.build(Mood.sleep, reciters);

      expect(queue.any((q) => q.surahNumber == 67 && q.reciterId == 5), isTrue);
    });

    test('skips surahs with no available recording at all', () {
      final reciters = [
        _reciter(id: 7, name: 'قارئ محدود', moshaf: [
          _moshaf(id: 70, name: 'ترتيل', surahList: [67]),
        ]),
      ];

      final queue = MoodPlaylistBuilder.build(Mood.sleep, reciters);

      expect(queue.length, 1);
      expect(queue.first.surahNumber, 67);
    });

    test('gym mode prefers حدر (faster) recitation style', () {
      final reciters = [
        _reciter(id: 1, name: 'قارئ الترتيل', moshaf: [
          _moshaf(id: 10, name: 'ترتيل', surahList: [61, 47, 8, 33]),
        ]),
        _reciter(id: 2, name: 'قارئ الحدر', moshaf: [
          _moshaf(id: 20, name: 'حدر', surahList: [61, 47, 8, 33]),
        ]),
      ];

      final queue = MoodPlaylistBuilder.build(Mood.gym, reciters);

      expect(queue, isNotEmpty);
      for (final item in queue) {
        expect(item.reciterId, 2);
      }
    });

    test('returns an empty list when no reciters have any of the mood surahs', () {
      final reciters = [
        _reciter(id: 1, name: 'قارئ', moshaf: [
          _moshaf(id: 10, name: 'ترتيل', surahList: [1, 2, 3]),
        ]),
      ];

      final queue = MoodPlaylistBuilder.build(Mood.sleep, reciters);

      expect(queue, isEmpty);
    });
  });
}
