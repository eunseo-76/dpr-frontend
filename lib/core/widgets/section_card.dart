import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/widgets/pop_effect.dart';

// 카드 = 제목(+편집 아이콘) + 본문 + (선택)하단
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onEditTap;
  final bool wrapInCard;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.footer,
    this.onEditTap,
    this.wrapInCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (onEditTap != null)
              _FloatingEditButton(onTap: onEditTap!),
          ],
        ),
        const SizedBox(height: 16),
        child,
        if (footer != null) ...[
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          const SizedBox(height: 4),
          footer!,
        ],
      ],
    );

    if (!wrapInCard) return content;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: content,
      ),
    );
  }
}

class _FloatingEditButton extends StatefulWidget {
  final VoidCallback onTap;

  const _FloatingEditButton({required this.onTap});

  @override
  State<_FloatingEditButton> createState() => _FloatingEditButtonState();
}

class _FloatingEditButtonState extends State<_FloatingEditButton> {
  bool _tapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _tapped = !_tapped);
        widget.onTap();
      },
      child: PopEffect(
        trigger: _tapped,
        animateOnDeactivate: true,
        peakScale: 1.25,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.edit_outlined, size: 16, color: Colors.grey[700]),
        ),
      ),
    );
  }
}
