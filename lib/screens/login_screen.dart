import 'package:flutter/material.dart';

import '../widgets/auth_text_field.dart';

typedef SignInCallback = Future<void> Function(String email, String password);

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onSignIn,
    required this.onMoveToSignUp,
  });

  final SignInCallback onSignIn;
  final VoidCallback onMoveToSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSignIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const _LoginHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 45, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _ClivLogo(),
                      const SizedBox(height: 38),
                      _LoginInputField(
                        fieldKey: const Key('login_email_field'),
                        controller: _emailController,
                        hintText: '아이디',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 6),
                      _LoginInputField(
                        fieldKey: const Key('login_password_field'),
                        controller: _passwordController,
                        hintText: '비밀번호',
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: validatePassword,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '비밀번호 표시',
                                  style: TextStyle(
                                    color: Color(0xFF7D7D7D),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _OptionDot(isSelected: _isPasswordVisible),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            '로그인 유지',
                            style: TextStyle(
                              color: Color(0xFF7D7D7D),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const _OptionDot(),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        _AuthErrorText(
                          key: const Key('login_error_text'),
                          message: _errorMessage!,
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 42,
                        child: FilledButton(
                          key: const Key('login_submit_button'),
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0000D6),
                            disabledBackgroundColor:
                                const Color(0xFF0000D6).withValues(alpha: 0.45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            _isSubmitting ? '로그인 중...' : '로그인',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _TextLink(label: '아이디 찾기'),
                          const _LinkDivider(label: '/'),
                          const _TextLink(label: '비밀번호 찾기'),
                          const _LinkDivider(label: '/'),
                          TextButton(
                            key: const Key('move_to_signup_button'),
                            onPressed:
                                _isSubmitting ? null : widget.onMoveToSignUp,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF7D7D7D),
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 4,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '회원가입',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 23),
                      const Text(
                        '간편로그인',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF7D7D7D),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 19),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 298),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _SocialButton(label: 'N'),
                              _SocialButton(label: 'TALK'),
                              _SocialButton(label: 'G'),
                              _SocialButton(label: 'f'),
                              _SocialButton(
                                label: 'Apple',
                                icon: Icons.apple,
                                useIcon: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8E8E8)),
        ),
      ),
      child: SizedBox(
        height: 69,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF333333),
              ),
              const SizedBox(width: 26),
              const Text(
                '로그인',
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '더보기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClivLogo extends StatelessWidget {
  const _ClivLogo();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Cliv',
        style: TextStyle(
          color: Color(0xFF0000D6),
          fontSize: 56,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _LoginInputField extends StatelessWidget {
  const _LoginInputField({
    required this.fieldKey,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String hintText;
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
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
        color: Color(0xFF333333),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFD9D9D9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        constraints: const BoxConstraints(minHeight: 34),
        border: _fieldBorder(),
        enabledBorder: _fieldBorder(),
        focusedBorder: _fieldBorder(color: const Color(0xFF0000D6), width: 1.5),
        errorBorder: _fieldBorder(color: const Color(0xFFD60000), width: 1.2),
        focusedErrorBorder:
            _fieldBorder(color: const Color(0xFFD60000), width: 1.5),
      ),
    );
  }

  OutlineInputBorder _fieldBorder({
    Color color = Colors.transparent,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _OptionDot extends StatelessWidget {
  const _OptionDot({this.isSelected = false});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0000D6) : const Color(0xFFD9D9D9),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF7D7D7D),
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _LinkDivider extends StatelessWidget {
  const _LinkDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF7D7D7D),
        fontSize: 14,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    this.icon,
    this.useIcon = false,
  });

  final String label;
  final IconData? icon;
  final bool useIcon;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _backgroundColor(label);
    return Container(
      width: 49,
      height: 49,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border:
            label == 'G' ? Border.all(color: const Color(0xFFE6E6E6)) : null,
      ),
      child: Center(
        child: useIcon
            ? Icon(icon, size: 27, color: Colors.white)
            : Text(
                label,
                style: TextStyle(
                  color: _labelColor(label),
                  fontSize: label.length > 1 ? 10 : 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Color _backgroundColor(String label) {
    switch (label) {
      case 'N':
        return const Color(0xFF03C75A);
      case 'TALK':
        return const Color(0xFFFEE500);
      case 'f':
        return const Color(0xFF1877F2);
      case 'Apple':
        return const Color(0xFF111111);
      default:
        return Colors.white;
    }
  }

  Color _labelColor(String label) {
    switch (label) {
      case 'N':
      case 'f':
        return Colors.white;
      case 'TALK':
        return const Color(0xFF3A2A00);
      case 'G':
        return const Color(0xFF4285F4);
      default:
        return const Color(0xFF333333);
    }
  }
}

class _AuthErrorText extends StatelessWidget {
  const _AuthErrorText({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFD60000),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
