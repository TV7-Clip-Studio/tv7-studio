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
    } else if (uri.path == '/v1/setup/manifest') {
      json = {
        'schema_version': 1,
        'platform': 'macos-arm64',
        'setup_modes': ['automatic', 'disabled'],
        'ai_provider_order': ['ollama', 'tv7_managed', 'tv7_cloud'],
        'assets': <Map<String, dynamic>>[],
      };
    } else if (uri.path == '/v1/setup/status') {
      json = _setupStatusPayload();
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

class _SetupDownTransport extends _FakeTransport {
  @override
  Future<EngineHttpResponse> request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) {
    if (uri.path == '/v1/setup/manifest' || uri.path == '/v1/setup/status') {
      throw const SocketException('setup endpoint down');
    }
    return super.request(method, uri, body: body);
  }
}

Map<String, dynamic> _setupStatusPayload() {
  return {
    'schema_version': 1,
    'setup_complete': false,
    'active_ai_provider': 'tv7_cloud',
    'assets': [
      {
        'id': 'whisper-runtime.user-path',
        'kind': 'transcription_runtime',
        'name': 'User-installed Whisper runtime',
        'status': 'missing',
        'source': 'user_path',
        'path': null,
        'version': null,
        'error': 'not configured',
      },
      {
        'id': 'whisper-model.tv7-managed.macos-arm64',
        'kind': 'transcription_model',
        'name': 'TV7-managed Whisper model',
        'status': 'installable',
        'source': 'tv7_managed',
        'path': '/tmp/models/whisper',
        'version': null,
        'error': 'download requires explicit user confirmation',
      },
      {
        'id': 'ollama.user-runtime',
        'kind': 'llm_runtime',
        'name': 'User-installed Ollama runtime',
        'status': 'available',
        'source': 'ollama',
        'path': '/usr/local/bin/ollama',
        'version': 'ollama 0.9',
        'error': null,
      },
      {
        'id': 'ollama.model.qwen',
        'kind': 'llm_model',
        'name': 'Selected Ollama model',
        'status': 'available',
        'source': 'ollama',
        'path': null,
        'version': 'qwen2.5',
        'error': null,
      },
    ],
    'ai_providers': [
      {
        'source': 'ollama',
        'status': 'missing_assets',
        'required_assets': ['llm_runtime', 'llm_model'],
        'requires_internet': false,
        'requires_user_confirmation': true,
        'cost_policy': 'user_local',
        'action': 'Install Ollama and configure a compatible model.',
      },
      {
        'source': 'tv7_cloud',
        'status': 'ready',
        'required_assets': <String>[],
        'requires_internet': true,
        'requires_user_confirmation': false,
        'cost_policy': 'tv7_managed_usage',
        'action': null,
      },
    ],
    'capabilities': [
      {
        'name': 'transcription',
        'status': 'not_ready',
        'provider': null,
        'missing': ['transcription_runtime', 'transcription_model'],
        'installable': true,
        'user_action_required': true,
      },
      {
        'name': 'ai',
        'status': 'ready',
        'provider': 'tv7_cloud',
        'missing': <String>[],
        'installable': true,
        'user_action_required': false,
      },
      {
        'name': 'offline_creation',
        'status': 'not_ready',
        'provider': null,
        'missing': ['transcription', 'local_ai'],
        'installable': true,
        'user_action_required': true,
      },
    ],
  };
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
        '{"account_active": true, "license_status": "active", "cloud_ai_available": true, "cloud_ai_credits_remaining": 1001000000, "can_request_engine_cloud_ai_token": true, "engine_cloud_ai_scope": "engine:cloud_ai", "reason_code": "READY"}',
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
        contains('Engine /v1/setup/status'),
      );
      expect(
        snapshot.checks.map((check) => check.name),
        contains('Engine /v1/setup/manifest'),
      );
      expect(
        snapshot.checks.map((check) => check.name),
        contains('Engine setup: transcription'),
      );
      expect(
        snapshot.checks.map((check) => check.name),
        contains('Engine setup: ai'),
      );
      final transcriptionCheck = snapshot.checks.firstWhere(
        (check) => check.name == 'Engine setup: transcription',
      );
      expect(transcriptionCheck.detail, contains('Set up transcription'));
      expect(transcriptionCheck.detail, contains('explicit user confirmation'));
      final aiCheck = snapshot.checks.firstWhere(
        (check) => check.name == 'Engine setup: ai',
      );
      expect(aiCheck.status, DiagnosticCheckStatus.ready);
      expect(aiCheck.detail, contains('TV7 cloud AI'));
      final offlineCreationCheck = snapshot.checks.firstWhere(
        (check) => check.name == 'Engine setup: offline_creation',
      );
      expect(offlineCreationCheck.status, DiagnosticCheckStatus.degraded);
      expect(offlineCreationCheck.detail, contains('local_ai'));
      final cloudProviderCheck = snapshot.checks.firstWhere(
        (check) => check.name == 'Engine AI provider: tv7_cloud',
      );
      expect(cloudProviderCheck.status, DiagnosticCheckStatus.ready);
      expect(cloudProviderCheck.detail, contains('requires_internet=true'));
      expect(cloudProviderCheck.detail, contains('active=true'));
      final installableAssetCheck = snapshot.checks.firstWhere(
        (check) =>
            check.name == 'Engine setup asset: TV7-managed Whisper model',
      );
      expect(
        installableAssetCheck.detail,
        contains('explicit user confirmation'),
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
      expect(licenseCheck.detail, contains('status=active'));
      expect(licenseCheck.detail, contains('cloud_ai=ready'));
      expect(licenseCheck.metadata['cloud_ai_credits_remaining'], 1001000000);
      expect(licenseCheck.metadata['reason_code'], 'READY');

      expect(snapshot.settings['Flavor'], 'test');
      expect(snapshot.recentErrors.single.source, 'test source');
    },
  );

  test(
    'collect reports setup endpoint failures separately from health',
    () async {
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
          transport: _SetupDownTransport(),
        ),
        dio: dio,
        diagnosticsLog: DiagnosticsLog(),
        engineStartup: () => EngineStartupResult(
          status: EngineStartupStatus.ready,
          baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
        ),
      );

      final snapshot = await service.collect();
      final healthCheck = snapshot.checks.firstWhere(
        (check) => check.name == 'Engine /health',
      );
      final manifestCheck = snapshot.checks.firstWhere(
        (check) => check.name == 'Engine /v1/setup/manifest',
      );
      final statusCheck = snapshot.checks.firstWhere(
        (check) => check.name == 'Engine /v1/setup/status',
      );

      expect(healthCheck.status, DiagnosticCheckStatus.ready);
      expect(manifestCheck.status, DiagnosticCheckStatus.degraded);
      expect(manifestCheck.detail, contains('Setup manifest unavailable'));
      expect(statusCheck.status, DiagnosticCheckStatus.degraded);
      expect(statusCheck.detail, contains('Setup readiness unavailable'));
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
      contains('/v1/setup/manifest'),
    );
    expect(results.map((result) => result.path), contains('/v1/setup/status'));
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
