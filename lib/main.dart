import 'package:flutter/material.dart';

import 'data/auth_repository.dart';
import 'models/app_user.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

void main() {
  runApp(const BoardApp());
}

class BoardApp extends StatelessWidget {
  const BoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '게시판 앱',
      theme: _buildTheme(),
      home: const AuthGate(),
    );
  }
}

ThemeData _buildTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF315D8C),
    brightness: Brightness.light,
  );
  final textTheme = Typography.material2021().black.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    textTheme: textTheme.copyWith(
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.55),
      bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.45),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surfaceTint,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
    ),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, AuthRepository? authRepository})
      : _authRepository = authRepository;

  final AuthRepository? _authRepository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthRepository _authRepository;
  late Future<AppUser?> _currentUserFuture;
  AppUser? _currentUser;
  bool _showSignUp = false;

  @override
  void initState() {
    super.initState();
    _authRepository = widget._authRepository ?? AuthRepository();
    _currentUserFuture = _loadCurrentUser();
  }

  Future<AppUser?> _loadCurrentUser() async {
    final user = await _authRepository.currentUser();
    _currentUser = user;
    return user;
  }

  Future<void> _signIn(String email, String password) async {
    final user = await _authRepository.signIn(email: email, password: password);
    if (!mounted) {
      return;
    }
    setState(() {
      _currentUser = user;
      _showSignUp = false;
    });
  }

  Future<void> _signUp(
    String email,
    String displayName,
    String password,
  ) async {
    final user = await _authRepository.signUp(
      email: email,
      displayName: displayName,
      password: password,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _currentUser = user;
      _showSignUp = false;
    });
  }

  Future<void> _signOut() async {
    await _authRepository.signOut();
    if (!mounted) {
      return;
    }
    setState(() {
      _currentUser = null;
      _showSignUp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _currentUserFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '로그인 상태를 확인하지 못했습니다.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final user = _currentUser;
        if (user != null) {
          return HomeScreen(user: user, onSignOut: _signOut);
        }

        if (_showSignUp) {
          return SignUpScreen(
            onSignUp: _signUp,
            onMoveToLogin: () => setState(() => _showSignUp = false),
          );
        }

        return LoginScreen(
          onSignIn: _signIn,
          onMoveToSignUp: () => setState(() => _showSignUp = true),
        );
      },
    );
  }
}
