import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/data/api/api_client.dart';
import 'package:forgotten_client/data/auth/models.dart';
import 'package:forgotten_client/data/auth/token_store.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';

/// Handles auth flows against the backend. Endpoints will be wired once
/// the OpenAPI client is generated.
class AuthRepository {
  AuthRepository({
    required this.config,
    required this.apiClient,
    required this.tokenStore,
    AuthApi? authApi,
  }) : _authApi = authApi ?? AuthApi(apiClient.dio);

  final AppConfig config;
  final ApiClient apiClient;
  final TokenStore tokenStore;
  final AuthApi _authApi;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await _authApi.loginApiV1AuthLoginPost(
      loginRequest: LoginRequest(email: email, password: password),
    );
    final token = response.data;
    if (token == null || token.accessToken.isEmpty) {
      throw Exception('Login failed: missing token');
    }

    final authTokens = AuthTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken ?? '',
      expiresAt:
          null, // JWT carries its own exp; we rely on backend enforcement.
    );
    await tokenStore.write(authTokens);
    return authTokens;
  }

  Future<AuthTokens?> refresh(AuthTokens current) async {
    final response = await _authApi.refreshTokenApiV1AuthRefreshPost(
      tokenRefreshRequest: TokenRefreshRequest(
        refreshToken: current.refreshToken,
      ),
    );
    final token = response.data;
    if (token == null || token.accessToken.isEmpty) {
      return null;
    }
    final refreshed = AuthTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken ?? current.refreshToken,
      expiresAt: null,
    );
    await tokenStore.write(refreshed);
    return refreshed;
  }

  Future<void> logout() async {
    await tokenStore.clear();
  }
}
