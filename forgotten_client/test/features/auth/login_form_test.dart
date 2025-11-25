import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/data/api/api_client.dart';
import 'package:forgotten_client/data/auth/auth_repository.dart';
import 'package:forgotten_client/data/auth/models.dart';
import 'package:forgotten_client/data/auth/token_store.dart';
import 'package:forgotten_client/features/auth/login_form.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({
    required this.onLogin,
  }) : super(
          config: AppConfig.fromEnvironment(
            defaults: const AppConfigDefaults(
              flavor: 'test',
              apiBaseUrl: 'https://api.test.local',
              openAiMode: 'cloud',
              featureFlagsJson: '{}',
              appLogLevel: 'debug',
            ),
          ),
          apiClient: ApiClient(
            config: AppConfig.fromEnvironment(
              defaults: const AppConfigDefaults(
                flavor: 'test',
                apiBaseUrl: 'https://api.test.local',
                openAiMode: 'cloud',
                featureFlagsJson: '{}',
                appLogLevel: 'debug',
              ),
            ),
            tokenStore: InMemoryTokenStore(),
          ),
          tokenStore: InMemoryTokenStore(),
        );

  final Future<AuthTokens> Function(String email, String password) onLogin;

  @override
  Future<AuthTokens> login({required String email, required String password}) {
    return onLogin(email, password);
  }
}

void main() {
  testWidgets('shows validation errors for empty fields', (tester) async {
    final authRepository = _FakeAuthRepository(
      onLogin: (_, __) async => const AuthTokens(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginForm(
            authRepository: authRepository,
            onSuccess: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter email'), findsOneWidget);
    expect(find.text('Enter password'), findsOneWidget);
  });

  testWidgets('invokes onSuccess after successful login', (tester) async {
    var loginCalls = 0;
    var onSuccessCalled = false;
    final authRepository = _FakeAuthRepository(
      onLogin: (email, password) async {
        loginCalls++;
        expect(email, 'user@example.com');
        expect(password, 'password123');
        return const AuthTokens(
          accessToken: 'token',
          refreshToken: 'refresh',
          expiresAt: null,
        );
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginForm(
            authRepository: authRepository,
            onSuccess: () {
              onSuccessCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(loginCalls, 1);
    expect(onSuccessCalled, isTrue);
  });

  testWidgets('surfaces errors from repository', (tester) async {
    final authRepository = _FakeAuthRepository(
      onLogin: (_, __) => Future<AuthTokens>.error(Exception('boom')),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginForm(
            authRepository: authRepository,
            onSuccess: () {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.textContaining('boom'), findsOneWidget);
  });
}
