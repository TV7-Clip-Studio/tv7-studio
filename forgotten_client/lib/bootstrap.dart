import 'package:flutter/widgets.dart';

import 'package:forgotten_client/app.dart';
import 'package:forgotten_client/config/app_config.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App(config: config));
}
