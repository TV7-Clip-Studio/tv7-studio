import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forgotten_client/data/local/engine_client.dart';

class _FakeTransport implements EngineJsonTransport {
  _FakeTransport(this.responses);

  final Map<String, Map<String, dynamic>> responses;
  final requested = <Uri>[];

  @override
  Future<EngineHttpResponse> request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    requested.add(uri);
    final response = responses[uri.path];
    if (response == null) {
      throw const SocketException('missing response');
    }
    return EngineHttpResponse(
      statusCode: 200,
      elapsed: Duration.zero,
      json: response,
      rawBody: response.toString(),
    );
  }
}

void main() {
  test('getHealth calls Engine health endpoint', () async {
    final transport = _FakeTransport({
      '/health': {'status': 'ok'},
    });
    final client = EngineClient(
      baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
      transport: transport,
    );

    final health = await client.getHealth();

    expect(health.isOk, isTrue);
    expect(transport.requested.single.path, '/health');
  });

  test('getDiagnostics parses degraded repair summary', () async {
    final transport = _FakeTransport({
      '/v1/diagnostics': {
        'status': 'degraded',
        'tools': [
          {'name': 'ffprobe', 'available': false},
        ],
      },
    });
    final client = EngineClient(
      baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
      transport: transport,
    );

    final diagnostics = await client.getDiagnostics();

    expect(diagnostics.isReady, isFalse);
    expect(diagnostics.summary, 'Engine degraded: missing ffprobe');
    expect(transport.requested.single.path, '/v1/diagnostics');
  });
}
