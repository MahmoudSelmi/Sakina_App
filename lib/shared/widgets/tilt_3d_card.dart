import 'dart:math' as math;
import 'package:flutter/material.dart';

/// بيدّي إحساس "3D" حقيقي لأي حاجة تحطها جواه - وانت لامس وبتسحب بإصبعك،
/// الكارت بيتميل بمنظور حقيقي (perspective) زي كارت فعليًا حامله في إيدك،
/// وبيرجع يستوي برفق لما تسيبه.
class Tilt3DCard extends StatefulWidget {
  final Widget child;
  final double maxTiltDegrees;

  const Tilt3DCard({super.key, required this.child, this.maxTiltDegrees = 12});

  @override
  State<Tilt3DCard> createState() => _Tilt3DCardState();
}

class _Tilt3DCardState extends State<Tilt3DCard> with SingleTickerProviderStateMixin {
  late final AnimationController _springBack;
  Offset _dragOffset = Offset.zero;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _springBack = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _springBack.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(_dragOffset, Offset.zero, 0.18) ?? Offset.zero;
      });
    });
  }

  @override
  void dispose() {
    _springBack.dispose();
    super.dispose();
  }

  void _updateTilt(Offset localPosition) {
    if (_size == Size.zero) return;
    final dx = (localPosition.dx / _size.width - 0.5) * 2;
    final dy = (localPosition.dy / _size.height - 0.5) * 2;
    setState(() => _dragOffset = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0)));
  }

  void _reset() {
    _springBack
      ..reset()
      ..repeat()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _springBack.stop();
      });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _dragOffset = Offset.zero);
        _springBack.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxTilt = widget.maxTiltDegrees * (math.pi / 180);
    final rotY = _dragOffset.dx * maxTilt;
    final rotX = -_dragOffset.dy * maxTilt;

    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanUpdate: (details) => _updateTilt(details.localPosition),
          onPanEnd: (_) => _reset(),
          onPanCancel: _reset,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 120),
            tween: Tween(begin: 0, end: 1),
            builder: (context, _, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018) // منظور حقيقي (perspective)
                  ..rotateX(rotX)
                  ..rotateY(rotY)
                  ..scale(1 + (_dragOffset.distance.abs() * 0.02)),
                child: child,
              );
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}
