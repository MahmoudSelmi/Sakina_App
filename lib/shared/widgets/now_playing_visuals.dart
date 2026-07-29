import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'reciter_avatar.dart';

/// غلاف صورة القارئ وقت التشغيل: بيدّي إحساس "حي" ومتحرك بدل الصورة
/// الثابتة، على غرار شاشة "Now Playing" في اسبوتيفاي (هالة متوهجة دايرة
/// بتلف ببطء + نبضة تنفّس خفيفة للصورة نفسها). الحركة بتشتغل وقت
/// التشغيل بس وبتتجمد بلطف لما يتوقف الصوت.
class NowPlayingArt extends StatefulWidget {
  final int reciterId;
  final String letter;
  final double size;
  final bool isPlaying;
  final String? heroTag;

  const NowPlayingArt({
    super.key,
    required this.reciterId,
    required this.letter,
    required this.size,
    required this.isPlaying,
    this.heroTag,
  });

  @override
  State<NowPlayingArt> createState() => _NowPlayingArtState();
}

class _NowPlayingArtState extends State<NowPlayingArt>
    with TickerProviderStateMixin {
  late final AnimationController _rotation;
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _syncWithPlayback();
  }

  @override
  void didUpdateWidget(covariant NowPlayingArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) _syncWithPlayback();
  }

  void _syncWithPlayback() {
    if (widget.isPlaying) {
      _rotation.repeat();
      _breathe.repeat(reverse: true);
    } else {
      _rotation.stop();
      _breathe.animateTo(0, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    _breathe.dispose();
    super.dispose();
  }

  static const _haloColors = [
    Color(0xFFD4AF37),
    Color(0xFF2FAE85),
    Color(0xFF6C8AE4),
    Color(0xFFD4AF37),
  ];

  @override
  Widget build(BuildContext context) {
    final haloSize = widget.size * 1.18;

    return SizedBox(
      width: haloSize,
      height: haloSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _rotation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotation.value * 2 * math.pi,
                child: child,
              );
            },
            child: Container(
              width: haloSize,
              height: haloSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: _haloColors,
                  transform: GradientRotation(-math.pi / 2),
                ),
              ),
              child: Center(
                child: Container(
                  width: haloSize - 10,
                  height: haloSize - 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _breathe,
            builder: (context, child) {
              final scale = 1.0 + (_breathe.value * 0.035);
              return Transform.scale(scale: scale, child: child);
            },
            child: ReciterAvatar(
              reciterId: widget.reciterId,
              letter: widget.letter,
              size: widget.size,
              heroTag: widget.heroTag,
            ),
          ),
        ],
      ),
    );
  }
}

/// شرطات "إيكولايزر" صغيرة بترقص وقت التشغيل، بتدي إحساس إن في صوت
/// شغال فعلًا بدل ما الواجهة تبقى ساكنة.
class EqualizerBars extends StatefulWidget {
  final bool isPlaying;
  final double height;
  final Color color;

  const EqualizerBars({
    super.key,
    required this.isPlaying,
    this.height = 14,
    this.color = Colors.white,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _bars;

  @override
  void initState() {
    super.initState();
    _bars = List.generate(3, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 480 + i * 130),
      );
      return controller;
    });
    _syncWithPlayback();
  }

  @override
  void didUpdateWidget(covariant EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) _syncWithPlayback();
  }

  void _syncWithPlayback() {
    for (final c in _bars) {
      if (widget.isPlaying) {
        c.repeat(reverse: true);
      } else {
        c.animateTo(0, duration: const Duration(milliseconds: 300));
      }
    }
  }

  @override
  void dispose() {
    for (final c in _bars) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.height * 1.1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _bars.map((c) {
          return AnimatedBuilder(
            animation: c,
            builder: (context, _) {
              final h = widget.height * (0.28 + c.value * 0.72);
              return Container(
                width: widget.height * 0.16,
                height: h,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
