import 'package:forgotten_client/bootstrap.dart';
import 'package:forgotten_client/config/app_config.dart';

Future<void> main() async {
  const defaults = AppConfigDefaults(
    flavor: 'dev',
    apiBaseUrl: 'https://api.dev.forgotten-app.local',
    openAiMode: 'cloud',
    featureFlagsJson: '{"publishing":false,"local_highlights":false}',
    appLogLevel: 'debug',
  );

  final config = AppConfig.fromEnvironment(defaults: defaults);
  await bootstrap(config);
}
