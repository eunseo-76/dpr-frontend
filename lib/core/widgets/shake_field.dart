import 'package:flutter/material.dart';
// 필수 필드 미입력 시 필드 흔드는 ux
class ShakeField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final ValueChanged<String>? onSubmitted;

  const ShakeField({
    super.key,
    required this.controller,
    required this.decoration,
    this.obscureText = false,
    this.keyboardType,
    this.style,
    this.onSubmitted,
  });

  @override
  ShakeFieldState createState() => ShakeFieldState();
}

class ShakeFieldState extends State<ShakeField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _offsetAnimation;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));
  }

  void showError(String message) {
    setState(() => _errorText = message);
    _animController.forward(from: 0);
  }

  void clearError() {
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(_offsetAnimation.value, 0),
        child: child,
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        style: widget.style,
        onSubmitted: widget.onSubmitted,
        decoration: widget.decoration.copyWith(
          errorText: _errorText,
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }
}