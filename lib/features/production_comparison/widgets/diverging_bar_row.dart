import 'package:flutter/material.dart';
import 'package:fprs_frontend/features/production_comparison/utils/comparison_diff.dart';

class DivergingBarRow extends StatelessWidget {
  final String processName;
  final ComparisonDiff diff;

  const DivergingBarRow({super.key, required this.processName, required this.diff});

  static const _cap = 100.0;
  static const _upColor = Color(0xFF0CA30C);
  static const _downColor = Color(0xFFD03B3B);

  static const _nameWidth = 56.0;
  static const _gap = 8.0;
  static const _pctWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth - _nameWidth - _gap * 2 - _pctWidth;
          final centerX = _nameWidth + _gap + trackWidth / 2;

          return Stack(
            children: [
              if (diff.direction != ComparisonDirection.unavailable)
                Positioned(
                  left: centerX,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 1, color: Colors.grey[300]),
                ),
              Row(
                children: [
                  SizedBox(
                    width: _nameWidth,
                    child: Text(
                      processName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: _gap),
                  Expanded(child: _buildTrack()),
                  const SizedBox(width: _gap),
                  SizedBox(
                    width: _pctWidth,
                    child: Text(
                      diff.label,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _labelColor),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Color? get _labelColor => switch (diff.direction) {
    ComparisonDirection.up => _upColor,
    ComparisonDirection.down => _downColor,
    _ => null,
  };

  Widget _buildTrack() {
    if (diff.direction == ComparisonDirection.unavailable) {
      return Center(
        child: Text('데이터 없음', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      );
    }

    final ratio = (diff.percent ?? 0).abs().clamp(0, _cap) / _cap;
    final isUp = diff.direction == ComparisonDirection.up;

    return SizedBox(
      height: 14,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: isUp ? 0 : ratio,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: _downColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: isUp ? ratio : 0,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: _upColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
