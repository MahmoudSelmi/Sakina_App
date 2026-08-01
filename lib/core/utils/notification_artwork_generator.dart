import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// بيولّد صورة PNG لكل قارئ (تدرج لوني + الحرف الأول) بنفس تصميم
/// [ReciterAvatar]، عشان تستخدم كصورة غلاف في إشعار التشغيل وشاشة القفل -
/// بدل ما كل القراء يظهروا بنفس أيقونة التطبيق العامة.
class NotificationArtworkGenerator {
  NotificationArtworkGenerator._();

  static const List<List<Color>> _palette = [
    [Color(0xFFE8C766), Color(0xFFD4AF37)],
    [Color(0xFF2FAE85), Color(0xFF0F7A5C)],
    [Color(0xFF6C8AE4), Color(0xFF3A57B7)],
    [Color(0xFFCB7BD8), Color(0xFF8A4BA3)],
    [Color(0xFFE49A6C), Color(0xFFB85C38)],
    [Color(0xFF5FC2C9), Color(0xFF2A8C93)],
  ];

  static final Map<int, Uri> _cache = {};

  static Future<Uri?> generate({required int reciterId, required String letter}) async {
    if (_cache.containsKey(reciterId)) return _cache[reciterId];

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/notif_art_$reciterId.png');

      if (await file.exists()) {
        final uri = Uri.file(file.path);
        _cache[reciterId] = uri;
        return uri;
      }

      const size = 400.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final gradient = _palette[reciterId % _palette.length];
      const center = Offset(size / 2, size / 2);

      final paint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(size, size),
          gradient,
        );
      canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), paint);

      final textSpan = TextSpan(
        text: letter.isNotEmpty ? letter : '؟',
        style: TextStyle(
          color: Colors.black.withOpacity(0.78),
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.rtl);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await file.writeAsBytes(bytes);

      final uri = Uri.file(file.path);
      _cache[reciterId] = uri;
      return uri;
    } catch (_) {
      return null;
    }
  }
}
