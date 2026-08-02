import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

/// أفاتار قارئ: بيحاول يعرض صورة حقيقية من `assets/reciters/{id}.jpg`
/// (لو المستخدم ضافها)، ولو مش موجودة بيرجع لأفاتار مصمم بشكل احترافي
/// (تدرج لوني مميز لكل قارئ + زخرفة نجمية خفيفة + الحرف الأول باسمه).
class ReciterAvatar extends StatelessWidget {
  final int reciterId;
  final String letter;
  final double size;
  final String? heroTag;
  final bool ring;

  const ReciterAvatar({
    super.key,
    required this.reciterId,
    required this.letter,
    this.size = 60,
    this.heroTag,
    this.ring = false,
  });

  static const List<List<Color>> _palette = [
    [Color(0xFFE8C766), Color(0xFFD4AF37)],
    [Color(0xFF2FAE85), Color(0xFF0F7A5C)],
    [Color(0xFF6C8AE4), Color(0xFF3A57B7)],
    [Color(0xFFCB7BD8), Color(0xFF8A4BA3)],
    [Color(0xFFE49A6C), Color(0xFFB85C38)],
    [Color(0xFF5FC2C9), Color(0xFF2A8C93)],
  ];

  List<Color> get _gradient => _palette[reciterId % _palette.length];

  @override
  Widget build(BuildContext context) {
    final content = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/reciters/$reciterId.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _GeneratedAvatar(
            letter: letter,
            gradient: _gradient,
            size: size,
          ),
        ),
      ),
    );

    final decorated = Container(
      width: size,
      height: size,
      decoration: ring
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _gradient.last.withValues(alpha: 0.35),
                  blurRadius: size * 0.35,
                  spreadRadius: size * 0.02,
                ),
              ],
              border: Border.all(
                  color: _gradient.last.withValues(alpha: 0.55), width: 2),
            )
          : null,
      padding: ring ? const EdgeInsets.all(2) : EdgeInsets.zero,
      child: content,
    );

    if (heroTag == null) return decorated;
    return Hero(
      tag: heroTag!,
      child: Material(color: Colors.transparent, child: decorated),
    );
  }
}

class _GeneratedAvatar extends StatelessWidget {
  final String letter;
  final List<Color> gradient;
  final double size;

  const _GeneratedAvatar({
    required this.letter,
    required this.gradient,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _StarPainter(Colors.white.withValues(alpha: 0.22)),
          ),
          Text(
            letter.isNotEmpty ? letter : '؟',
            style: AppTypography.quranic(Brightness.dark).copyWith(
              color: Colors.black.withValues(alpha: 0.78),
              fontSize: size * 0.42,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// زخرفة نجمة ثمانية خفيفة خلف الحرف، بتدي إحساس إسلامي هندسي راقي.
class _StarPainter extends CustomPainter {
  final Color color;
  const _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 * 0.82;
    final innerR = outerR * 0.55;
    final path = Path();

    for (int i = 0; i < 16; i++) {
      final angle = (math.pi / 8) * i - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.color != color;
}
