import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/data/api/api_client.dart';
import 'package:forgotten_client/data/auth/auth_repository.dart';
import 'package:forgotten_client/data/auth/token_store.dart';
import 'package:forgotten_client/data/config/config_repository.dart';
import 'package:forgotten_client/data/local/diagnostics_log.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/engine_process_manager.dart';
import 'package:forgotten_client/data/local/local_video_repository.dart';
import 'package:forgotten_client/data/local/studio_diagnostics_service.dart';
import 'package:forgotten_client/data/local/tool_runner.dart';
import 'package:forgotten_client/features/dashboard/dashboard_page.dart';
import 'package:forgotten_client/features/diagnostics/diagnostics_page.dart';
import 'package:forgotten_client_api/forgotten_client_api.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

class _FakeEngineTransport implements EngineJsonTransport {
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
    } else {
      json = {'result': 'ok'};
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

class _FakeDiagnosticsService extends StudioDiagnosticsService {
  _FakeDiagnosticsService()
    : super(
        appConfig: AppConfig(
          flavor: 'test',
          apiBaseUrl: Uri.parse('https://api.test.local'),
          openAiMode: 'cloud',
          featureFlags: const {},
          appLogLevel: 'debug',
        ),
        engineClient: EngineClient(
          baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
          transport: _FakeEngineTransport(),
        ),
        dio: Dio(),
        diagnosticsLog: DiagnosticsLog(),
        engineStartup: () => EngineStartupResult(
          status: EngineStartupStatus.ready,
          baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
        ),
      );

  @override
  Future<StudioDiagnosticsSnapshot> collect() async {
    return StudioDiagnosticsSnapshot(
      collectedAt: DateTime(2026, 5, 21, 20),
      checks: const [
        DiagnosticCheck(
          name: 'Engine /health',
          status: DiagnosticCheckStatus.ready,
          detail: 'status=ok',
        ),
        DiagnosticCheck(
          name: 'Engine setup: ai',
          status: DiagnosticCheckStatus.ready,
          detail:
              'status=ready | provider=tv7_cloud | Ready through TV7 cloud AI; offline creation still requires local AI.',
        ),
        DiagnosticCheck(
          name: 'Engine setup: offline_creation',
          status: DiagnosticCheckStatus.degraded,
          detail:
              'status=not_ready | missing=transcription, local_ai | Action: Import or configure missing offline creation assets.',
        ),
        DiagnosticCheck(
          name: 'Engine AI provider: tv7_cloud',
          status: DiagnosticCheckStatus.ready,
          detail:
              'status=ready | source=tv7_cloud | active=true | requires_internet=true | cost_policy=tv7_managed_usage',
        ),
      ],
      endpointResults: const [
        EngineEndpointResult(
          name: 'Health',
          method: 'GET',
          path: '/health',
          status: DiagnosticCheckStatus.ready,
          detail: 'HTTP 200 in 0 ms',
          elapsed: Duration.zero,
          statusCode: 200,
          responsePreview: '{"status":"ok"}',
        ),
      ],
      settings: const {'Flavor': 'test'},
      recentErrors: const [],
    );
  }
}

class _FailingDiagnosticsService extends _FakeDiagnosticsService {
  @override
  Future<StudioDiagnosticsSnapshot> collect() async {
    throw StateError('diagnostics exploded');
  }
}

void main() {
  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;

  setUp(() async {
    originalPathProvider = PathProviderPlatform.instance;
    tempDir = await Directory.systemTemp.createTemp('diag_nav_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await tempDir.delete(recursive: true);
  });

  testWidgets('exposes diagnostics as third navigation item', (tester) async {
    final config = AppConfig(
      flavor: 'test',
      apiBaseUrl: Uri.parse('https://api.test.local'),
      openAiMode: 'cloud',
      featureFlags: const {'publishing': false},
      appLogLevel: 'debug',
    );
    final dio = Dio(BaseOptions(baseUrl: config.apiBaseUrl.toString()))
      ..httpClientAdapter = _BackendAdapter();
    final tokenStore = InMemoryTokenStore();
    final authRepository = AuthRepository(
      config: config,
      apiClient: ApiClient(config: config, tokenStore: tokenStore),
      tokenStore: tokenStore,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: DashboardPage(
          configRepository: ConfigRepository(config),
          localVideoRepository: ClientVideoRepository(
            toolRunner: ToolRunner(),
            engineClient: EngineClient(
              baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
              transport: _FakeEngineTransport(),
            ),
            videosApi: VideosApi(dio),
            uploadsApi: UploadsApi(dio),
            aiApi: AiApi(dio),
            dio: dio,
          ),
          authRepository: authRepository,
          appConfig: config,
          dio: dio,
          engineClient: EngineClient(
            baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
            transport: _FakeEngineTransport(),
          ),
          engineStartup: EngineStartupResult(
            status: EngineStartupStatus.ready,
            baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
            message: 'Engine ready',
          ),
          diagnosticsLog: DiagnosticsLog(),
          usersApi: UsersApi(dio),
          onLogout: () {},
        ),
      ),
    );

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations.length, 3);
    expect(find.text('Diagnostics'), findsOneWidget);
  });

  testWidgets('diagnostics page renders runtime checks', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: DiagnosticsPage(
          service: _FakeDiagnosticsService(),
          diagnosticsLog: DiagnosticsLog(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Local Media Engine'), findsOneWidget);
    expect(find.text('Health API'), findsOneWidget);
  });

  testWidgets('diagnostics page renders unified AI readiness', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: DiagnosticsPage(
          service: _FakeDiagnosticsService(),
          diagnosticsLog: DiagnosticsLog(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Setup Readiness'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('OFFLINE CREATION'), findsOneWidget);
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -500),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.text('tv7 cloud'), findsOneWidget);
    expect(find.textContaining('requires_internet=true'), findsOneWidget);
    expect(find.textContaining('local_llm'), findsNothing);
    expect(find.textContaining('cloud_llm'), findsNothing);
  });

  testWidgets('diagnostics page renders collection errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: DiagnosticsPage(
          service: _FailingDiagnosticsService(),
          diagnosticsLog: DiagnosticsLog(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Diagnostics unavailable'), findsOneWidget);
    expect(find.textContaining('diagnostics exploded'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
