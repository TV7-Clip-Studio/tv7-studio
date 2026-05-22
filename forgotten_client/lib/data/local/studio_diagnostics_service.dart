import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/data/local/diagnostics_log.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/engine_process_manager.dart';
import 'package:path_provider/path_provider.dart';

enum DiagnosticCheckStatus { ready, degraded, unavailable, unknown }

class DiagnosticCheck {
  const DiagnosticCheck({
    required this.name,
    required this.status,
    required this.detail,
  });

  final String name;
  final DiagnosticCheckStatus status;
  final String detail;
}

class StudioDiagnosticsSnapshot {
  const StudioDiagnosticsSnapshot({
    required this.collectedAt,
    required this.checks,
    required this.endpointResults,
    required this.settings,
    required this.recentErrors,
  });

  final DateTime collectedAt;
  final List<DiagnosticCheck> checks;
  final List<EngineEndpointResult> endpointResults;
  final Map<String, String> settings;
  final List<DiagnosticsLogEntry> recentErrors;
}

class EngineEndpointResult {
  const EngineEndpointResult({
    required this.name,
    required this.method,
    required this.path,
    required this.status,
    required this.detail,
    required this.elapsed,
    this.statusCode,
    this.requestPreview,
    this.responsePreview,
  });

  final String name;
  final String method;
  final String path;
  final DiagnosticCheckStatus status;
  final String detail;
  final Duration elapsed;
  final int? statusCode;
  final String? requestPreview;
  final String? responsePreview;
}

class StudioDiagnosticsService {
  const StudioDiagnosticsService({
    required this.appConfig,
    required this.engineClient,
    required this.dio,
    required this.diagnosticsLog,
    required this.engineStartup,
  });

  final AppConfig appConfig;
  final EngineClient engineClient;
  final Dio dio;
  final DiagnosticsLog diagnosticsLog;
  final EngineStartupResult Function() engineStartup;

  Future<StudioDiagnosticsSnapshot> collect() async {
    final checks = <DiagnosticCheck>[
      _startupCheck(engineStartup()),
      await _engineHealthCheck(),
      await _engineDiagnosticsCheck(),
      await _backendUsersEndpointCheck(),
      await _workspaceCheck(),
    ];

    return StudioDiagnosticsSnapshot(
      collectedAt: DateTime.now(),
      checks: checks,
      endpointResults: const [],
      settings: await _settings(),
      recentErrors: diagnosticsLog.entries,
    );
  }

  Future<List<EngineEndpointResult>> runEngineEndpointSmokeChecks() async {
    final fixture = await _prepareSmokeFixture();
    final outputDir = Directory('${fixture.parent.path}/diagnostics_output');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    final endpoints = [
      _EndpointSmokeDefinition(name: 'Health', method: 'GET', path: '/health'),
      _EndpointSmokeDefinition(
        name: 'Diagnostics',
        method: 'GET',
        path: '/v1/diagnostics',
      ),
      _EndpointSmokeDefinition(
        name: 'Probe',
        method: 'POST',
        path: '/v1/media/probe',
        body: {'path': fixture.path},
      ),
      _EndpointSmokeDefinition(
        name: 'Thumbnail',
        method: 'POST',
        path: '/v1/media/thumbnail',
        body: {
          'source_path': fixture.path,
          'output_path': '${outputDir.path}/diagnostics_thumb.jpg',
          'timestamp_seconds': 0.0,
        },
      ),
      _EndpointSmokeDefinition(
        name: 'Render clip',
        method: 'POST',
        path: '/v1/media/render-clip',
        body: {
          'source_path': fixture.path,
          'output_path': '${outputDir.path}/diagnostics_clip.mp4',
          'start_seconds': 0.0,
          'end_seconds': 0.5,
        },
      ),
    ];

    final results = <EngineEndpointResult>[];
    for (final endpoint in endpoints) {
      results.add(await _runEndpoint(endpoint));
    }
    return results;
  }

  Future<EngineEndpointResult> _runEndpoint(
    _EndpointSmokeDefinition endpoint,
  ) async {
    final requestPreview = endpoint.body == null
        ? null
        : jsonEncode(endpoint.body);
    try {
      final response = await engineClient.request(
        endpoint.method,
        endpoint.path,
        body: endpoint.body,
      );
      return EngineEndpointResult(
        name: endpoint.name,
        method: endpoint.method,
        path: endpoint.path,
        status: response.isSuccess
            ? DiagnosticCheckStatus.ready
            : DiagnosticCheckStatus.degraded,
        detail:
            'HTTP ${response.statusCode} in ${response.elapsed.inMilliseconds} ms',
        elapsed: response.elapsed,
        statusCode: response.statusCode,
        requestPreview: requestPreview,
        responsePreview: _truncate(response.rawBody),
      );
    } catch (error) {
      return EngineEndpointResult(
        name: endpoint.name,
        method: endpoint.method,
        path: endpoint.path,
        status: DiagnosticCheckStatus.unavailable,
        detail: error.toString(),
        elapsed: Duration.zero,
        requestPreview: requestPreview,
      );
    }
  }

