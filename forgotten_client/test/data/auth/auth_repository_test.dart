import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/data/api/api_client.dart';
import 'package:forgotten_client/data/auth/auth_repository.dart';
import 'package:forgotten_client/data/auth/models.dart';
import 'package:forgotten_client/data/auth/token_store.dart';

class _StubAuthAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    final path = options.path;
    if (path.contains('/api/v1/auth/login')) {
      return ResponseBody.fromString(
        '{"access_token":"token123","refresh_token":"refresh123","token_type":"bearer"}',
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }
    if (path.contains('/api/v1/auth/refresh')) {
      return ResponseBody.fromString(
        '{"access_token":"newAccess","refresh_token":"newRefresh","token_type":"bearer"}',
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }
    throw DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 404,
      ),
      type: DioExceptionType.badResponse,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late InMemoryTokenStore tokenStore;
  late AuthRepository repository;

  setUp(() {
    tokenStore = InMemoryTokenStore();
    const defaults = AppConfigDefaults(
      flavor: 'test',
      apiBaseUrl: 'https://api.test.local',
      openAiMode: 'cloud',
      featureFlagsJson: '{}',
      appLogLevel: 'debug',
    );
    final config = AppConfig.fromEnvironment(defaults: defaults);
    repository = AuthRepository(
      config: config,
      apiClient: ApiClient(config: config, tokenStore: tokenStore),
      tokenStore: tokenStore,
    );
    repository.apiClient.dio.httpClientAdapter = _StubAuthAdapter();
  });

  group('AuthRepository', () {
    test('login writes tokens to the token store', () async {
      final tokens = await repository.login(
        email: 'user@example.com',
        password: 'password',
      );

      final stored = await tokenStore.read();
      expect(stored, isNotNull);
      expect(stored!.accessToken, tokens.accessToken);
      expect(stored.refreshToken, tokens.refreshToken);
    });

    test('logout clears stored tokens', () async {
      await repository.login(email: 'user@example.com', password: 'pw');
      expect(await tokenStore.read(), isNotNull);

      await repository.logout();

      expect(await tokenStore.read(), isNull);
    });

    test('refresh returns new tokens and stores them', () async {
      final tokens = AuthTokens(
        accessToken: 'a',
        refreshToken: 'b',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      final refreshed = await repository.refresh(tokens);
      expect(refreshed, isNotNull);
      expect(refreshed!.accessToken, 'newAccess');
      expect(refreshed.refreshToken, 'newRefresh');

      final stored = await tokenStore.read();
      expect(stored, isNotNull);
      expect(stored!.accessToken, 'newAccess');
    });
  });

  group('AuthTokens', () {
    test('isExpired reflects expiration timestamp', () {
      final expired = AuthTokens(
        accessToken: 'a',
        refreshToken: 'b',
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      final valid = AuthTokens(
        accessToken: 'a',
        refreshToken: 'b',
        expiresAt: DateTime.now().add(const Duration(seconds: 1)),
      );
      final noExpiry = AuthTokens(
        accessToken: 'a',
        refreshToken: 'b',
        expiresAt: null,
      );

      expect(expired.isExpired, isTrue);
      expect(valid.isExpired, isFalse);
      expect(noExpiry.isExpired, isFalse);
    });
  });
}
