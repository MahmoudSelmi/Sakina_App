import 'package:flutter/material.dart';

/// بيلف أي widget بحركة ظهور تدريجية (fade + slide) بتتأخر حسب [index]
/// عشان يديلنا إحساس إن العناصر بتدخل الشاشة واحدة ورا التانية.
class StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration stepDelay;
  final Duration duration;
  final Axis direction;

  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.stepDelay = const Duration(milliseconds: 45),
    this.duration = const Duration(milliseconds: 420),
    this.direction = Axis.vertical,
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final beginOffset = widget.direction == Axis.vertical
        ? const Offset(0, 0.10)
        : const Offset(0.10, 0);
    _slide = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(_fade);

    final delayMs = widget.stepDelay.inMilliseconds * widget.index.clamp(0, 14);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
