import 'package:flutter/material.dart';

import '../widgets/auth_text_field.dart';

typedef SignUpCallback = Future<void> Function(
  String email,
  String displayName,
  String password,
);

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.onSignUp,
    required this.onMoveToLogin,
  });

  final SignUpCallback onSignUp;
  final VoidCallback onMoveToLogin;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      await widget.onSignUp(
        _emailController.text.trim(),
        _nameController.text.trim(),
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

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return '비밀번호 확인을 입력하세요.';
    }
    if (value != _passwordController.text) {
      return '비밀번호가 서로 다릅니다.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.person_add_alt_outlined,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '새 계정 만들기',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '이름과 이메일로 로컬 게시판 계정을 만듭니다.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 28),
                        AuthTextField(
                          fieldKey: const Key('signup_name_field'),
                          controller: _nameController,
                          labelText: '이름',
                          textInputAction: TextInputAction.next,
                          validator: validateRequiredName,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          fieldKey: const Key('signup_email_field'),
                          controller: _emailController,
                          labelText: '이메일',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: validateEmail,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          fieldKey: const Key('signup_password_field'),
                          controller: _passwordController,
                          labelText: '비밀번호',
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          validator: validatePassword,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          fieldKey: const Key('signup_confirm_password_field'),
                          controller: _confirmPasswordController,
                          labelText: '비밀번호 확인',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: _validateConfirmPassword,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _SignupErrorText(
                            key: const Key('signup_error_text'),
                            message: _errorMessage!,
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton(
                          key: const Key('signup_submit_button'),
                          onPressed: _isSubmitting ? null : _submit,
                          child: Text(_isSubmitting ? '가입 중...' : '회원가입'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          key: const Key('move_to_login_button'),
                          onPressed:
                              _isSubmitting ? null : widget.onMoveToLogin,
                          child: const Text('로그인 화면으로 이동'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupErrorText extends StatelessWidget {
  const _SignupErrorText({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.onErrorContainer),
      ),
    );
  }
}
