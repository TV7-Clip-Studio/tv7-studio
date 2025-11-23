import 'bootstrap.dart';
import 'config/app_config.dart';

Future<void> main() async {
  const defaults = AppConfigDefaults(
    flavor: 'stage',
    apiBaseUrl: 'https://api.stage.forgotten-app.local',
    openAiMode: 'cloud',
    featureFlagsJson: '{"publishing":true,"local_highlights":false}',
    appLogLevel: 'info',
  );

  final config = AppConfig.fromEnvironment(defaults: defaults);
  await bootstrap(config);
}
