class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://www.mp3quran.net/api/v3';
  static const String reciters = '$baseUrl/reciters';
  static const String suwar = '$baseUrl/suwar';

  static String surahAudioUrl(String server, int surahNumber) {
    final padded = surahNumber.toString().padLeft(3, '0');
    final normalizedServer = server.endsWith('/') ? server : '$server/';
    return '$normalizedServer$padded.mp3';
  }
}
