import 'package:flutter/material.dart';

// 폴더 탭 접혔다 펼쳐지는 애니메이션
class WobbleEffect extends StatefulWidget {
  final bool trigger;
  final Widget child;
  final Duration duration;

  const WobbleEffect({
    super.key,
    required this.trigger,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<WobbleEffect> createState() => _WobbleEffectState();
}

class _WobbleEffectState extends State<WobbleEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.4),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.1),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 0.95),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(WobbleEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform(
        transform: Matrix4.diagonal3Values(1.0, _scaleAnimation.value, 1.0),
        alignment: Alignment.bottomCenter,
        child: child,
      ),
      child: widget.child,
    );
  }
}
