/// أدوات مساعدة لتطبيع النص العربي عشان البحث يشتغل صح
/// حتى لو المستخدم كتب بتشكيل مختلف أو همزات مختلفة أو مسافات زيادة.
class ArabicText {
  ArabicText._();

  static final RegExp _tashkeel = RegExp(
    r'[\u064B-\u065F\u0670\u06D6-\u06ED]',
  );

  /// بيوحّد الحروف المتشابهة، ويشيل التشكيل والتطويل والمسافات الزيادة
  /// عشان "أحمد" و"احمد" و"اَحمَد" كلهم يتطابقوا في البحث.
  static String normalize(String input) {
    var text = input.trim().toLowerCase();
    text = text.replaceAll(_tashkeel, '');
    text = text.replaceAll('ـ', ''); // تطويل
    text = text.replaceAll(RegExp(r'[إأآا]'), 'ا');
    text = text.replaceAll('ى', 'ي');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll('ؤ', 'و');
    text = text.replaceAll('ئ', 'ي');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text;
  }

  static bool contains(String source, String query) {
    if (query.isEmpty) return true;
    return normalize(source).contains(normalize(query));
  }
}
