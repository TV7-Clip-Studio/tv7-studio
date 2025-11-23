import 'bootstrap.dart';
import 'config/app_config.dart';

Future<void> main() async {
  const defaults = AppConfigDefaults(
    flavor: 'prod',
    apiBaseUrl: 'https://api.forgotten-app.com',
    openAiMode: 'cloud',
    featureFlagsJson: '{"publishing":true,"local_highlights":false}',
    appLogLevel: 'info',
  );

  final config = AppConfig.fromEnvironment(defaults: defaults);
  await bootstrap(config);
}
