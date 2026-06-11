import 'package:flutter/material.dart';

// 카드 = 제목 + 본문 + (선택)하단
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? footer;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 + 본문
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            child,
            // footer가 있으면 구분선 + footer 추가
            if (footer != null) ...[  //  if-spread: if 충족하면 채움
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 4),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}