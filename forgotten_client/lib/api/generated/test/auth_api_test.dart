import 'package:test/test.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';

/// tests for AuthApi
void main() {
  final instance = ForgottenClientApi().getAuthApi();

  group(AuthApi, () {
    // Login
    //
    //Future<Token> loginApiV1AuthLoginPost(LoginRequest loginRequest) async
    test('test loginApiV1AuthLoginPost', () async {
      // TODO
    });

    // Refresh Token
    //
    //Future<Token> refreshTokenApiV1AuthRefreshPost(TokenRefreshRequest tokenRefreshRequest) async
    test('test refreshTokenApiV1AuthRefreshPost', () async {
      // TODO
    });
  });
}
