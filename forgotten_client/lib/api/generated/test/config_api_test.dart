import 'package:test/test.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';

/// tests for ConfigApi
void main() {
  final instance = ForgottenClientApi().getConfigApi();

  group(ConfigApi, () {
    // Get Config
    //
    // Expose feature flags and limits for the Flutter client.
    //
    //Future<ConfigRead> getConfigApiV1ConfigGet() async
    test('test getConfigApiV1ConfigGet', () async {
      // TODO
    });
  });
}
