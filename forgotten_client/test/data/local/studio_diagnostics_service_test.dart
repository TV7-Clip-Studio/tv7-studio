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
    int statusCode = 200;
    if (uri.path == '/health') {
      json = {'status': 'ok'};
    } else if (uri.path == '/v1/diagnostics') {
      json = {
        'status': 'ready',
        'runtime': {
          'engine_version': '0.1.0',
          'host': '127.0.0.1',
          'port': 7070,
        },
        'capabilities': [
          {
            'name': 'probe',
            'status': 'ready',
            'required_tools': ['ffprobe'],
          },
          {
            'name': 'thumbnail',
            'status': 'ready',
            'required_tools': ['ffmpeg'],
          },
          {
            'name': 'render_clip',
            'status': 'ready',
            'required_tools': ['ffmpeg'],
          },
          {
            'name': 'url_ingest',
            'status': 'ready',
            'required_tools': ['yt-dlp'],
          },
          {
            'name': 'transcript',
            'status': 'ready',
            'required_tools': ['yt-dlp'],
          },
        ],
        'tools': [
          {
            'name': 'ffprobe',
            'available': true,
            'version': 'ffprobe version 8.0',
            'required_for': ['probe'],
            'error': null,
          },
          {
            'name': 'ffmpeg',
            'available': true,
            'version': 'ffmpeg version 8.0',
            'required_for': ['thumbnail', 'render_clip'],
            'error': null,
          },
          {
            'name': 'yt-dlp',
            'available': true,
            'version': 'yt-dlp 2026.01.01',
            'required_for': ['url_ingest', 'transcript'],
            'error': null,
          },
        ],
        'work_dir': {'path': '/tmp/workspace', 'ready': true, 'error': null},
      };
    } else if (uri.path.startsWith('/v1/media/')) {
      json = {'result': 'ok'};
    } else if (uri.path == '/v1/ingest/url' ||
        uri.path == '/v1/transcripts/download') {
      json = {
        'job': {
          'id': 'job_fake',
          'kind': uri.path.contains('ingest')
              ? 'url_ingest'
              : 'transcript_download',
          'status': 'queued',
          'progress': 0.0,
          'logs': ['queued'],
          'result': null,
          'error': null,
          'cancel_requested': false,
        },
      };
      statusCode = 202;
    } else if (uri.path.startsWith('/v1/jobs/')) {
      json = {'error': 'JOB_NOT_FOUND', 'message': 'job not found'};
      statusCode = 404;
    } else {
      throw StateError('unexpected ${uri.path}');
    }
    return EngineHttpResponse(
      statusCode: statusCode,
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
    if (options.path.contains('/auth/license')) {
      return ResponseBody.fromString(
        '{"plan": "pro", "license_token": "token_abc", "expires_at": "2026-12-31T23:59:59Z"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
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
        contains('Engine capability: url_ingest'),
      );
      expect(
        snapshot.checks.map((check) => check.name),
        contains('Engine capability: transcript'),
      );
      expect(
        snapshot.checks.map((check) => check.name),
        contains('Engine tool: yt-dlp'),
      );
      expect(
        snapshot.checks.map((check) => check.name),
        contains('Backend /api/v1/users/'),
      );
      expect(
        snapshot.checks.map((check) => check.name),
        contains('User License'),
      );
      final licenseCheck = snapshot.checks.firstWhere(
        (c) => c.name == 'User License',
      );
      expect(licenseCheck.status, DiagnosticCheckStatus.ready);
      expect(licenseCheck.detail, contains('Plan: PRO'));
      expect(licenseCheck.detail, contains('Expires: 2026-12-31'));

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
    expect(results.map((result) => result.path), contains('/v1/ingest/url'));
    expect(
      results.map((result) => result.path),
      contains('/v1/transcripts/download'),
    );
    expect(
      results.map((result) => result.path),
      contains('/v1/jobs/smoke_test_non_existent'),
    );
    expect(
      results
          .firstWhere((result) => result.path == '/v1/media/probe')
          .requestPreview,
      contains('diagnostics_fixture.mp4'),
    );
  });
}
