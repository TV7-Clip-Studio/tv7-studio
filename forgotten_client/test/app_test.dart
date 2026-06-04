import 'package:flutter_test/flutter_test.dart';

import 'package:forgotten_client/app.dart';
import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/data/local/engine_client.dart';
import 'package:forgotten_client/data/local/engine_process_manager.dart';

class _FakeEngineTransport implements EngineJsonTransport {
  final requested = <Uri>[];

  @override
  Future<EngineHttpResponse> request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    requested.add(uri);
    Map<String, dynamic> json;
    if (uri.path == '/health') {
      json = {'status': 'ok'};
    } else if (uri.path == '/v1/diagnostics') {
      json = {'status': 'ready'};
    } else {
      throw StateError('unexpected path ${uri.path}');
    }
    return EngineHttpResponse(
      statusCode: 200,
      elapsed: Duration.zero,
      json: json,
      rawBody: json.toString(),
    );
  }
}

void main() {
  final readyEngine = EngineStartupResult(
    status: EngineStartupStatus.ready,
    baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
    diagnostics: const EngineDiagnostics(status: 'ready', raw: {}),
    message: 'Engine ready',
  );

  testWidgets('renders login shell by default', (tester) async {
    const defaults = AppConfigDefaults(
      flavor: 'test',
      apiBaseUrl: 'https://api.test.local',
      openAiMode: 'cloud',
      featureFlagsJson: '{"publishing":false}',
      appLogLevel: 'debug',
    );

    final config = AppConfig.fromEnvironment(defaults: defaults);
    await tester.pumpWidget(App(config: config, engineStartup: readyEngine));

    expect(find.textContaining('Sign in'), findsAtLeastNWidgets(1));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('surfaces degraded Engine startup state', (tester) async {
    const defaults = AppConfigDefaults(
      flavor: 'test',
      apiBaseUrl: 'https://api.test.local',
      openAiMode: 'cloud',
      featureFlagsJson: '{"publishing":false}',
      appLogLevel: 'debug',
    );

    final config = AppConfig.fromEnvironment(defaults: defaults);
    await tester.pumpWidget(
      App(
        config: config,
        engineStartup: EngineStartupResult(
          status: EngineStartupStatus.degraded,
          baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
          message: 'Engine degraded: missing ffmpeg',
        ),
      ),
    );

    expect(find.text('Engine degraded: missing ffmpeg'), findsOneWidget);
  });

  testWidgets('refreshes Engine diagnostics from the banner', (tester) async {
    const defaults = AppConfigDefaults(
      flavor: 'test',
      apiBaseUrl: 'https://api.test.local',
      openAiMode: 'cloud',
      featureFlagsJson: '{"publishing":false}',
      appLogLevel: 'debug',
    );

    final config = AppConfig.fromEnvironment(defaults: defaults);
    final transport = _FakeEngineTransport();
    await tester.pumpWidget(
      App(
        config: config,
        engineClient: EngineClient(
          baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
          transport: transport,
        ),
        engineStartup: EngineStartupResult(
          status: EngineStartupStatus.degraded,
          baseUri: Uri(scheme: 'http', host: '127.0.0.1', port: 7070),
          message: 'Engine degraded: missing ffmpeg',
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(transport.requested.map((uri) => uri.path), [
      '/health',
      '/v1/diagnostics',
    ]);
    expect(find.text('Engine degraded: missing ffmpeg'), findsNothing);
  });
}
