import 'package:flutter_test/flutter_test.dart';

import 'package:forgotten_client/app.dart';
import 'package:forgotten_client/config/app_config.dart';

void main() {
  testWidgets('shows config preview values', (tester) async {
    const defaults = AppConfigDefaults(
      flavor: 'test',
      apiBaseUrl: 'https://api.test.local',
      openAiMode: 'cloud',
      featureFlagsJson: '{"publishing":false}',
      appLogLevel: 'debug',
    );

    final config = AppConfig.fromEnvironment(defaults: defaults);
    await tester.pumpWidget(App(config: config));

    expect(find.textContaining('Bootstrap shell'), findsOneWidget);
    expect(find.text('API base URL'), findsOneWidget);
    expect(find.text('OpenAI mode'), findsOneWidget);
    expect(find.textContaining('api.test.local'), findsOneWidget);
  });
}
