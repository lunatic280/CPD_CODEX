import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(_iconForLabel(labelText)),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  IconData _iconForLabel(String label) {
    if (label.contains('이메일')) {
      return Icons.mail_outline;
    }
    if (label.contains('비밀번호')) {
      return Icons.lock_outline;
    }
    return Icons.person_outline;
  }
}

String? validateRequiredName(String? value) {
  if ((value ?? '').trim().isEmpty) {
    return '이름을 입력하세요.';
  }
  return null;
}

String? validateEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) {
    return '이메일을 입력하세요.';
  }
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailPattern.hasMatch(email)) {
    return '올바른 이메일 형식을 입력하세요.';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return '비밀번호를 입력하세요.';
  }
  if (password.length < 6) {
    return '비밀번호는 6자 이상이어야 합니다.';
  }
  return null;
}

String authErrorMessage(Object error) {
  try {
    final dynamic dynamicError = error;
    final message = dynamicError.message;
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
  } catch (_) {
    // message 필드가 없는 예외는 기본 문구를 사용한다.
  }
  return '요청을 처리하지 못했습니다.';
}
