import 'package:flutter_test/flutter_test.dart';

import 'package:forgotten_client/app.dart';
import 'package:forgotten_client/config/app_config.dart';

void main() {
  testWidgets('renders login shell by default', (tester) async {
    const defaults = AppConfigDefaults(
      flavor: 'test',
      apiBaseUrl: 'https://api.test.local',
      openAiMode: 'cloud',
      featureFlagsJson: '{"publishing":false}',
      appLogLevel: 'debug',
    );

    final config = AppConfig.fromEnvironment(defaults: defaults);
    await tester.pumpWidget(App(config: config));

    expect(find.textContaining('Sign in'), findsAtLeastNWidgets(1));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
