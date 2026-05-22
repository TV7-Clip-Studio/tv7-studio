import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/data/local/diagnostics_log.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/engine_process_manager.dart';
import 'package:forgotten_client/data/local/studio_diagnostics_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

class _FakeTransport implements EngineJsonTransport {
  @override
  Future<EngineHttpResponse> request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    Map<String, dynamic> json;
    if (uri.path == '/health') {
      json = {'status': 'ok'};
    } else if (uri.path == '/v1/diagnostics') {
      json = {'status': 'ready'};
    } else if (uri.path.startsWith('/v1/media/')) {
      json = {'result': 'ok'};
    } else {
      throw StateError('unexpected ${uri.path}');
    }
    return EngineHttpResponse(
      statusCode: 200,
      elapsed: Duration.zero,
      json: json,
      rawBody: json.toString(),
    );
  }
}

class _BackendAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    return ResponseBody.fromString('[]', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;

  setUp(() async {
    originalPathProvider = PathProviderPlatform.instance;
    tempDir = await Directory.systemTemp.createTemp('studio_diag_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await tempDir.delete(recursive: true);
  });

  test(
    'collect reports Engine, backend, settings, and recent errors',
    () async {
      final log = DiagnosticsLog()..record('test source', 'test failure');
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test.local'))
        ..httpClientAdapter = _BackendAdapter();
      final service = StudioDiagnosticsService(
        appConfig: AppConfig(
          flavor: 'test',
          apiBaseUrl: Uri.parse('https://api.test.local'),
          openAiMode: 'cloud',
          featureFlags: const {'publishing': false},
          appLogLevel: 'debug',
        ),
        engineClient: EngineClient(
          baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
          transport: _FakeTransport(),
        ),
        dio: dio,
        diagnosticsLog: log,
        engineStartup: () => EngineStartupResult(
          status: EngineStartupStatus.ready,
          baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
          message: 'Engine ready',
        ),
      );

      final snapshot = await service.collect();

      expect(
        snapshot.checks.map((check) => check.name),
        contains('Engine /health'),
      );
      expect(
        snapshot.checks.map((check) => check.name),
        contains('Engine /v1/diagnostics'),
      );
      expect(
        snapshot.checks.map((check) => check.name),
        contains('Backend /api/v1/users/'),
      );
      expect(snapshot.settings['Flavor'], 'test');
      expect(snapshot.recentErrors.single.source, 'test source');
    },
  );

  test('manual Engine smoke checks include media endpoint previews', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test.local'))
      ..httpClientAdapter = _BackendAdapter();
    final service = StudioDiagnosticsService(
      appConfig: AppConfig(
        flavor: 'test',
        apiBaseUrl: Uri.parse('https://api.test.local'),
        openAiMode: 'cloud',
        featureFlags: const {},
        appLogLevel: 'debug',
      ),
      engineClient: EngineClient(
        baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
        transport: _FakeTransport(),
      ),
      dio: dio,
      diagnosticsLog: DiagnosticsLog(),
      engineStartup: () => EngineStartupResult(
        status: EngineStartupStatus.ready,
        baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
      ),
    );

    final results = await service.runEngineEndpointSmokeChecks();

    expect(results.map((result) => result.path), contains('/v1/media/probe'));
    expect(
      results.map((result) => result.path),
      contains('/v1/media/thumbnail'),
    );
    expect(
      results
          .firstWhere((result) => result.path == '/v1/media/probe')
          .requestPreview,
      contains('diagnostics_fixture.mp4'),
    );
  });
}
