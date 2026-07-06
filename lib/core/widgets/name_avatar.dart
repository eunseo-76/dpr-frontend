import 'package:flutter/material.dart';

class NameAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double fontSize;

  static const _colors = [
    Color(0xFF4CCD6C),
    Color(0xFF6C6ADB),
    Color(0xFFFFCF0E),
    Color(0xFF007AFF),
    Color(0xFF222222),
  ];

  const NameAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0] : '?';
    // 문자열 해시값으로 색상 정하기
    final color = _colors[name.hashCode.abs() % _colors.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}