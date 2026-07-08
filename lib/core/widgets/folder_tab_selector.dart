import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/widgets/wobble_effect.dart';

// 탭 = 카드 선택 인덱스. 선택된 탭이 아래 카드와 이음새 없이 붙어 보이도록
// 탭 위치(첫 번째/마지막/중간)에 따라 카드 상단 모서리 라운딩을 지운다.
class FolderTabSelector extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget child;
  final EdgeInsetsGeometry contentPadding;

  const FolderTabSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
    this.contentPadding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: labels.asMap().entries.map((entry) {
            final isSelected = entry.key == selectedIndex;
            final isLast = entry.key == labels.length - 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 2),
                child: GestureDetector(
                  onTap: () => onSelected(entry.key),
                  child: WobbleEffect(
                    trigger: isSelected,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.blue : Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: selectedIndex == 0
                  ? Radius.zero
                  : const Radius.circular(12),
              topRight: selectedIndex == labels.length - 1
                  ? Radius.zero
                  : const Radius.circular(12),
              bottomLeft: const Radius.circular(12),
              bottomRight: const Radius.circular(12),
            ),
          ),
          padding: contentPadding,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: child,
          ),
        ),
      ],
    );
  }
}