  DiagnosticCheck _startupCheck(EngineStartupResult startup) {
    return DiagnosticCheck(
      name: 'Engine startup',
      status: _fromStartup(startup.status),
      detail: startup.message ?? startup.status.name,
    );
  }

  Future<DiagnosticCheck> _engineHealthCheck() async {
    try {
      final health = await engineClient.getHealth();
      return DiagnosticCheck(
        name: 'Engine /health',
        status: health.isOk
            ? DiagnosticCheckStatus.ready
            : DiagnosticCheckStatus.degraded,
        detail: 'status=${health.status}',
      );
    } catch (error) {
      return DiagnosticCheck(
        name: 'Engine /health',
        status: DiagnosticCheckStatus.unavailable,
        detail: error.toString(),
      );
    }
  }

  Future<DiagnosticCheck> _engineDiagnosticsCheck() async {
    try {
      final diagnostics = await engineClient.getDiagnostics();
      return DiagnosticCheck(
        name: 'Engine /v1/diagnostics',
        status: diagnostics.isReady
            ? DiagnosticCheckStatus.ready
            : DiagnosticCheckStatus.degraded,
        detail: diagnostics.summary,
      );
    } catch (error) {
      return DiagnosticCheck(
        name: 'Engine /v1/diagnostics',
        status: DiagnosticCheckStatus.unavailable,
        detail: error.toString(),
      );
    }
  }

  Future<DiagnosticCheck> _backendUsersEndpointCheck() async {
    try {
      final response = await dio.get<Object>(
        '/api/v1/users/',
        options: Options(validateStatus: (_) => true),
      );
      final statusCode = response.statusCode ?? 0;
      final status = statusCode >= 200 && statusCode < 300
          ? DiagnosticCheckStatus.ready
          : DiagnosticCheckStatus.degraded;
      return DiagnosticCheck(
        name: 'Backend /api/v1/users/',
        status: status,
        detail: 'HTTP $statusCode from ${appConfig.apiBaseUrl}',
      );
    } catch (error) {
      return DiagnosticCheck(
        name: 'Backend /api/v1/users/',
        status: DiagnosticCheckStatus.unavailable,
        detail: error.toString(),
      );
    }
  }

  Future<DiagnosticCheck> _workspaceCheck() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final workspace = Directory('${docs.path}/forgotten_workspace');
      final exists = await workspace.exists();
      return DiagnosticCheck(
        name: 'Local workspace',
        status: exists
            ? DiagnosticCheckStatus.ready
            : DiagnosticCheckStatus.degraded,
        detail: workspace.path,
      );
    } catch (error) {
      return DiagnosticCheck(
        name: 'Local workspace',
        status: DiagnosticCheckStatus.unavailable,
        detail: error.toString(),
      );
    }
  }

  Future<Map<String, String>> _settings() async {
    String workspacePath;
    try {
      final docs = await getApplicationDocumentsDirectory();
      workspacePath = '${docs.path}/forgotten_workspace';
    } catch (error) {
      workspacePath = 'unavailable: $error';
    }

    return {
      'Flavor': appConfig.flavor,
      'API base URL': appConfig.apiBaseUrl.toString(),
      'OpenAI mode': appConfig.openAiMode,
      'App log level': appConfig.appLogLevel,
      'Feature flags': appConfig.featureFlags.toString(),
      'Engine base URL': engineClient.baseUri.toString(),
      'Workspace path': workspacePath,
      'Platform': Platform.operatingSystem,
      'Dart version': Platform.version.split(' ').first,
    };
  }

  DiagnosticCheckStatus _fromStartup(EngineStartupStatus status) {
    return switch (status) {
      EngineStartupStatus.ready => DiagnosticCheckStatus.ready,
      EngineStartupStatus.degraded => DiagnosticCheckStatus.degraded,
      EngineStartupStatus.unavailable => DiagnosticCheckStatus.unavailable,
    };
  }

  Future<File> _prepareSmokeFixture() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/forgotten_workspace/diagnostics');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final fixture = File('${dir.path}/diagnostics_fixture.mp4');
    if (!await fixture.exists()) {
      await fixture.writeAsBytes(_tinyMp4Bytes);
    }
    return fixture;
  }

  String _truncate(String value) {
    if (value.length <= 2000) return value;
    return '${value.substring(0, 2000)}...';
  }
}

class _EndpointSmokeDefinition {
  const _EndpointSmokeDefinition({
    required this.name,
    required this.method,
    required this.path,
    this.body,
  });

  final String name;
  final String method;
  final String path;
  final Map<String, dynamic>? body;
}

final _tinyMp4Bytes = <int>[
  0,
  0,
  0,
  32,
  102,
  116,
  121,
  112,
  105,
  115,
  111,
  109,
  0,
  0,
  2,
  0,
  105,
  115,
  111,
  109,
  105,
  115,
  111,
  50,
  97,
  118,
  99,
  49,
  109,
  112,
  52,
  49,
  0,
  0,
  0,
  8,
  109,
  100,
  97,
  116,
];
