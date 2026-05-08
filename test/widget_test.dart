import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cpd_test_app/data/auth_repository.dart';
import 'package:cpd_test_app/main.dart';
import 'package:cpd_test_app/models/app_user.dart';

void main() {
  testWidgets('세션이 없으면 로그인 화면을 보여준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(authRepository: _FakeAuthRepository()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_password_field')), findsOneWidget);
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
  });
}

class _FakeAuthRepository extends AuthRepository {
  @override
  Future<AppUser?> currentUser() async {
    return null;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String displayName,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }
}
