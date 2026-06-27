import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/data/api/api_client.dart';
import 'package:forgotten_client/data/api/safe_log_interceptor.dart';
import 'package:forgotten_client/data/auth/models.dart';
import 'package:forgotten_client/data/auth/token_store.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late InMemoryTokenStore tokenStore;
  late ApiClient client;
  late _CapturingAdapter adapter;

  setUp(() {
    tokenStore = InMemoryTokenStore();
    adapter = _CapturingAdapter();

    const defaults = AppConfigDefaults(
      flavor: 'test',
      apiBaseUrl: 'https://api.test.local',
      openAiMode: 'cloud',
      featureFlagsJson: '{}',
      appLogLevel: 'debug',
    );

    final config = AppConfig.fromEnvironment(defaults: defaults);
    client = ApiClient(config: config, tokenStore: tokenStore);
    client.dio.httpClientAdapter = adapter;
    client.dio.options.responseType = ResponseType.plain;
  });

  test('sets base URL from config', () {
    expect(client.dio.options.baseUrl, 'https://api.test.local');
  });

  test('omits Authorization header when no token is stored', () async {
    await client.dio.get<void>('/hello');

    expect(adapter.lastOptions, isNotNull);
    expect(adapter.lastOptions!.headers.containsKey('Authorization'), isFalse);
  });

  test('adds Authorization header when access token is present', () async {
    await tokenStore.write(
      const AuthTokens(
        accessToken: 'abc123',
        refreshToken: 'refresh',
        expiresAt: null,
      ),
    );

    await client.dio.get<void>('/hello');

    expect(adapter.lastOptions, isNotNull);
    expect(adapter.lastOptions!.headers['Authorization'], 'Bearer abc123');
  });

  test('sanitizeForLog redacts auth headers and token payloads', () {
    final sanitized =
        sanitizeForLog({
              'Authorization': 'Bearer access-token',
              'alternate_authorization': 'Bearer\talternate-token',
              'password': 'secret-password',
              'nested': {
                'access_token': 'access',
                'refresh_token': 'refresh',
                'email': 'user@example.com',
              },
            })
            as Map<dynamic, dynamic>;

    expect(sanitized['Authorization'], '<redacted>');
    expect(sanitized['alternate_authorization'], 'Bearer <redacted>');
    expect(sanitized['password'], '<redacted>');
    expect(
      (sanitized['nested'] as Map<dynamic, dynamic>)['access_token'],
      '<redacted>',
    );
    expect(
      (sanitized['nested'] as Map<dynamic, dynamic>)['refresh_token'],
      '<redacted>',
    );
    expect(
      (sanitized['nested'] as Map<dynamic, dynamic>)['email'],
      'user@example.com',
    );
  });

  test('sanitizeForLog redacts generated auth DTOs before stringification', () {
    final sanitized =
        sanitizeForLog(
              LoginRequest(email: 'user@example.com', password: 'password123'),
            )
            as Map<dynamic, dynamic>;

    expect(sanitized['email'], 'user@example.com');
    expect(sanitized['password'], '<redacted>');
  });

  test('sanitizeForLog redacts JSON encoded request bodies', () {
    final sanitized = sanitizeForLog(
      '{"email":"user@example.com","password":"password123"}',
    );

    expect(sanitized, '{"email":"user@example.com","password":"<redacted>"}');
  });
}
