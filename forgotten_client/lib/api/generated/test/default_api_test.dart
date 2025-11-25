import 'package:test/test.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';


/// tests for DefaultApi
void main() {
  final instance = ForgottenClientApi().getDefaultApi();

  group(DefaultApi, () {
    // Health
    //
    //Future<Map<String, String>> healthHealthGet() async
    test('test healthHealthGet', () async {
      // TODO
    });

    // Metrics
    //
    // Endpoint that serves Prometheus metrics.
    //
    //Future<Object> metricsMetricsGet() async
    test('test metricsMetricsGet', () async {
      // TODO
    });

    // Readyz
    //
    //Future<Map<String, String>> readyzReadyzGet() async
    test('test readyzReadyzGet', () async {
      // TODO
    });

    // Version
    //
    //Future<Map<String, String>> versionVersionGet() async
    test('test versionVersionGet', () async {
      // TODO
    });

  });
}
