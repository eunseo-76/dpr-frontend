import 'package:flutter/material.dart';

OverlayEntry? _currentToast;

void showToast(BuildContext context, String message, {bool isError = true}) {
  _currentToast?.remove();
  _currentToast = null;

  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _ToastWidget(
      message: message,
      isError: isError,
      onDismiss: () {
        entry.remove();
        if (_currentToast == entry) _currentToast = null;
      },
    ),
  );

  _currentToast = entry;
  overlay.insert(entry);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();
    Future.delayed(const Duration(seconds: 3), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isError ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: TextStyle(
                  color: widget.isError ? Colors.red[700] : Colors.green[700],
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}