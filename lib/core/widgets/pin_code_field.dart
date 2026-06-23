import 'package:flutter/material.dart';
// 초대코드, 비밀번호 재설정 시 사용되는 네모칸
class PinCodeField extends StatefulWidget {
  final int length;
  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  const PinCodeField({
    super.key,
    this.length = 6,
    required this.controller,
    this.autofocus = true,
    this.onSubmitted,
  });

  @override
  State<PinCodeField> createState() => _PinCodeFieldState();
}

class _PinCodeFieldState extends State<PinCodeField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text.toUpperCase();

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (i) {
              final hasChar = i < code.length;
              final isCursor = i == code.length && _focusNode.hasFocus;
              return Container(
                width: 48,
                height: 56,
                decoration: BoxDecoration(
                  color: hasChar ? Colors.grey[100] : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCursor ? Colors.black87 : Colors.grey[300]!,
                    width: isCursor ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  hasChar ? code[i] : '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              );
            }),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                maxLength: widget.length,
                textCapitalization: TextCapitalization.characters,
                autofocus: widget.autofocus,
                decoration: const InputDecoration(counterText: ''),
                onSubmitted: widget.onSubmitted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}