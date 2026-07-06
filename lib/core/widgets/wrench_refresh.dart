import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/widgets/loading_indicator.dart';

// 아래로 당기면 wrench가 위에서 내려오고, 놓으면 새로고침
// TODO: 새로고침 할 때 어색한 거 나중에 수정... 일단 굴러는 간다
class WrenchRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const WrenchRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  State<WrenchRefresh> createState() => _WrenchRefreshState();
}

class _WrenchRefreshState extends State<WrenchRefresh> {
  double _dragOffset = 0;
  bool _atTop = true;
  bool _triggered = false;
  static const _maxDrag = 120.0;
  static const _threshold = 80.0;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      _atTop = notification.metrics.pixels <= 0;
    }
    return false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_triggered) return;

    if (_dragOffset > 0) {
      setState(() {
        _dragOffset = (_dragOffset + event.delta.dy).clamp(0, _maxDrag);
      });
    } else if (_atTop && event.delta.dy > 0) {
      setState(() {
        _dragOffset = event.delta.dy.clamp(0, _maxDrag);
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_dragOffset <= 0) return;

    if (_dragOffset >= _threshold) {
      _triggered = true;
      setState(() => _dragOffset = 0);
      widget.onRefresh().then((_) {
        if (mounted) _triggered = false;
      });
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: _dragOffset > 0 ? 0 : 200),
              height: _dragOffset,
              child: _dragOffset > 10
                  ? Center(
                      child: LoadingIndicator(
                        size: (_dragOffset * 0.7).clamp(20, 80),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: IgnorePointer(
                ignoring: _dragOffset > 0,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
