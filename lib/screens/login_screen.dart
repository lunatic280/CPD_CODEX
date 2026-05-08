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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
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
                          Icons.school_outlined,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '게시판 앱에 로그인',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '학습용 게시판에 접속해 글을 확인하고 작성하세요.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 28),
                        AuthTextField(
                          fieldKey: const Key('login_email_field'),
                          controller: _emailController,
                          labelText: '이메일',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: validateEmail,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          fieldKey: const Key('login_password_field'),
                          controller: _passwordController,
                          labelText: '비밀번호',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: validatePassword,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _AuthErrorText(
                            key: const Key('login_error_text'),
                            message: _errorMessage!,
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton(
                          key: const Key('login_submit_button'),
                          onPressed: _isSubmitting ? null : _submit,
                          child: Text(_isSubmitting ? '로그인 중...' : '로그인'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          key: const Key('move_to_signup_button'),
                          onPressed:
                              _isSubmitting ? null : widget.onMoveToSignUp,
                          child: const Text('회원가입'),
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

class _AuthErrorText extends StatelessWidget {
  const _AuthErrorText({
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
