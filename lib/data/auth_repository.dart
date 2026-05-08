import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';
import 'app_database.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<AppUser> signUp({
    required String email,
    required String displayName,
    required String password,
  }) async {
    final normalizedEmail = _validateEmail(email);
    final trimmedDisplayName = _validateDisplayName(displayName);
    _validatePassword(password);

    final db = await _database.database;
    final existingUser = await _findUserByEmail(db, normalizedEmail);
    if (existingUser != null) {
      throw const AuthException('이미 가입된 이메일입니다.');
    }

    final now = DateTime.now().toUtc();
    final salt = _createSalt();
    final userId = await db.transaction<int>((transaction) async {
      final id = await transaction.insert('users', {
        'email': normalizedEmail,
        'display_name': trimmedDisplayName,
        'password_salt': salt,
        'password_hash': _hashPassword(password, salt),
        'created_at': now.toIso8601String(),
      });
      await _saveSession(transaction, id);
      return id;
    });

    return AppUser(
      id: userId,
      email: normalizedEmail,
      displayName: trimmedDisplayName,
      createdAt: now,
    );
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _validateEmail(email);
    if (password.isEmpty) {
      throw const AuthException('비밀번호를 입력하세요.');
    }

    final db = await _database.database;
    final user = await _findUserByEmail(db, normalizedEmail);
    if (user == null) {
      throw const AuthException('이메일 또는 비밀번호가 올바르지 않습니다.');
    }

    final salt = user['password_salt'] as String;
    final passwordHash = user['password_hash'] as String;
    if (_hashPassword(password, salt) != passwordHash) {
      throw const AuthException('이메일 또는 비밀번호가 올바르지 않습니다.');
    }

    await db.transaction<void>((transaction) async {
      await _saveSession(transaction, user['id'] as int);
    });
    return AppUser.fromMap(user);
  }

  Future<void> signOut() async {
    final db = await _database.database;
    await db.delete('auth_session');
  }

  Future<AppUser?> currentUser() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT users.id, users.email, users.display_name, users.created_at
      FROM auth_session
      INNER JOIN users ON users.id = auth_session.user_id
      WHERE auth_session.id = 1
      LIMIT 1
    ''');

    if (rows.isEmpty) {
      return null;
    }
    return AppUser.fromMap(rows.first);
  }

  String _validateEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw const AuthException('이메일을 입력하세요.');
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(normalizedEmail)) {
      throw const AuthException('올바른 이메일 형식이 아닙니다.');
    }
    return normalizedEmail;
  }

  String _validateDisplayName(String displayName) {
    final trimmedDisplayName = displayName.trim();
    if (trimmedDisplayName.isEmpty) {
      throw const AuthException('이름을 입력하세요.');
    }
    if (trimmedDisplayName.length < 2) {
      throw const AuthException('이름은 2자 이상 입력하세요.');
    }
    return trimmedDisplayName;
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw const AuthException('비밀번호를 입력하세요.');
    }
    if (password.length < 6) {
      throw const AuthException('비밀번호는 6자 이상 입력하세요.');
    }
  }

  Future<Map<String, Object?>?> _findUserByEmail(
    DatabaseExecutor db,
    String email,
  ) async {
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  static Future<void> _saveSession(DatabaseExecutor db, int userId) async {
    await db.delete('auth_session');
    await db.insert('auth_session', {
      'id': 1,
      'user_id': userId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  String _createSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }
}
