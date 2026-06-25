import 'package:flutter/material.dart';

class PopEffect extends StatefulWidget {
  final bool trigger;
  final Widget child;
  final double peakScale;
  final Duration duration;
  final bool animateOnDeactivate;

  const PopEffect({
    super.key,
    required this.trigger,
    required this.child,
    this.peakScale = 1.30,
    this.duration = const Duration(milliseconds: 800),
    this.animateOnDeactivate = false,
  });

  @override
  State<PopEffect> createState() => _PopEffectState();
}

class _PopEffectState extends State<PopEffect>
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
        tween: Tween(begin: 1.0, end: widget.peakScale),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.peakScale, end: 0.97),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.97, end: 1.0),
        weight: 35,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(PopEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activated = widget.trigger && !oldWidget.trigger;
    final deactivated = !widget.trigger && oldWidget.trigger;
    if (activated || (deactivated && widget.animateOnDeactivate)) {
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
