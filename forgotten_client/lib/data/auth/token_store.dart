import 'package:forgotten_client/data/auth/models.dart';

/// Abstraction over secure token storage; platform implementations can back
/// this with Keychain/Keystore/secure storage. An in-memory fallback is
/// provided for testing and early bootstrapping.
abstract class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

class InMemoryTokenStore implements TokenStore {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }
}
