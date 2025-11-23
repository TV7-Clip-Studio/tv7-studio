import '../../config/app_config.dart';
import '../api/api_client.dart';
import 'models.dart';
import 'token_store.dart';

/// Handles auth flows against the backend. Endpoints will be wired once
/// the OpenAPI client is generated.
class AuthRepository {
  AuthRepository({
    required this.config,
    required this.apiClient,
    required this.tokenStore,
  });

  final AppConfig config;
  final ApiClient apiClient;
  final TokenStore tokenStore;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    // TODO: replace with generated client call once OpenAPI is available.
    throw UnimplementedError('login endpoint not wired yet');
  }

  Future<AuthTokens?> refresh(AuthTokens current) async {
    // TODO: replace with generated client call once OpenAPI is available.
    return null;
  }

  Future<void> logout() async {
    await tokenStore.clear();
  }
}
