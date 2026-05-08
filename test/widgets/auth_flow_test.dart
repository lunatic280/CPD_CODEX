import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cpd_test_app/screens/login_screen.dart';
import 'package:cpd_test_app/screens/signup_screen.dart';

void main() {
  testWidgets('로그인 화면에서 입력 검증 메시지를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onSignIn: (_, __) async {},
          onMoveToSignUp: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    expect(find.text('이메일을 입력하세요.'), findsOneWidget);
    expect(find.text('비밀번호를 입력하세요.'), findsOneWidget);
  });

  testWidgets('회원가입 화면에서 비밀번호 확인 불일치를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SignUpScreen(
          onSignUp: (_, __, ___) async {},
          onMoveToLogin: () {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('signup_name_field')),
      '홍길동',
    );
    await tester.enterText(
      find.byKey(const Key('signup_email_field')),
      'hong@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signup_password_field')),
      'password',
    );
    await tester.enterText(
      find.byKey(const Key('signup_confirm_password_field')),
      'password2',
    );
    await tester.tap(find.byKey(const Key('signup_submit_button')));
    await tester.pump();

    expect(find.text('비밀번호가 서로 다릅니다.'), findsOneWidget);
  });
}
