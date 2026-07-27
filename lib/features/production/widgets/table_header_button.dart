import 'package:flutter/material.dart';

// [공정별 실적 합계]/[업체별 실적 합계] 표의 '공정'/'업체' 헤더 셀 안에 들어가는
// 작은 버튼. 헤더 셀 테두리는 표 격자선이 그대로 그려주고, 이 위젯은 그 안쪽에
// 여백을 두고 앉는 별도의 버튼처럼 보이도록 자체 배경/테두리를 가진다.
class TableHeaderButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const TableHeaderButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  // 상단 필터바의 SegmentedToggle(segmented_toggle.dart)의 '선택됨' 상태와
  // 같은 파란색 pill 스타일로 맞춘다.
  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.blue;
    return Center(
      child: Material(
        color: activeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: activeColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
