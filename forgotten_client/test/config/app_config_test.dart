import 'package:flutter_test/flutter_test.dart';

import 'package:forgotten_client/config/app_config.dart';

void main() {
  group('AppConfig.fromEnvironment', () {
    test('uses defaults when no overrides are provided', () {
      const defaults = AppConfigDefaults(
        flavor: 'dev',
        apiBaseUrl: 'https://api.dev.local',
        openAiMode: 'cloud',
        featureFlagsJson: '{"publishing":false,"local_highlights":true}',
        appLogLevel: 'debug',
      );

      final config = AppConfig.fromEnvironment(defaults: defaults);

      expect(config.flavor, defaults.flavor);
      expect(config.apiBaseUrl.toString(), defaults.apiBaseUrl);
      expect(config.openAiMode, defaults.openAiMode);
      expect(config.featureFlags, {'publishing': false, 'local_highlights': true});
      expect(config.appLogLevel, defaults.appLogLevel);
    });

    test('gracefully handles invalid feature flag JSON', () {
      const defaults = AppConfigDefaults(
        flavor: 'test',
        apiBaseUrl: 'https://api.test.local',
        openAiMode: 'cloud',
        featureFlagsJson: '{not-json}',
        appLogLevel: 'info',
      );

      final config = AppConfig.fromEnvironment(defaults: defaults);

      expect(config.featureFlags['raw'], defaults.featureFlagsJson);
      expect(config.featureFlags['parseError'], isTrue);
    });
  });
}
