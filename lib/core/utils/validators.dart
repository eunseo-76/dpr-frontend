import 'package:flutter/services.dart';

class PositiveDecimalFormatter extends TextInputFormatter {
  static final _pattern = RegExp(r'^\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty || _pattern.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

class Validators {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$',
  );

  static String? validateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '이메일을 입력해주세요';
    if (!_emailRegex.hasMatch(trimmed)) return '올바른 이메일 형식이 아닙니다';
    return null;
  }

  static String? validatePassword(String value) {
    if (value.isEmpty) return '비밀번호를 입력해주세요';
    if (!_passwordRegex.hasMatch(value)) {
      return '영문, 숫자, 특수문자(@\$!%*#?&)를 포함하여 8자 이상';
    }
    return null;
  }
}
