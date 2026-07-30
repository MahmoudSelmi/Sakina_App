import 'package:flutter_test/flutter_test.dart';
import 'package:quran_premium/core/utils/arabic_text.dart';

void main() {
  group('ArabicText.normalize', () {
    test('removes tashkeel (diacritics)', () {
      expect(ArabicText.normalize('اَحْمَد'), ArabicText.normalize('احمد'));
    });

    test('unifies different alef forms', () {
      expect(ArabicText.normalize('إبراهيم'), ArabicText.normalize('ابراهيم'));
      expect(ArabicText.normalize('أحمد'), ArabicText.normalize('احمد'));
      expect(ArabicText.normalize('آدم'), ArabicText.normalize('ادم'));
    });

    test('unifies taa marbuta and yaa/alef maqsura', () {
      expect(ArabicText.normalize('فاطمة'), ArabicText.normalize('فاطمه'));
      expect(ArabicText.normalize('مصطفى'), ArabicText.normalize('مصطفي'));
    });

    test('collapses extra whitespace', () {
      expect(ArabicText.normalize('  محمد   العفاسي '), 'محمد العفاسي');
    });
  });

  group('ArabicText.contains', () {
    test('matches regardless of diacritics differences', () {
      expect(ArabicText.contains('الشيخ عبدالباسط عبدالصمد', 'عبدالباسط'), isTrue);
      expect(ArabicText.contains('مشاري راشد العفاسي', 'العفاسي'), isTrue);
    });

    test('empty query always matches', () {
      expect(ArabicText.contains('أي اسم', ''), isTrue);
    });

    test('non-matching query returns false', () {
      expect(ArabicText.contains('السديس', 'الحصري'), isFalse);
    });
  });
}
