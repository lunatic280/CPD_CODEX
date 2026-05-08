import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cpd_test_app/data/app_database.dart';
import 'package:cpd_test_app/data/auth_repository.dart';

void main() {
  late AppDatabase database;
  late AuthRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await AppDatabase.openInMemoryForTest();
    repository = AuthRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('회원가입에 성공하면 현재 사용자 세션을 저장한다', () async {
    final user = await repository.signUp(
      email: 'Student@Example.com',
      displayName: '학생',
      password: 'password123',
    );

    final currentUser = await repository.currentUser();

    expect(user.id, greaterThan(0));
    expect(user.email, 'student@example.com');
    expect(user.displayName, '학생');
    expect(currentUser?.id, user.id);
  });

  test('이미 가입된 이메일로 다시 가입할 수 없다', () async {
    await repository.signUp(
      email: 'student@example.com',
      displayName: '학생',
      password: 'password123',
    );

    expect(
      () => repository.signUp(
        email: 'STUDENT@example.com',
        displayName: '다른학생',
        password: 'password123',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('로그인에 성공하면 현재 사용자 세션을 갱신한다', () async {
    final signedUpUser = await repository.signUp(
      email: 'student@example.com',
      displayName: '학생',
      password: 'password123',
    );
    await repository.signOut();

    final signedInUser = await repository.signIn(
      email: 'student@example.com',
      password: 'password123',
    );
    final currentUser = await repository.currentUser();

    expect(signedInUser.id, signedUpUser.id);
    expect(currentUser?.id, signedUpUser.id);
  });

  test('비밀번호가 다르면 로그인할 수 없다', () async {
    await repository.signUp(
      email: 'student@example.com',
      displayName: '학생',
      password: 'password123',
    );

    expect(
      () => repository.signIn(
        email: 'student@example.com',
        password: 'wrong-password',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('로그아웃하면 현재 사용자 세션이 비워진다', () async {
    await repository.signUp(
      email: 'student@example.com',
      displayName: '학생',
      password: 'password123',
    );

    await repository.signOut();

    expect(await repository.currentUser(), isNull);
  });
}
