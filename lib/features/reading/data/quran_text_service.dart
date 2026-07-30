import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/storage/local_storage.dart';
import 'ayah_model.dart';

/// بيجيب نص السورة (بالرسم العثماني) من Al Quran Cloud API، وبيحفظه محليًا
/// أول مرة عشان المرات الجاية تفتح فورًا من غير ما تحتاج نت.
class QuranTextService {
  QuranTextService._internal();
  static final QuranTextService instance = QuranTextService._internal();

  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.alquran.cloud/v1'));
  final Map<int, List<AyahModel>> _memoryCache = {};

  String _cacheKey(int surahNumber) => 'quran_text_$surahNumber';

  Future<List<AyahModel>> getSurahText(int surahNumber) async {
    final cached = _memoryCache[surahNumber];
    if (cached != null) return cached;

    final fromDisk = _readFromDisk(surahNumber);
    if (fromDisk != null) {
      _memoryCache[surahNumber] = fromDisk;
      return fromDisk;
    }

    final response = await _dio.get('/surah/$surahNumber/quran-uthmani');
    final data = response.data['data'] as Map<String, dynamic>;
    final ayahsJson = data['ayahs'] as List;
    final ayahs = ayahsJson
        .map((e) => AyahModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    _memoryCache[surahNumber] = ayahs;
    await _writeToDisk(surahNumber, ayahs);
    return ayahs;
  }

  List<AyahModel>? _readFromDisk(int surahNumber) {
    final raw = LocalStorage.instance.getString(_cacheKey(surahNumber));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => AyahModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeToDisk(int surahNumber, List<AyahModel> ayahs) async {
    final encoded = jsonEncode(ayahs.map((a) => a.toJson()).toList());
    await LocalStorage.instance.setString(_cacheKey(surahNumber), encoded);
  }
}
