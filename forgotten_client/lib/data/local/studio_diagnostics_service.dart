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
    this.metadata = const <String, Object?>{},
  });

  final String name;
  final DiagnosticCheckStatus status;
  final String detail;
  final Map<String, Object?> metadata;
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
    ];

    EngineDiagnostics? engineDiagnostics;
    try {
      engineDiagnostics = await engineClient.getDiagnostics();
      checks.add(
        DiagnosticCheck(
          name: 'Engine /v1/diagnostics',
          status: engineDiagnostics.isReady
              ? DiagnosticCheckStatus.ready
              : DiagnosticCheckStatus.degraded,
          detail: engineDiagnostics.summary,
        ),
      );
    } catch (error) {
      checks.add(
        DiagnosticCheck(
          name: 'Engine /v1/diagnostics',
          status: DiagnosticCheckStatus.unavailable,
          detail: error.toString(),
        ),
      );
    }

    if (engineDiagnostics != null) {
      final capabilities = engineDiagnostics.raw['capabilities'];
      if (capabilities is List) {
        for (final cap in capabilities) {
          if (cap is Map<String, dynamic>) {
            final name = cap['name']?.toString() ?? 'unknown';
            final statusStr = cap['status']?.toString() ?? 'unknown';
            final requiredTools = cap['required_tools'] as List?;
            final toolsStr = requiredTools?.join(', ') ?? 'none';

            checks.add(
              DiagnosticCheck(
                name: 'Engine capability: $name',
                status: _parseCheckStatus(statusStr),
                detail: 'Required tools: $toolsStr',
              ),
            );
          }
        }
      }

      final tools = engineDiagnostics.raw['tools'];
      if (tools is List) {
        for (final tool in tools) {
          if (tool is Map<String, dynamic>) {
            final name = tool['name']?.toString() ?? 'unknown';
            final available = tool['available'] as bool?;
            final version = tool['version']?.toString() ?? 'unknown version';
            final requiredFor = tool['required_for'] as List?;
            final reqStr = requiredFor?.join(', ') ?? 'none';
            final error = tool['error']?.toString();

            DiagnosticCheckStatus status;
            if (available == true) {
              status = DiagnosticCheckStatus.ready;
            } else if (available == false) {
              status = DiagnosticCheckStatus.unavailable;
            } else {
              status = DiagnosticCheckStatus.unknown;
            }

            checks.add(
              DiagnosticCheck(
                name: 'Engine tool: $name',
                status: status,
                detail: error != null && error.isNotEmpty
                    ? 'Error: $error'
                    : 'Available: $available ($version), Required for: $reqStr',
              ),
            );
          }
        }
      }
    }

    try {
      final setupManifest = await engineClient.getSetupManifest();
      checks.add(
        DiagnosticCheck(
          name: 'Engine /v1/setup/manifest',
          status: DiagnosticCheckStatus.ready,
          detail: _setupManifestDetail(setupManifest),
        ),
      );
    } catch (error) {
      checks.add(
        DiagnosticCheck(
          name: 'Engine /v1/setup/manifest',
          status: DiagnosticCheckStatus.degraded,
          detail:
              'Setup manifest unavailable on this Engine build or request failed: $error',
        ),
      );
    }

    try {
      final setupStatus = await engineClient.getSetupStatus();
      checks.addAll(_setupChecks(setupStatus));
    } catch (error) {
      checks.add(
        DiagnosticCheck(
          name: 'Engine /v1/setup/status',
          status: DiagnosticCheckStatus.degraded,
          detail:
              'Setup readiness unavailable on this Engine build or request failed: $error',
        ),
      );
    }

    checks.add(await _backendUsersEndpointCheck());
    checks.add(await _backendLicenseCheck());
    checks.add(await _workspaceCheck());

    return StudioDiagnosticsSnapshot(
      collectedAt: DateTime.now(),
      checks: checks,
      endpointResults: const [],
      settings: await _settings(),
      recentErrors: diagnosticsLog.entries,
    );
  }

  DiagnosticCheckStatus _parseCheckStatus(String value) {
    return switch (value) {
      'ready' => DiagnosticCheckStatus.ready,
      'degraded' => DiagnosticCheckStatus.degraded,
      _ => DiagnosticCheckStatus.unknown,
    };
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
        name: 'Setup manifest',
        method: 'GET',
        path: '/v1/setup/manifest',
      ),
      _EndpointSmokeDefinition(
        name: 'Setup status',
        method: 'GET',
        path: '/v1/setup/status',
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
      _EndpointSmokeDefinition(
        name: 'Ingest rejects local URL',
        method: 'POST',
        path: '/v1/ingest/url',
        body: {'url': 'http://localhost/video', 'output_dir': outputDir.path},
        expectedStatusCode: 400,
      ),
      _EndpointSmokeDefinition(
        name: 'Transcript rejects local URL',
        method: 'POST',
        path: '/v1/transcripts/download',
        body: {
          'url': 'http://localhost/video',
          'output_path': '${outputDir.path}/diagnostics_sub.vtt',
        },
        expectedStatusCode: 400,
      ),
      _EndpointSmokeDefinition(
        name: 'Job query (404)',
        method: 'GET',
        path: '/v1/jobs/smoke_test_non_existent',
        expectedStatusCode: 404,
      ),
      _EndpointSmokeDefinition(
        name: 'Job logs (404)',
        method: 'GET',
        path: '/v1/jobs/smoke_test_non_existent/logs',
        expectedStatusCode: 404,
      ),
      _EndpointSmokeDefinition(
        name: 'Job cancel (404)',
        method: 'POST',
        path: '/v1/jobs/smoke_test_non_existent/cancel',
        expectedStatusCode: 404,
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
        status: response.statusCode == endpoint.expectedStatusCode
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

  List<DiagnosticCheck> _setupChecks(SetupStatus setupStatus) {
    final checks = <DiagnosticCheck>[
      DiagnosticCheck(
        name: 'Engine /v1/setup/status',
        status: setupStatus.setupComplete
            ? DiagnosticCheckStatus.ready
            : DiagnosticCheckStatus.degraded,
        detail: setupStatus.setupComplete
            ? 'Offline creation setup complete.'
            : 'Offline creation setup incomplete; capability readiness below.',
      ),
    ];

    for (final name in const ['transcription', 'ai', 'offline_creation']) {
      final capability = setupStatus.capability(name);
      if (capability == null) {
        checks.add(
          DiagnosticCheck(
            name: 'Engine setup: $name',
            status: DiagnosticCheckStatus.unknown,
            detail: 'Capability not reported by Engine setup status.',
          ),
        );
        continue;
      }
      checks.add(_setupCapabilityCheck(setupStatus, capability));
    }

    for (final provider in setupStatus.aiProviders) {
      checks.add(
        DiagnosticCheck(
          name: 'Engine AI provider: ${provider.source}',
          status: _setupProviderStatus(provider.status),
          detail: _setupProviderDetail(provider, setupStatus),
        ),
      );
    }

    for (final asset in setupStatus.assets) {
      checks.add(
        DiagnosticCheck(
          name: 'Engine setup asset: ${asset.name}',
          status: _setupItemStatus(asset.status),
          detail: _setupAssetDetail(asset),
        ),
      );
    }

    return checks;
  }

  String _setupManifestDetail(SetupManifest manifest) {
    final details = <String>[
      'platform=${manifest.platform}',
      if (manifest.effectiveSetupModes.isNotEmpty)
        'setup_modes=${manifest.effectiveSetupModes.join(', ')}',
      if (manifest.effectiveAiProviderOrder.isNotEmpty)
        'ai_provider_order=${manifest.effectiveAiProviderOrder.join(', ')}',
      'assets=${manifest.assets.length}',
    ];
    return details.join(' | ');
  }

  DiagnosticCheck _setupCapabilityCheck(
    SetupStatus setupStatus,
    SetupCapabilityStatus capability,
  ) {
    final missingAssets = setupStatus.missingAssetsFor(capability);
    final installableAssets = missingAssets
        .where((asset) => asset.isInstallable)
        .toList();
    final details = <String>[
      'status=${capability.status}',
      if (capability.provider != null) 'provider=${capability.provider}',
      if (capability.missing.isNotEmpty)
        'missing=${capability.missing.join(', ')}',
    ];
    if (capability.isReady) {
      if (capability.name == 'ai' && capability.provider == 'tv7_cloud') {
        details.add(
          'Ready through TV7 cloud AI; offline creation still requires local AI.',
        );
      } else {
        details.add('Ready from configured assets; no reinstall needed.');
      }
    } else if (installableAssets.isNotEmpty) {
      details.add(
        'Action: Set up ${_capabilityLabel(capability.name)} with explicit user confirmation before any download.',
      );
    } else if (capability.installable) {
      details.add(
        'Action: Import or configure missing ${_capabilityLabel(capability.name)} assets.',
      );
    } else if (capability.userActionRequired) {
      details.add('Action: user configuration required.');
    }

    return DiagnosticCheck(
      name: 'Engine setup: ${capability.name}',
      status: capability.isReady
          ? DiagnosticCheckStatus.ready
          : DiagnosticCheckStatus.degraded,
      detail: details.join(' | '),
    );
  }

  String _setupProviderDetail(
    SetupProviderStatus provider,
    SetupStatus setupStatus,
  ) {
    final activeProvider = setupStatus.effectiveActiveAiProvider;
    return [
      'status=${provider.status}',
      'source=${provider.source}',
      if (activeProvider == provider.source) 'active=true',
      if (provider.requiresInternet) 'requires_internet=true',
      if (provider.requiresUserConfirmation) 'requires_user_confirmation=true',
      if (provider.costPolicy != null) 'cost_policy=${provider.costPolicy}',
      if (provider.requiredAssets.isNotEmpty)
        'required_assets=${provider.requiredAssets.join(', ')}',
      if (provider.action != null && provider.action!.isNotEmpty)
        'action=${provider.action}',
    ].join(' | ');
  }

  String _setupAssetDetail(SetupAssetStatus asset) {
    final details = <String>[
      'status=${asset.status}',
      'source=${asset.source}',
      'kind=${asset.kind}',
      if (asset.path != null && asset.path!.isNotEmpty) 'path=${asset.path}',
      if (asset.version != null && asset.version!.isNotEmpty)
        'version=${asset.version}',
      if (asset.error != null && asset.error!.isNotEmpty)
        'error=${asset.error}',
    ];
    if (asset.isAvailable && asset.isUserInstalled) {
      details.add('User-installed asset ready; no reinstall needed.');
    } else if (asset.isInstallable) {
      details.add(
        'Action: available for setup/import/download only after explicit user confirmation.',
      );
    }
    return details.join(' | ');
  }

  String _capabilityLabel(String name) {
    return name.replaceAll('_', ' ');
  }

  DiagnosticCheckStatus _setupItemStatus(String status) {
    return switch (status) {
      'available' => DiagnosticCheckStatus.ready,
      'installable' => DiagnosticCheckStatus.degraded,
      'missing' => DiagnosticCheckStatus.unavailable,
      'unsupported' => DiagnosticCheckStatus.unavailable,
      _ => DiagnosticCheckStatus.unknown,
    };
  }

  DiagnosticCheckStatus _setupProviderStatus(String status) {
    return switch (status) {
      'ready' => DiagnosticCheckStatus.ready,
      'missing_assets' => DiagnosticCheckStatus.degraded,
      'missing_model' => DiagnosticCheckStatus.degraded,
      'missing_api_key' => DiagnosticCheckStatus.degraded,
      'disabled' => DiagnosticCheckStatus.unknown,
      _ => DiagnosticCheckStatus.unknown,
    };
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

  Future<DiagnosticCheck> _backendLicenseCheck() async {
    try {
      final response = await dio.get<Object>(
        '/api/v1/auth/license',
        options: Options(validateStatus: (_) => true),
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final accountActive = data['account_active'] == true;
          final licenseStatus =
              data['license_status']?.toString() ?? 'required';
          final cloudAiAvailable = data['cloud_ai_available'] == true;
          final canRequestToken =
              data['can_request_engine_cloud_ai_token'] == true;
          final rawCredits = data['cloud_ai_credits_remaining'];
          final credits = rawCredits is num
              ? rawCredits.toInt()
              : int.tryParse(rawCredits?.toString() ?? '') ?? 0;
          final reasonCode = data['reason_code']?.toString() ?? 'UNKNOWN';
          final scope =
              data['engine_cloud_ai_scope']?.toString() ?? 'engine:cloud_ai';
          final isReady = accountActive && cloudAiAvailable && canRequestToken;
          return DiagnosticCheck(
            name: 'User License',
            status: isReady
                ? DiagnosticCheckStatus.ready
                : DiagnosticCheckStatus.degraded,
            detail:
                'status=$licenseStatus | cloud_ai=${cloudAiAvailable ? 'ready' : 'unavailable'} | credits=$credits | reason=$reasonCode',
            metadata: <String, Object?>{
              'account_active': accountActive,
              'license_status': licenseStatus,
              'cloud_ai_available': cloudAiAvailable,
              'cloud_ai_credits_remaining': credits,
              'can_request_engine_cloud_ai_token': canRequestToken,
              'engine_cloud_ai_scope': scope,
              'reason_code': reasonCode,
            },
          );
        }
      }
      if (statusCode == 404) {
        return DiagnosticCheck(
          name: 'User License',
          status: DiagnosticCheckStatus.degraded,
          detail:
              'License endpoint unavailable on this backend build (HTTP 404).',
        );
      }
      return DiagnosticCheck(
        name: 'User License',
        status: DiagnosticCheckStatus.degraded,
        detail: 'HTTP $statusCode from ${appConfig.apiBaseUrl}',
      );
    } catch (error) {
      return DiagnosticCheck(
        name: 'User License',
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
    await fixture.writeAsBytes(_tinyMp4Bytes);
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
    this.expectedStatusCode = 200,
  });

  final String name;
  final String method;
  final String path;
  final Map<String, dynamic>? body;
  final int expectedStatusCode;
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
  3,
  46,
  109,
  111,
  111,
  118,
  0,
  0,
  0,
  108,
  109,
  118,
  104,
  100,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  3,
  232,
  0,
  0,
  0,
  120,
  0,
  1,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  64,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  2,
  0,
  0,
  2,
  89,
  116,
  114,
  97,
  107,
  0,
  0,
  0,
  92,
  116,
  107,
  104,
  100,
  0,
  0,
  0,
  3,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  120,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  64,
  0,
  0,
  0,
  0,
  16,
  0,
  0,
  0,
  16,
  0,
  0,
  0,
  0,
  0,
  36,
  101,
  100,
  116,
  115,
  0,
  0,
  0,
  28,
  101,
  108,
  115,
  116,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  120,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  1,
  209,
  109,
  100,
  105,
  97,
  0,
  0,
  0,
  32,
  109,
  100,
  104,
  100,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  50,
  0,
  0,
  0,
  6,
  0,
  85,
  196,
  0,
  0,
  0,
  0,
  0,
  45,
  104,
  100,
  108,
  114,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  118,
  105,
  100,
  101,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  86,
  105,
  100,
  101,
  111,
  72,
  97,
  110,
  100,
  108,
  101,
  114,
  0,
  0,
  0,
  1,
  124,
  109,
  105,
  110,
  102,
  0,
  0,
  0,
  20,
  118,
  109,
  104,
  100,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  36,
  100,
  105,
  110,
  102,
  0,
  0,
  0,
  28,
  100,
  114,
  101,
  102,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  12,
  117,
  114,
  108,
  32,
  0,
  0,
  0,
  1,
  0,
  0,
  1,
  60,
  115,
  116,
  98,
  108,
  0,
  0,
  0,
  184,
  115,
  116,
  115,
  100,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  168,
  97,
  118,
  99,
  49,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  16,
  0,
  16,
  0,
  72,
  0,
  0,
  0,
  72,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  21,
  76,
  97,
  118,
  99,
  54,
  50,
  46,
  49,
  49,
  46,
  49,
  48,
  48,
  32,
  108,
  105,
  98,
  120,
  50,
  54,
  52,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  24,
  255,
  255,
  0,
  0,
  0,
  46,
  97,
  118,
  99,
  67,
  1,
  66,
  192,
  10,
  255,
  225,
  0,
  22,
  103,
  66,
  192,
  10,
  217,
  30,
  192,
  68,
  0,
  0,
  3,
  0,
  4,
  0,
  0,
  3,
  0,
  200,
  60,
  72,
  153,
  32,
  1,
  0,
  5,
  104,
  203,
  131,
  203,
  32,
  0,
  0,
  0,
  16,
  112,
  97,
  115,
  112,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  20,
  98,
  116,
  114,
  116,
  0,
  0,
  0,
  0,
  0,
  0,
  172,
  101,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  24,
  115,
  116,
  116,
  115,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  3,
  0,
  0,
  2,
  0,
  0,
  0,
  0,
  20,
  115,
  116,
  115,
  115,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  28,
  115,
  116,
  115,
  99,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  3,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  32,
  115,
  116,
  115,
  122,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  3,
  0,
  0,
  2,
  131,
  0,
  0,
  0,
  9,
  0,
  0,
  0,
  10,
  0,
  0,
  0,
  20,
  115,
  116,
  99,
  111,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  3,
  94,
  0,
  0,
  0,
  97,
  117,
  100,
  116,
  97,
  0,
  0,
  0,
  89,
  109,
  101,
  116,
  97,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  33,
  104,
  100,
  108,
  114,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  109,
  100,
  105,
  114,
  97,
  112,
  112,
  108,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  44,
  105,
  108,
  115,
  116,
  0,
  0,
  0,
  36,
  169,
  116,
  111,
  111,
  0,
  0,
  0,
  28,
  100,
  97,
  116,
  97,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  76,
  97,
  118,
  102,
  54,
  50,
  46,
  51,
  46,
  49,
  48,
  48,
  0,
  0,
  0,
  8,
  102,
  114,
  101,
  101,
  0,
  0,
  2,
  158,
  109,
  100,
  97,
  116,
  0,
  0,
  2,
  113,
  6,
  5,
  255,
  255,
  109,
  220,
  69,
  233,
  189,
  230,
  217,
  72,
  183,
  150,
  44,
  216,
  32,
  217,
  35,
  238,
  239,
  120,
  50,
  54,
  52,
  32,
  45,
  32,
  99,
  111,
  114,
  101,
  32,
  49,
  54,
  53,
  32,
  114,
  51,
  50,
  50,
  50,
  32,
  98,
  51,
  53,
  54,
  48,
  53,
  97,
  32,
  45,
  32,
  72,
  46,
  50,
  54,
  52,
  47,
  77,
  80,
  69,
  71,
  45,
  52,
  32,
  65,
  86,
  67,
  32,
  99,
  111,
  100,
  101,
  99,
  32,
  45,
  32,
  67,
  111,
  112,
  121,
  108,
  101,
  102,
  116,
  32,
  50,
  48,
  48,
  51,
  45,
  50,
  48,
  50,
  53,
  32,
  45,
  32,
  104,
  116,
  116,
  112,
  58,
  47,
  47,
  119,
  119,
  119,
  46,
  118,
  105,
  100,
  101,
  111,
  108,
  97,
  110,
  46,
  111,
  114,
  103,
  47,
  120,
  50,
  54,
  52,
  46,
  104,
  116,
  109,
  108,
  32,
  45,
  32,
  111,
  112,
  116,
  105,
  111,
  110,
  115,
  58,
  32,
  99,
  97,
  98,
  97,
  99,
  61,
  48,
  32,
  114,
  101,
  102,
  61,
  51,
  32,
  100,
  101,
  98,
  108,
  111,
  99,
  107,
  61,
  49,
  58,
  48,
  58,
  48,
  32,
  97,
  110,
  97,
  108,
  121,
  115,
  101,
  61,
  48,
  120,
  49,
  58,
  48,
  120,
  49,
  49,
  49,
  32,
  109,
  101,
  61,
  104,
  101,
  120,
  32,
  115,
  117,
  98,
  109,
  101,
  61,
  55,
  32,
  112,
  115,
  121,
  61,
  49,
  32,
  112,
  115,
  121,
  95,
  114,
  100,
  61,
  49,
  46,
  48,
  48,
  58,
  48,
  46,
  48,
  48,
  32,
  109,
  105,
  120,
  101,
  100,
  95,
  114,
  101,
  102,
  61,
  49,
  32,
  109,
  101,
  95,
  114,
  97,
  110,
  103,
  101,
  61,
  49,
  54,
  32,
  99,
  104,
  114,
  111,
  109,
  97,
  95,
  109,
  101,
  61,
  49,
  32,
  116,
  114,
  101,
  108,
  108,
  105,
  115,
  61,
  49,
  32,
  56,
  120,
  56,
  100,
  99,
  116,
  61,
  48,
  32,
  99,
  113,
  109,
  61,
  48,
  32,
  100,
  101,
  97,
  100,
  122,
  111,
  110,
  101,
  61,
  50,
  49,
  44,
  49,
  49,
  32,
  102,
  97,
  115,
  116,
  95,
  112,
  115,
  107,
  105,
  112,
  61,
  49,
  32,
  99,
  104,
  114,
  111,
  109,
  97,
  95,
  113,
  112,
  95,
  111,
  102,
  102,
  115,
  101,
  116,
  61,
  45,
  50,
  32,
  116,
  104,
  114,
  101,
  97,
  100,
  115,
  61,
  49,
  32,
  108,
  111,
  111,
  107,
  97,
  104,
  101,
  97,
  100,
  95,
  116,
  104,
  114,
  101,
  97,
  100,
  115,
  61,
  49,
  32,
  115,
  108,
  105,
  99,
  101,
  100,
  95,
  116,
  104,
  114,
  101,
  97,
  100,
  115,
  61,
  48,
  32,
  110,
  114,
  61,
  48,
  32,
  100,
  101,
  99,
  105,
  109,
  97,
  116,
  101,
  61,
  49,
  32,
  105,
  110,
  116,
  101,
  114,
  108,
  97,
  99,
  101,
  100,
  61,
  48,
  32,
  98,
  108,
  117,
  114,
  97,
  121,
  95,
  99,
  111,
  109,
  112,
  97,
  116,
  61,
  48,
  32,
  99,
  111,
  110,
  115,
  116,
  114,
  97,
  105,
  110,
  101,
  100,
  95,
  105,
  110,
  116,
  114,
  97,
  61,
  48,
  32,
  98,
  102,
  114,
  97,
  109,
  101,
  115,
  61,
  48,
  32,
  119,
  101,
  105,
  103,
  104,
  116,
  112,
  61,
  48,
  32,
  107,
  101,
  121,
  105,
  110,
  116,
  61,
  50,
  53,
  48,
  32,
  107,
  101,
  121,
  105,
  110,
  116,
  95,
  109,
  105,
  110,
  61,
  50,
  53,
  32,
  115,
  99,
  101,
  110,
  101,
  99,
  117,
  116,
  61,
  52,
  48,
  32,
  105,
  110,
  116,
  114,
  97,
  95,
  114,
  101,
  102,
  114,
  101,
  115,
  104,
  61,
  48,
  32,
  114,
  99,
  95,
  108,
  111,
  111,
  107,
  97,
  104,
  101,
  97,
  100,
  61,
  52,
  48,
  32,
  114,
  99,
  61,
  99,
  114,
  102,
  32,
  109,
  98,
  116,
  114,
  101,
  101,
  61,
  49,
  32,
  99,
  114,
  102,
  61,
  50,
  51,
  46,
  48,
  32,
  113,
  99,
  111,
  109,
  112,
  61,
  48,
  46,
  54,
  48,
  32,
  113,
  112,
  109,
  105,
  110,
  61,
  48,
  32,
  113,
  112,
  109,
  97,
  120,
  61,
  54,
  57,
  32,
  113,
  112,
  115,
  116,
  101,
  112,
  61,
  52,
  32,
  105,
  112,
  95,
  114,
  97,
  116,
  105,
  111,
  61,
  49,
  46,
  52,
  48,
  32,
  97,
  113,
  61,
  49,
  58,
  49,
  46,
  48,
  48,
  0,
  128,
  0,
  0,
  0,
  10,
  101,
  136,
  132,
  11,
  242,
  98,
  128,
  0,
  171,
  206,
  0,
  0,
  0,
  5,
  65,
  154,
  56,
  23,
  234,
  0,
  0,
  0,
  6,
  65,
  154,
  84,
  5,
  122,
  128,
];
